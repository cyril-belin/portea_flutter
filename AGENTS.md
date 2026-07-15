# AGENTS.md — Portea Flutter

> **Ce fichier fait autorité.** Avant toute tâche, lis ce document en entier. Ne commence aucune implémentation sans l'avoir lu.

---

## 1. Contexte produit

**Portea** = app mobile (iOS + Android) de gestion d'élevage pour éleveurs familiaux de chiens/chats en France.

- **Valeur centrale** : suivi des portées (pesées, soins, rappels) + génération des documents légaux (attestation de cession PDF, registre d'élevage).
- **Modèle freemium via RevenueCat** :
  - Gratuit = 1 portée active max
  - Premium = portées illimitées + historique + documents PDF illimités + registre exportable
- **Cible** : iOS + Android uniquement. Pas de web en V1.

---

## 2. Architecture qui fait foi — NE PAS MODIFIER

### Structure de dossiers

```
lib/
├── core/
│   ├── data/           # MockDatabase (tests uniquement)
│   ├── routing/        # app_router.dart, shell_scaffold.dart
│   ├── theme/          # app_colors.dart, app_text_styles.dart, app_theme.dart
│   └── widgets/        # Widgets partagés (animal_list_tile, empty_state, status_badge)
├── features/
│   ├── onboarding/     # F01
│   ├── breeders/       # F02
│   ├── litters/        # F03
│   ├── puppies/        # F04, F05, F06, F07, F08
│   ├── dashboard/
│   └── settings/       # F09, F10
└── main.dart
```

Chaque feature suit **Clean Architecture 3 couches** :
```
feature/
├── data/
│   └── repositories/       # Implémentations (Mock + Serverpod)
├── domain/
│   └── repositories/       # Interfaces (IXxxRepository)
└── presentation/
    ├── screens/             # Widgets UI
    └── view_models/         # ChangeNotifier (MVVM)
```

### Règles absolues

| Règle | Description |
|-------|-------------|
| **Architecture** | Clean Architecture + MVVM. INTERDIT : refonte, changement de structure de dossier. |
| **State management** | Provider uniquement (`ChangeNotifier` + `ChangeNotifierProxyProvider`). INTERDIT : Riverpod, BLoC, GetX. |
| **Navigation** | go_router avec `StatefulShellRoute.indexedStack`. INTERDIT : Navigator.push direct entre branches. |
| **Modèles** | Proviennent UNIQUEMENT du client généré Serverpod (`portea_client`). INTERDIT : créer des classes modèles côté app. |
| **DI** | Via `MultiProvider` dans `main.dart`. Les repositories sont injectés dans les ViewModels via `ChangeNotifierProxyProvider`. |
| **Persistance** | `MockXxxRepository` = tests uniquement. Production = `ServerpodXxxRepository`. |
| **kennelId** | JAMAIS passé en paramètre client. Le serveur dérive le kennel depuis la session auth. |

---

## 3. Stack technique

| Composant | Package | Version |
|-----------|---------|---------|
| Serverpod client | `portea_client` (path: ../portea_client) | 4.0.0-beta.0 |
| Auth | `serverpod_auth_idp_flutter` | 4.0.0-beta.0 |
| Serverpod Flutter | `serverpod_flutter` | 4.0.0-beta.0 |
| Navigation | `go_router` | ^14.0.0 |
| State | `provider` | ^6.1.2 |
| Fonts | `google_fonts` | ^8.1.0 |
| Flutter SDK | `^3.38.4` | Dart SDK `^3.10.3` |
| **À ajouter V1** | `flutter_local_notifications` | Notifications F07 |
| **À ajouter V1** | `pdf` + `printing` | Génération PDF F09 |
| **À ajouter V1** | `purchases_flutter` | RevenueCat F10 |
| **À ajouter V1** | `shared_preferences` | Cache kennelId local |

---

## 4. Serverpod 4 — Référence obligatoire

> ⚠️ Ta connaissance interne de Serverpod est probablement périmée (v4 = beta récente, breaking changes vs v2/v3). **Consulte toujours la doc officielle v4** avant toute implémentation backend.

- **Doc principale** : https://docs.serverpod.dev/next
- **Auth** : https://docs.serverpod.dev/next/concepts/authentication/get-started
- **Endpoints disponibles côté client** (portea_client/src/protocol/client.dart) :
  - `emailIdp` — login, registration, password reset
  - `jwtRefresh` — refresh token JWT
  - `greeting` — exemple (ne pas utiliser en prod)
  - Modules : `serverpod_auth_idp`, `serverpod_auth_core`
- **Modèles générés** (ne PAS modifier) : `Kennel`, `Breeder`, `Litter`, `Puppy`, `WeighingEntry`, `CareEntry`

### Workflow Serverpod par feature

Pour chaque feature nécessitant Serverpod :
1. Écrire les modèles YAML dans `portea_server/lib/src/models/`
2. Écrire les endpoints dans `portea_server/lib/src/endpoints/`
3. Lancer `serverpod generate` → régénère `portea_client`
4. Créer `ServerpodXxxRepository implements IXxxRepository` dans `features/xxx/data/repositories/`
5. Swapper le Mock par Serverpod dans `main.dart`
6. Créer/appliquer les migrations DB : `serverpod create-migration` puis `serverpod migrate`

### Règle de sécurité serveur

```dart
// ✅ Correct — serveur dérive le kennel depuis la session
Future<List<Litter>> getLitters(Session session) async {
  final kennel = await _getKennelForSession(session); // jamais en param
  return await Litter.db.find(session, where: (t) => t.kennelId.equals(kennel.id!));
}

// ❌ INTERDIT — client ne passe jamais le kennelId
Future<List<Litter>> getLitters(Session session, int kennelId) async { ... }
```

---

## 5. MCP dart-flutter — Outil de validation obligatoire

**Avant de déclarer une feature terminée**, utilise ces outils MCP :

| Outil MCP | Usage |
|-----------|-------|
| `analyze_files` | Vérification statique (`dart analyze` équivalent) |
| `pub` | Gestion des dépendances |
| `hot_reload` / `hot_restart` | Test en live |
| `get_runtime_errors` | Capture des erreurs runtime |
| `widget_inspector` | Debug layout |
| `lsp` | Navigation symbolique, diagnostics |

**Ordre de validation obligatoire :**
1. `analyze_files` → 0 warning, 0 error
2. `flutter test` → tous les tests verts
3. Smoke test 4 points (voir §8)

---

## 6. Skills Flutter/Dart — Table de chargement par type de tâche

| Type de tâche | Skills à charger |
|---------------|-----------------|
| Nouvelle feature UI | `flutter-technical` + `flutter-apply-architecture-best-practices` |
| Routing / deep-link | `flutter-technical` + `flutter-setup-declarative-routing` |
| Test widget | `flutter-add-widget-test` |
| Test unitaire | `dart-add-unit-test` |
| Test intégration | `flutter-add-integration-test` |
| Mocks de test | `dart-generate-test-mocks` |
| Analyse statique | `dart-run-static-analysis` |
| Coverage | `dart-collect-coverage` |
| Erreur runtime | `dart-fix-runtime-errors` |
| Conflit packages | `dart-resolve-package-conflicts` |
| Layout overflow | `flutter-fix-layout-issues` |
| Responsive | `flutter-build-responsive-layout` |
| Sérialisation JSON | `flutter-implement-json-serialization` |
| Pattern matching Dart | `dart-use-pattern-matching` |
| Toute tâche Flutter | `flutter-technical` (toujours) |

> En cas de **conflit entre un skill et l'architecture existante du repo**, le repo gagne.

---

## 7. Conventions du repo

### Nommage

| Type | Convention | Exemple |
|------|-----------|---------|
| Fichier screen | `snake_case_screen.dart` | `litter_detail_screen.dart` |
| Fichier ViewModel | `snake_case_view_model.dart` | `litter_detail_view_model.dart` |
| Classe ViewModel | `PascalCaseViewModel` | `LitterDetailViewModel` |
| Interface repository | `IXxxRepository` | `ILitterRepository` |
| Mock repository | `MockXxxRepository` | `MockLitterRepository` |
| Serverpod repository | `ServerpodXxxRepository` | `ServerpodLitterRepository` |

### Enums / valeurs métier (strings côté modèle Serverpod)

| Entité | Champ | Valeurs |
|--------|-------|---------|
| `Kennel` | `species` | `'dog'` \| `'cat'` |
| `Breeder` | `sex` | `'male'` \| `'female'` |
| `Breeder` | `status` | `'active'` \| `'retired'` |
| `Puppy` | `sex` | `'male'` \| `'female'` |
| `Puppy` | `status` | `'available'` \| `'reserved'` \| `'sold'` |
| `CareEntry` | `type` | `'vaccine'` \| `'deworming'` \| `'other'` |

### Routing complet (go_router)

```
/onboarding/welcome         OnboardingWelcomeScreen
/onboarding/login           SignInScreen  (F01 — migrer depuis lib/screens/)
/onboarding/setup           KennelSetupScreen
/onboarding/notifications   OnboardingNotificationsScreen

/dashboard                  DashboardScreen (ShellRoute branche 1)
/breeders                   BreedersListScreen (branche 2)
/breeders/new               BreederProfileScreen
/breeders/:id               BreederProfileScreen
/litters                    LittersHistoryScreen (branche 3)
/litters/new                LitterDeclarationScreen
/litters/:id                LitterDetailScreen
/litters/:id/puppies/batch  PuppyBatchCreationScreen
/litters/:id/weighing       GroupWeighingScreen
/litters/:id/care           AddCareScreen
/litters/:id/documents      DocumentsScreen
/settings                   SettingsScreen (branche 4)

/puppies/:id                PuppyFileScreen (root push)
/premium                    PorteaPremiumScreen (root push)
```

---

## 8. Workflow feature par feature

Pour chaque feature (Fxx) :

1. **Lire le feature file** (`features/Fxx_nom.md`) — objectif, état actuel, reste à faire
2. **Charger les skills** pertinents (table §6)
3. **Consulter la doc Serverpod v4** si la feature touche le backend
4. **Backend d'abord** (si applicable) : YAML modèles → endpoints serveur → `serverpod generate`
5. **Repository** : `ServerpodXxxRepository` implémentant `IXxxRepository`
6. **ViewModel** : uniquement si logique manquante (ne pas recréer ce qui existe)
7. **UI** : uniquement si écrans manquants (ne pas réécrire ce qui existe)
8. **Tests** : unitaires ViewModel + widget si nouveau screen
9. **Validation** : `analyze_files` → tests → smoke test 4 points
10. **Commit** : `feat(Fxx): <description> (ref: Fxx_nom.md)`

### Définition de "feature terminée"

Une feature est **terminée** si et seulement si :
- ✅ `dart analyze` → 0 warning, 0 error
- ✅ `flutter test` → tous les tests verts (unitaires + widget si applicable)
- ✅ Smoke test 4 points :
  1. Redémarrage app → données persistent (Serverpod, pas MockDB)
  2. Chaque action → modifie l'état réel
  3. État vide → empty state correct (pas un crash)
  4. Chemin d'erreur → erreur exploitable (pas silencieuse)
- ✅ `mounted` vérifié après tout `await`
- ✅ Commit conventionnel référençant le feature file

---

## 9. Interdits V1 → ROADMAP.md

- Généalogie graphique
- Multi-utilisateur / transfert de carnet
- Mode propriétaire
- Comptabilité
- API externes tierces (hors Serverpod, RevenueCat, PDF)
- Web app
- Multi-élevage par compte
- Multi-espèces par élevage

Règle absolue : toute idée hors F01-F10 → 1 ligne dans `ROADMAP.md`, zéro discussion, revue post-build.

---

## 10. Commandes opérationnelles

```bash
# NE PAS lancer le serveur toi-même — demander à l'utilisateur
serverpod start

# Analyse statique
dart analyze lib/
dart format lib/ --set-exit-if-changed

# Tests
flutter test
flutter test --coverage

# Génération Serverpod (après changement de modèle YAML)
serverpod generate

# Migration DB (après serverpod generate si schéma changé)
serverpod create-migration
serverpod migrate --apply-migrations
```

---

## 11. Fichiers clés

| Fichier | Rôle |
|---------|------|
| `lib/main.dart` | DI MultiProvider + initialisation client Serverpod |
| `lib/core/routing/app_router.dart` | Toutes les routes go_router |
| `lib/core/data/mock_database.dart` | Données de test uniquement |
| `../portea_client/lib/portea_client.dart` | Entry point client généré Serverpod |
| `../portea_client/lib/src/protocol/client.dart` | Endpoints Serverpod disponibles |
| `features/F01_onboarding.md` … `features/F10_premium.md` | Feature files — source de vérité |
| `memory.md` | État de session (skill remember) |
| `ui-registry.md` | Référentiel design (skill imprint) |
| `ROADMAP.md` | Idées hors scope V1 |
