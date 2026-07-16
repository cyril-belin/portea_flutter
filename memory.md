# Memory — Portea (état post-F03)

Last updated: 2026-07-16

---

## État du projet

**F01 Onboarding + Auth**, **F02 Reproducteurs** et **F03 Portées** sont TERMINÉS,
validés et **mergés sur `main`** dans les deux repos (`portea_server` + `portea_flutter`).

| Fonctionnalité | Backend | Frontend | main |
|----------------|---------|----------|------|
| F01 Onboarding (auth + kennel) | Serverpod | Serverpod | mergé |
| F02 Reproducteurs | Serverpod | Serverpod | mergé |
| F03 Portées (limite freemium) | Serverpod | Serverpod | mergé |
| F04-F10 | mock | UI faite, mock | — |

- portea_server main : merge commit `778968d` (ahead 4 vs origin, **push pas fait**).
- portea_flutter main : merge commit `b36ee72` (ahead 9 vs origin, **push pas fait**).
- README.md, memory.md et ROADMAP.md à jour sur main.

---

## Pattern établi (À RÉPLIQUER sur tous les futurs endpoints)

Le pattern endpoint + test d'intégration a été stabilisé en F01 puis F02, raffiné en F03.
**Toute nouvelle entité backend doit suivre ce canevas.**

### Modèle `.spy.yaml`
- Toujours la clé `table: <name>` (sinon non persisté — piège F01/Kennel, F03/Litter).
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

### Règle freemium / erreur métier typée (F03)
- Exception sérialisable dédiée via `.spy.yaml` avec le mot-clé `exception:` :
  ```yaml
  exception: ActiveLitterLimitException
  fields:
    message: String, default="..."
  ```
- Après `serverpod generate`, catchable côté client via `on ActiveLitterLimitException`.
- L'endpoint `throw` l'exception (PAS une Exception générique) ; le ViewModel
  l'intercepte et expose un **enum outcome** (success / <businessLimit> / error) ;
  l'écran transforme `<businessLimit>` en navigation paywall `/premium`,
  error en SnackBar (PAS de paywall sur erreur générique).

### Test d'intégration (`test/integration/<entity>_endpoint_test.dart`)
4 cas obligatoires, avec `withServerpod` + `AuthenticationOverride` :
1. **Unauthenticated** → `throwsA(isA<ServerpodUnauthenticatedException>())`
2. **Create** ignore le `kennelId` client (forge rejetée).
3. **Isolation inter-kennels** : user A ne voit pas les données de user B.
4. **Update** préserve `kennelId` + throw sur tentative de vol.
Plus les cas métier spécifiques (ex. F03 : limite portée active → exception typée
+ litter existante préservée ; saillie externe père null).

Helper réutilisable : seed un `Kennel` par utilisateur avant les tests d'entité.
Référence : `test/integration/litter_endpoint_test.dart` (10 tests, le plus complet).

### Frontend
- `<feature>/data/repositories/serverpod_<entity>_repository.dart` implémente
  l'interface via `client.<entity>.*`.
- Swap dans `main.dart`. `Mock<Entity>Repository` conservé pour les tests.
- **Résoudre les noms (mère, etc.) réellement via le repo, jamais hardcoder**
  (F03 a retiré 2 hardcodages "Salsa" dans Dashboard + écran Historique).
- **StatefulShellRoute.indexedStack** garde les onglets en mémoire →
  `ShellScaffold._onTap` doit rafraîchir le ViewModel de l'onglet cible au retour
  (sinon état stale, ex. portée déclarée invisible sur Accueil).

---

## Next session starts with

**F04 — Chiots (CRUD puppies → Serverpod)**

