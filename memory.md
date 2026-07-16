# Memory — F01 Onboarding + Auth Serverpod

Last updated: 2026-07-16

---

## What was built

**F01 Onboarding + Auth Serverpod — TERMINÉ et VALIDÉ sur simulateur (6/6 smoke test).**

### Backend (`portea_server`, branche `feat/f01-onboarding`)
- `lib/src/models/kennel.spy.yaml` : Kennel transformé en table DB persistée (`table: kennel`), ajout `userId: UuidValue?` + index unique `kennel_user_id_idx` (relation 1:1 user→kennel).
- `lib/src/endpoints/kennel_endpoint.dart` : `KennelEndpoint` avec `requireLogin = true` — `getMyKennel`, `createKennel`, `updateKennel`. userId dérivé de `session.authenticated?.authUserId` (synchrone en v4), jamais en param client. species fixé à l'onboarding (non modifiable en update V1).
- Migration `20260716120707650` : CREATE TABLE kennel + index unique userId.
- `test/integration/kennel_endpoint_test.dart` : 6 tests d'intégration Serverpod (auth/non-auth, create, contrainte 1:1, update).

### Frontend (`portea_flutter`, branche `feat/f01-onboarding`)
- `lib/features/onboarding/data/repositories/serverpod_kennel_repository.dart` : `ServerpodKennelRepository implements IKennelRepository` (client.kennel.*), cache kennelId en SharedPreferences.
- `lib/features/onboarding/presentation/screens/sign_in_screen.dart` : `SignInScreen` avec `EmailSignInWidget` (login + inscription + reset via emailIdp).
- `lib/features/onboarding/presentation/view_models/onboarding_view_model.dart` : séparé `hasKennel` (kennel existe) de `isOnboardingCompleted` (flux terminé, persisté SharedPreferences `onboarding_completed`). `authListenable` injecté (`ValueListenable<bool>`) pour rester testable.
- `lib/core/auth/authenticated_listenable.dart` : adapte `ValueListenable<AuthSuccess?>` en `ValueListenable<bool>` (générique sur T, découplé Serverpod).
- `lib/core/notifications/notification_service.dart` : `NotificationService` (initialize + requestPermission iOS/Android).
- `lib/features/onboarding/presentation/screens/onboarding_notifications_screen.dart` : vrai appel `requestPermission()` au tap, état loading, `completeOnboarding()` async.
- `lib/core/routing/app_router.dart` : route `/onboarding/login` ajoutée, redirect auth-aware (non-auth→welcome, auth sans kennel→setup, auth+kennel sans onboarding fini→notifications, auth+onboarding fini→dashboard).
- `lib/main.dart` : swap MockKennelRepository→ServerpodKennelRepository, injection NotificationService + AuthenticatedListenable.
- Nettoyage : suppression `lib/screens/` (sign_in + greetings orphelins), correction `Color(0xFFC4664A)` → `AppColors.primary`.
- `pubspec.yaml` : + shared_preferences, flutter_local_notifications.
- iOS : switch SPM → CocoaPods (cf. Problems solved).
- 69 tests Flutter verts (13 onboarding dont 4 nouveaux auth-driven).

---

## Decisions made

- **Auth Flutter** : `EmailSignInWidget` (officiel Serverpod v4) plutôt qu'un formulaire email/password custom — gère inscription, vérification email, reset, politique de mot de passe.
- **Navigation post-auth** : jamais dans `onAuthenticated` (interdit par doc Serverpod — forcerait un re-login à chaque lancement). Le router réagit au `refreshListenable` du VM.
- **hasKennel ≠ isOnboardingCompleted** : la création du kennel ne complète PAS l'onboarding. L'écran notifications fait partie du flux. `completeOnboarding()` (persisté SharedPreferences) est le seul point qui marque la fin.
- **idb installé** pour piloter le simulateur en autonomie (cf. Problems solved). `idb` CLI patché pour Python 3.14 (asyncio.get_event_loop → new_event_loop), symlink dans /opt/homebrew/bin.
- **iOS : CocoaPods, pas SPM**. `flutter config --no-enable-swift-package-manager`. SPM ne référençait pas flutter_local_notifications → plugin jamais intégré au build.

