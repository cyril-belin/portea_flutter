# F01 — Onboarding

## Objectif

Guider l'éleveur depuis le premier lancement jusqu'au Dashboard : création de compte (email/Google/Apple), création de l'élevage, permission notifications. Une session existante doit aller directement au Dashboard sans re-onboarding.

---

## État actuel (audit 2026-07-15)

### Fait ✅
- `OnboardingWelcomeScreen` — écran d'accueil avec illustration et bouton "Commencer"
- `KennelSetupScreen` — formulaire : nom, espèce (dog/cat), affixe, SIRET. Collecte aussi ownerName via `Kennel.ownerName`.
- `OnboardingNotificationsScreen` — demande de permission (UI seulement, pas de vraie permission OS)
- `OnboardingViewModel` — gère `kennelName`, `species`, `affix`, `isOnboardingCompleted`
- `IKennelRepository` / `MockKennelRepository` — CRUD complet
- Router go_router avec redirect : onboarding non complété → `/onboarding/welcome` ; complété → `/dashboard`
- 9 tests unitaires passing (`onboarding_test.dart`)

### Absent / partiel ⚠️
- **Login screen** : `lib/screens/sign_in_screen.dart` est orphelin (non branché au router). Doit être migré en `features/onboarding/presentation/screens/sign_in_screen.dart` et intégré au flux.
- **`greetings_screen.dart`** : orphelin — à évaluer si réutilisable ou supprimer.
- **Auth Serverpod réelle** : le client `emailIdp` est câblé mais l'onboarding ne demande ni email ni mot de passe.
- **Google / Apple Sign-In** : absent, à ajouter via `serverpod_auth_idp_flutter` (providers).
- **`ServerpodKennelRepository`** : absent — `createKennel` / `getKennel` ne touchent pas le serveur.
- **`isOnboardingCompleted` persisté** : en mémoire seulement, perdu au redémarrage.
- **Permission notifications OS réelle** : `OnboardingNotificationsScreen` affiche l'UI mais n'appelle pas `flutter_local_notifications`.
- **`kennelId` hardcodé** : `kennelId: 1` dans `LitterDeclarationViewModel` et `MockDatabase`. Doit venir du kennel créé post-login.
- **`lib/screens/`** : dossier à supprimer à la fin de F01.

---

## Reste à faire

### Backend (portea_server)
- [ ] Vérifier/créer l'endpoint `kennel` : `getMyKennel`, `createKennel`, `updateKennel` (session-based, jamais de kennelId en param)
- [ ] La relation user Serverpod → Kennel doit être 1:1 avec contrainte unique sur userId
- [ ] `serverpod generate` → régénère portea_client

### Data layer (app)
- [ ] `ServerpodKennelRepository implements IKennelRepository`
- [ ] Swapper `MockKennelRepository` → `ServerpodKennelRepository` dans `main.dart`
- [ ] Stocker le `kennelId` résolu en `SharedPreferences` pour éviter une requête à chaque démarrage (cache lecture seule, jamais utilisé pour l'autorisation)
- [ ] Ajouter `flutter_local_notifications` au `pubspec.yaml` et implémenter `NotificationService.requestPermission()` pour obtenir la vraie permission OS dès cette étape.

### Auth
- [ ] Migrer/créer `SignInScreen` dans `features/onboarding/presentation/screens/sign_in_screen.dart`
- [ ] Intégrer `SignInScreen` dans le router : `/onboarding/login`
- [ ] Flux complet : Welcome → Login → (si première fois) Kennel Setup → Notifications → Dashboard
- [ ] Flux retour : Welcome → Login → (session existante + kennel existant) → Dashboard
- [ ] Email login fonctionnel via `client.emailIdp.login()`
- [ ] Google Sign-In via `serverpod_auth_idp_flutter` (si config Google Console disponible)
- [ ] Apple Sign-In (si config Apple Developer disponible)
- [ ] Mettre à jour `OnboardingViewModel.isOnboardingCompleted` : persisté via `ServerpodKennelRepository.getKennel() != null`

### UI
- [ ] Ajouter vrai appel `requestPermission()` dans `OnboardingNotificationsScreen` (flutter_local_notifications)
- [ ] Supprimer `lib/screens/greetings_screen.dart` (ou recycler si utile)
- [ ] Supprimer `lib/screens/` après migration de SignInScreen

### Tests
- [ ] Tests unitaires `ServerpodKennelRepository` (nécessite mocks Serverpod — voir skill `dart-generate-test-mocks`)
- [ ] Test `OnboardingViewModel.createKennel` avec `ServerpodKennelRepository`

---

## Écrans concernés

| Écran | Fichier | État |
|-------|---------|------|
| Welcome | `onboarding/presentation/screens/onboarding_welcome_screen.dart` | ✅ Fait |
| Login | `onboarding/presentation/screens/sign_in_screen.dart` | ❌ À créer/migrer |
| Kennel Setup | `onboarding/presentation/screens/kennel_setup_screen.dart` | ✅ Fait |
| Notifications | `onboarding/presentation/screens/onboarding_notifications_screen.dart` | ⚠️ UI seulement |

---

## Règles métier

1. Un compte = un élevage (contrainte 1:1 en base, V1).
2. Si le compte existe mais le kennel n'est pas encore créé → Kennel Setup.
3. Si le compte existe et le kennel existe → Dashboard direct.
4. L'espèce (`species`) est choisie une fois à l'onboarding, non modifiable ensuite (V1). Préparée pour V2 multi-espèces.
5. Le `kennelId` n'est JAMAIS envoyé par le client comme paramètre d'autorisation.
6. `ownerName`, `ownerEmail`, `ownerPhone`, `ownerAddress` sont optionnels à l'onboarding mais utiles pour pré-remplir les PDF (F09).
7. **Dépendance package** : Le package `flutter_local_notifications` est ajouté au `pubspec.yaml` dès cette étape (F01). L'écran `OnboardingNotificationsScreen` doit faire la vraie demande de permission OS via l'API du package, et non pas simuler la demande.

---

## Critères d'acceptation

- [ ] L'éleveur peut créer un compte email/password et créer son élevage en < 2 minutes.
- [ ] Un redémarrage à froid après onboarding mène directement au Dashboard (pas de re-onboarding).
- [ ] Une session existante au lancement → Dashboard direct (redirect go_router).
- [ ] `dart analyze` 0 warning.
- [ ] `flutter test` vert sur `onboarding_test.dart`.
- [ ] `lib/screens/` supprimé.