1. Lire `features/F04*.md` (source de vérité).
2. Backend : `puppy.spy.yaml` (**vérifier clé `table:`** — le modèle existe déjà
   côté client mais la table n'est pas persistée, même piège que litter avant F03),
   `puppy_endpoint.dart` (getPuppies by litter, createPuppy, createPuppiesBatch,
   updatePuppy — répliquer pattern litter/breeder).
   `serverpod generate` + `create_migration` + `apply_migrations`.
3. Frontend : `ServerpodPuppyRepository` + swap `main.dart`.
4. **Bug F04 connu (ROADMAP)** : `MockPuppyRepository.createPuppiesBatch` fait
   toujours des `add` (jamais d'update) → duplication à chaque sauvegarde ;
   `loadLitterPuppies` pré-remplit 3 chiots mockers ; rien n'est persisté.
   Le backend puppy + repo serveur corrigera ça (penser update vs create).
5. Tests d'intégration endpoint sur le pattern F02/F03.

---

## Contraintes de session

- Doc Serverpod v4 obligatoire (https://docs.serverpod.dev/next) — via context7.
- **Tu ne lances PAS le serveur** : tu demandes `serverpod start` + run simulateur.
  MAIS tu peux STOPPER le serveur (`kill -TERM <pid>`, lsof -iTCP:8080) et
  wiper la DB (`find portea_server/.serverpod/development -mindepth 1 -delete`)
  + erase simulateur (`xcrun simctl shutdown <udid> && xcrun simctl erase <udid>`)
  pour un reset A→Z propre (efface app + Keychain = auth).
- Toute idée hors périmètre → 1 ligne `ROADMAP.md`, zéro discussion.
- Annonce ton plan et attends le GO avant d'écrire le moindre fichier.
- Workflow git : branche `feat/fXX-*` dans les 2 repos, commits atomiques,
  INTERDIT commit/push sur main, merge `--no-ff` (user ou assistant sur demande
  explicite) après smoke test.

---

## Smoke test éprouvé : pilotage via widget inspector (DTD)

- idb cassé (Python 3.14), flutter_driver non activé → pas de tap/UI automation.
- MAIS `widget_inspector get_widget_tree` fonctionne sur l'app iOS connectée au DTD :
  relève l'arbre pour confirmer objectivement les écrans (ex. `PorteaPremiumScreen`
  au sommet = paywall ouvert, pas un SnackBar ; vrai nom de mère au lieu d'un mock).
- DTD : `listDtdUris` → connect au DTD flutter (workspace portea_flutter) →
  `listConnectedApps` → `widget_inspector` avec l'appUri retourné.

---

## Hors-F03 noté dans ROADMAP.md (zéro discussion, à traiter plus tard)

- F04 chiots (backend puppy + bug duplication/non-persistance).
- Lenteur mobile (à profiler), date picker naissance EN (i18n FR),
  suppression compte KO (SnackBar seul), « Ajouter mes reproducteurs d'abord »
  persistant après ajout, UI clôture manuelle de portée, photo reproducteur
  (image_picker).
- `Kennel.premiumUntil` (F10) — débloquera le test du chemin premium
  (`_isKennelPremium` retourne `false` par défaut, TODO commenté).

---

## Problèmes résolus transportables

- `session.authenticated` synchrone en Serverpod v4 (la doc Context7 v3 montrait `await` → erreur).
- iOS : CocoaPods pas SPM (`flutter config --no-enable-swift-package-manager`).
- Session auth survit à l'uninstall (Keychain iOS) → `xcrun simctl erase` pour test propre.
- idb + Python 3.14 : fb-idb 1.1.7 cassé, patch local (pas fiable → widget inspector).
- serverpod start utilise un Postgres embarqué (port 8090, data dans
  `.serverpod/development/pgdata`, password dans `config/passwords.yaml`).
  Pas de `psql` embarqué (uniquement initdb/pg_ctl/postgres dans
  `~/Library/Caches/serverpod/pg-binaries/`).
- Exceptions sérialisables v4 : `.spy.yaml` `exception: Name` + `fields:`,
  catchables côté client via `on NameException` après generate.
