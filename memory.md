# Memory — Portea (état post-F02)

Last updated: 2026-07-16

---

## État du projet

**F01 Onboarding + Auth** et **F02 Reproducteurs** sont TERMINÉS, validés et
**mergés sur `main`** dans les deux repos (`portea_server` + `portea_flutter`).

| Fonctionnalité | Backend | Frontend | main |
|----------------|---------|----------|------|
| F01 Onboarding (auth + kennel) | Serverpod | Serverpod | mergé |
| F02 Reproducteurs | Serverpod | Serverpod | mergé |
| F03-F10 | mock | UI faite, mock | — |

---

## Pattern établi (À RÉPLIQUER sur tous les futurs endpoints)

Le pattern endpoint + test d'intégration a été stabilisé en F01 puis F02.
**Toute nouvelle entité backend doit suivre ce canevas.**

### Modèle `.spy.yaml`
- Toujours la clé `table: <name>` (sinon non persisté — piège F01/Kennel).
- FK vers kennel : `kennelId: int`.

### Endpoint (`lib/src/endpoints/<entity>_endpoint.dart`)
- `@override bool get requireLogin => true;`
- Kennel dérivé de la session, **jamais** en param client :
  ```dart
  final userId = session.authenticated?.authUserId; // synchrone en v4
  final kennel = await Kennel.db.findFirstRow(
    session, where: (t) => t.userId.equals(userId));
  ```
- **Filtre `WHERE kennelId` sur TOUTES les requêtes** (find, findFirstRow).
- `kennelId` écrasé côté serveur à la création ; vérifié + préservé à l'update
  (anti-forge : un update qui tente de changer de kennel est rejeté).
- `update` : toujours `findFirstRow` avec filtre `id & kennelId` avant
  `copyWith` + `updateRow`.

### Test d'intégration (`test/integration/<entity>_endpoint_test.dart`)
4 cas obligatoires, avec `withServerpod` + `AuthenticationOverride` :
1. **Unauthenticated** → `throwsA(isA<ServerpodUnauthenticatedException>())`
2. **Create** ignore le `kennelId` client (forge rejetée).
3. **Isolation inter-kennels** : user A ne voit pas les données de user B
   (getBreeders filtré, getBreeder retourne null, update throw).
4. **Update** préserve `kennelId` + throw sur tentative de vol.

Helper réutilisable : seed un `Kennel` par utilisateur avant les tests
d'entité (sinon `_requireKennelId` throw).

Référence : `test/integration/breeder_endpoint_test.dart` (7 tests, le plus
complet). Réf F01 : `kennel_endpoint_test.dart`.

### Frontend
- `<feature>/data/repositories/serverpod_<entity>_repository.dart` implémente
  l'interface via `client.<entity>.*`.
- Swap dans `main.dart`. `Mock<Entity>Repository` conservé pour les tests.

---

## Décisions de F02

- **Règle retraité** : un breeder `status == 'retired'` n'apparaît pas dans les
  listes de sélection de `LitterDeclarationScreen`. Déjà implémentée côté
  `LitterDeclarationViewModel` (filtre `status == 'active'`), rien à faire.
- **Photo upload** : HORS SCOPE F02. `photoUrl` = URL saisie manuellement.
  Upload `image_picker` → voir `ROADMAP.md`.

---

## Étapes fin de session (workflow git)

1. Branche `feat/fXX-*` dans `portea_server` ET `portea_flutter`.
2. Commits atomiques au fil de la session.
3. INTERDIT : commit/push sur main, merge, force-push. Le merge (user) se fait
   après smoke test simulateur.
4. Fin de session : `git push -u origin <branche>` puis merge `--no-ff` dans
   main (message `Merge feat/fXX-*: ... (fXX terminé)`).

---

## Problèmes résolus (transportables)

- **`session.authenticated` synchrone en Serverpod v4** (la doc Context7 v3
  montrait `await` → erreur). C'est un getter synchrone.
- **iOS : CocoaPods, pas SPM**. `flutter config --no-enable-swift-package-manager`.
  SPM ne référençait pas flutter_local_notifications.
- **Session auth survit à l'uninstall** (flutter_secure_storage = Keychain iOS).
  Test propre : `xcrun simctl erase` du simulateur.
- **idb + Python 3.14** : fb-idb 1.1.7 cassé, patch local site-packages.

Détails complets F01 dans l'historique git (`feat/f01-onboarding`).

---

## Next session starts with

**F03 — Portées (CRUD litters → Serverpod)**

1. Lire `features/F03_portees.md`.
2. Backend : `litter.spy.yaml` (vérifier/ajouter `table:` + `kennelId`),
   `litter_endpoint.dart` (getLitters, getActiveLitter, createLitter,
   updateLitter) — répliquer le pattern ci-dessus.
3. **Point d'attention métier F03** : la logique actuelle
   (`LitterDeclarationViewModel.declareLitter`) désactive systématiquement la
   portée active précédente (« only 1 active litter in this simple flow »).
   Spécifier le comportement V1 : erreur métier « limite portée active »
   (freemium) → ouverture paywall plutôt que switch silencieux. À clarifier
   avec l'utilisateur avant implémentation.
4. `serverpod generate` + migration.
5. `ServerpodLitterRepository` + swap `main.dart`.
6. Tests d'intégration (pattern breeder) + validation.

---

## Open questions

- **Google/Apple Sign-In** : configs console requises. Email d'abord.
- **Limite portée active (F03)** : erreur + paywall vs switch silencieux ?
