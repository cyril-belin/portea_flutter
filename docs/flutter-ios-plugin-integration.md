# Playbook : Intégration de plugins Flutter natifs iOS + routage auth-aware

> **Transportable** : ce document décrit deux pièges génériques rencontrés sur toute app Flutter (≥ 3.44) avec backend Serverpod. Aucune référence au domaine Portea — applicable à n'importe quelle app.

---

## Partie 1 — Plugins natifs iOS : SPM vs CocoaPods

### Le piège

Depuis Flutter 3.44+, **Swift Package Manager (SPM) est le gestionnaire de dépendances natif iOS par défaut**, remplaçant CocoaPods. Mais de nombreux plugins pub.dev (ex. `flutter_local_notifications`) ne sont **pas correctement référencés par SPM** — ils apparaissent dans `.flutter-plugins-dependencies` mais ni dans le `Package.resolved` SPM ni dans le `Podfile.lock` CocoaPods. Résultat : **le plugin n'est jamais intégré au build natif**, les method channels échouent silencieusement (`resolvePlatformSpecificImplementation` retourne `null`), et les appels comme `requestPermissions()` retournent `null` sans popup OS.

### Symptômes

- Un plugin natif est ajouté au `pubspec.yaml` et `pub get` réussit.
- `.flutter-plugins-dependencies` liste bien le plugin en section `ios`.
- Mais le comportement natif attendu (popup de permission, method channel) ne se produit **pas**.
- Aucune erreur runtime — l'appel retourne `null` silencieusement.

### Diagnostic (30 secondes)

Vérifier si le plugin est réellement intégré au build natif :

```bash
# 1. Le plugin est-il détecté par Flutter ?
python3 -c "import json; d=json.load(open('.flutter-plugins-dependencies')); print([p['name'] for p in d.get('plugins',{}).get('ios',[])])"

# 2. SPM activé ?
python3 -c "import json; d=json.load(open('.flutter-plugins-dependencies')); print('SPM:', d.get('swift_package_manager_enabled'))"

# 3. Le plugin est-il dans Package.resolved (SPM) ?
find ios -name "Package.resolved" | xargs grep -l "nom_du_plugin" 2>/dev/null

# 4. Le plugin est-il dans Podfile.lock (CocoaPods) ?
grep "nom_du_plugin" ios/Podfile.lock
```

Si SPM est activé (`{'ios': true}`) mais le plugin n'est ni dans `Package.resolved` ni dans `Podfile.lock` → **c'est ce piège**.

### Fix : désactiver SPM et revenir à CocoaPods

```bash
# 1. Désactiver SPM globalement pour ce projet
flutter config --no-enable-swift-package-manager

# 2. Supprimer les artefacts SPM obsolètes
rm -f ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved
rm -f ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# 3. Régénérer les références plugins (SPM now disabled)
flutter pub get

# 4. Vérifier le flag SPM est bien à false
python3 -c "import json; d=json.load(open('.flutter-plugins-dependencies')); print('SPM:', d.get('swift_package_manager_enabled'))"
# Doit afficher : SPM: {'ios': False, 'macos': False}

# 5. Réinstaller les pods proprement
cd ios && rm -f Podfile.lock && rm -rf Pods .symlinks
pod install
# Doit lister TOUS les plugins natifs (flutter_local_notifications, etc.)
```

### Vérification du fix

```bash
# Le plugin doit maintenant apparaître dans Podfile.lock
grep "flutter_local_notifications" ios/Podfile.lock
# Doit retourner une ligne non vide

# Et le framework natif doit être dans le .app après build
find ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Bundle/Application/*/Runner.app/Frameworks -name "flutter_local_notifications*" 2>/dev/null
# Doit retourner le chemin du .framework
```

### Quand garder SPM (alternative)

SPM est l'avenir et fonctionne pour la plupart des plugins. Ne le désactiver que si un plugin spécifique n'est pas référencé. Pour diagnostiquer plugin par plugin, vérifier que chaque plugin de `.flutter-plugins-dependencies` (section `ios`) apparaît soit dans `Package.resolved` (SPM) soit dans `Podfile.lock` (CocoaPods fallback).

---

## Partie 2 — Routage auth-aware avec onboarding multi-étapes

### Le piège