---

## Problems solved

1. **`session.authenticated` synchrone en v4** : la doc Context7 (v3) montrait `await session.authenticated` → erreur. En v4 c'est un getter synchrone.
2. **Flutter SPM vs CocoaPods** : Flutter utilisait SPM par défaut (`swift_package_manager_enabled: {ios: true}`), mais flutter_local_notifications n'était référencé ni dans SPM (Package.resolved) ni dans CocoaPods → plugin natif jamais intégré → `requestPermissions()` retournait null silencieusement. Fix : `flutter config --no-enable-swift-package-manager` + pod install propre (18 pods).
3. **Écran notifications skippé** : `OnboardingViewModel` marquait `isOnboardingCompleted = true` dès la création du kennel → le redirect sautait l'écran notifications → `requestPermission()` jamais appelé. Fix : séparé `hasKennel` de `isOnboardingCompleted`.
4. **VM non testable** : coupler le VM au `client` global cassait les tests (`LateInitializationError`). Fix : `authListenable` injecté (`ValueListenable<bool>`) via `AuthenticatedListenable`.
5. **API flutter_local_notifications v22** : `initialize(settings:)` (nommé), `requestNotificationsPermission()` (pas `requestNotifications`).
6. **idb + Python 3.14** : fb-idb 1.1.7 cassé (asyncio.get_event_loop supprimé en 3.14). Patch local du fichier site-packages.
7. **Session auth survit à l'uninstall** : flutter_secure_storage utilise le Keychain iOS qui survit à l'uninstall sur simulateur. Fix pour test propre : `xcrun simctl erase` du simulateur.

---

## Current state

- **F01 TERMINÉ et VALIDÉ sur simulateur** (smoke test 6/6 vert, flux complet from scratch après erase simulateur).
- `dart analyze` : 0 warning, 0 erreur côté serveur ET Flutter.
- Tests : 69 Flutter verts + 6 intégration serveur verts.
- **Validation statique + runtime complète**.
- **PAS de merge dans main** — c'est l'utilisateur qui fait le merge après validation.
- Google/Apple Sign-In : NON implémenté (email d'abord, configs console requises).

---

## Branches git (prêtes pour merge par l'utilisateur)

### `portea_server` : `feat/f01-onboarding` (2 commits)
- `feat(F01): backend kennel endpoint + model table`
- `test(F01): kennel endpoint integration tests`

### `portea_flutter` : `feat/f01-onboarding` (9 commits)
- `feat(F01): ServerpodKennelRepository + shared_preferences cache`
- `feat(F01): sign-in screen + onboarding auth flow`
- `style: dart format sur ecrans existants`
- `feat(F01): real notification permission request`
- `chore(F01): remove orphan lib/screens + fix hardcoded color + lint fixes`
- `test(F01): onboarding viewmodel auth-driven completion tests`
- `fix(F01): switch iOS from SPM to CocoaPods for plugin native integration`
- `fix(F01): onboarding notifications screen skipped + permission diagnostic`
- `chore(F01): remove notification diagnostic code (popup validated)`

---

## Next session starts with

**F02 — Reproducteurs (CRUD breeders → Serverpod)**

1. Lire `features/F02_reproducteurs.md`
2. Backend : `breeder.spy.yaml` → vérifier/ajouter table + userId, créer `breeder_endpoint.dart` (getBreeders, createBreeder, updateBreeder, deleteBreeder — session-based)
3. `serverpod generate` + migration
4. `ServerpodBreederRepository implements IBreederRepository` + swap dans main.dart
5. Tests + validation

---

## Open questions

- **Google/Apple Sign-In** : configs console Google + Apple Developer requises. À demander à l'utilisateur avant d'implémenter.
- **Merge F01 dans main** : l'utilisateur fait le merge lui-même après validation simulateur (déjà validé).