Un flux d'onboarding typique : `Welcome → Login → Setup → Notifications → Dashboard`.
L'erreur courante est de dériver l'état « onboarding terminé » d'une **seule** condition (ex. « kennel créé »). Or la dernière étape (Notifications) fait partie du flux — si elle est skippée par le redirect, elle ne s'exécute jamais (ex. la demande de permission OS n'est jamais déclenchée).

### L'erreur type

```dart
// ❌ MAUVAIS : onboarding considéré terminé dès que le kennel existe
bool get isOnboardingCompleted => _kennel != null;
```

Conséquence : dès la création du kennel, le redirect saute l'écran notifications → `requestPermission()` jamais appelé → aucune popup OS.

### La solution : séparer deux concepts

```dart
// ✅ CORRECT : deux états distincts
class OnboardingViewModel extends ChangeNotifier {
  // Le kennel existe sur le serveur (décide : setup vs notifications)
  bool _hasKennel = false;
  bool get hasKennel => _hasKennel;

  // Le flux complet est terminé (kennel + notifications screen passée).
  // Persisté via SharedPreferences pour le cold-start.
  bool _isOnboardingCompleted = false;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  // Authentifié, pas de kennel → redirect setup
  bool get needsKennelSetup => isAuthenticated && !_hasKennel;

  Future<bool> createKennel() async {
    // ... crée le kennel ...
    _hasKennel = _kennel != null;
    // ⚠️ NE PAS mettre isOnboardingCompleted = true ici !
    // L'utilisateur doit encore passer l'écran notifications.
  }

  // Appelé UNIQUEMENT depuis l'écran final (notifications).
  Future<void> completeOnboarding() async {
    _isOnboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true); // cold-start
    notifyListeners();
  }
}
```

### Le redirect go_router correspondant

Quatre cas mutuellement exclusifs, dans cet ordre :

```dart
GoRouter(
  refreshListenable: onboardingViewModel, // réagit aux changements d'état
  redirect: (context, state) {
    final loc = state.matchedLocation;
    final isOnboarding = loc.startsWith('/onboarding');

    // 1. Non authentifié → welcome (sauf login)
    if (!onboardingViewModel.isAuthenticated) {
      return (loc == '/onboarding/welcome' || loc == '/onboarding/login')
          ? null
          : '/onboarding/welcome';
    }

    // 2. Onboarding complet → dashboard (jamais rester sur onboarding)
    if (onboardingViewModel.isOnboardingCompleted) {
      return isOnboarding ? '/dashboard' : null;
    }

    // 3. Authentifié sans kennel → setup
    if (onboardingViewModel.needsKennelSetup && loc != '/onboarding/setup') {
      return '/onboarding/setup';
    }

    // 4. Kennel créé mais notifications pas passées → écran notifications
    if (onboardingViewModel.hasKennel && isOnboarding &&
        loc != '/onboarding/notifications') {
      return '/onboarding/notifications';
    }

    return null;
  },
  // ...
);
```

### L'écueil du timing au démarrage

Au cold-start, la séquence est asynchrone :
1. App démarre, `initialLocation = '/dashboard'`
2. Auth pas encore restaurée → redirect welcome
3. Auth restaurée → `notifyListeners()` → redirect réévalué
4. `getKennel()` en cours → `hasKennel` encore faux → redirect setup
5. `getKennel()` fini → `hasKennel` vrai → redirect notifications

**Clé** : le `refreshListenable` réagit à CHAQUE `notifyListeners()` du ViewModel, donc le redirect se réévalue à chaque étape transitoire. Il ne faut pas craindre les états intermédiaires — ils se résolvent d'eux-mêmes.

### Cold-start : comment savoir si l'onboarding est déjà fait ?

La session auth est restaurée par le SDK (secure storage / keychain), et le kennel est interrogé sur le serveur. Mais « onboarding terminé » n'est pas déductible de ces deux seuls éléments : il faut le **persister côté client** (SharedPreferences), car l'utilisateur peut avoir un compte + kennel mais avoir quitté l'app avant l'écran notifications.

```dart
// Au démarrage, _onAuthChanged() lit le flag persisté :
void _onAuthChanged() async {
  // ...
  _kennel = await _kennelRepository.getKennel();
  _hasKennel = _kennel != null;
  final prefs = await SharedPreferences.getInstance();
  _isOnboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  notifyListeners();
}
```

### Pattern de testabilité

Ne pas coupler le ViewModel au client/auth global — injecter l'état d'auth comme un `ValueListenable<bool>` :

```dart
// Adapter générique (découplé de Serverpod)
class AuthenticatedListenable<T> extends ChangeNotifier
    implements ValueListenable<bool> {
  AuthenticatedListenable(this._source) {
    _source.addListener(_onChanged);
  }
  final ValueListenable<T?> _source; // ex. ValueListenable<AuthSuccess?>
  @override
  bool get value => _source.value != null;
  void _onChanged() => notifyListeners();
  @override
  void dispose() { _source.removeListener(_onChanged); super.dispose(); }
}
```

Avantage : le ViewModel est testable sans client réel — il suffit d'un `ValueNotifier<bool>` dans les tests.

---

## Checklist rapide (quand un plugin natif ne marche pas)

- [ ] `flutter config` : SPM activé ou non ?
- [ ] Plugin présent dans `.flutter-plugins-dependencies` (section `ios`) ?
- [ ] Plugin présent dans `Package.resolved` (SPM) **ou** `Podfile.lock` (CocoaPods) ?
- [ ] Framework `.framework` présent dans le `.app` installé sur simulateur ?
- [ ] Si non → appliquer le fix Partie 1 (désactiver SPM + pod install)

## Checklist rapide (quand un écran d'onboarding est skippé)

- [ ] L'état « onboarding terminé » est-il dérivé d'une seule condition ?
- [ ] Le redirect court-circuite-t-il un écran obligatoire ?
- [ ] Séparer `hasEntity` (étape N créée) de `isOnboardingCompleted` (flux entier terminé)
- [ ] Persister `isOnboardingCompleted` via SharedPreferences pour le cold-start
- [ ] Tester le redirect avec un test unitaire sur le ViewModel (chaque transition d'état)
