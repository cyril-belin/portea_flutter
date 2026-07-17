# Memory — Portea (état post-F03-bis mergé)

Last updated: 2026-07-17

---

## État du projet

**F01 Onboarding + Auth**, **F02 Reproducteurs**, **F03 Portées**, et
**F03-bis (durcissement litter)** TERMINÉS, validés et **mergés sur `main`**
dans les deux repos (`portea_server` + `portea_flutter`).

| Fonctionnalité | Backend | Frontend | main |
|----------------|---------|----------|------|
| F01 Onboarding (auth + kennel) | Serverpod | Serverpod | mergé |
| F02 Reproducteurs | Serverpod | Serverpod | mergé |
| F03 Portées (limite freemium) | Serverpod | Serverpod | mergé |
| F03-bis Hardening litter (claims 1.1 + 1.2) | Serverpod | **non touché** | mergé |
| F04-F10 | mock | UI faite, mock | — |

- portea_server main : merge commit `ed96718` (F03-bis) + commit `ede6aa9`
  (doc README backend). **Ahead 4 vs origin, push pas fait.**
- portea_flutter main : merge commit `b36ee72` (ahead 9 vs origin, **push pas fait**).
- Frontend **non modifié** en F03-bis (justifié : l'exception typée tombe dans
  le chemin error→SnackBar existant, aucun paywall induit).
- **README server** réécrit (`portea_server/README.md`) : doc backend complète
  (stack, monorepo, modèles, exceptions, endpoints, règles métier freemium
  atomique + validation relations, migrations, tests, génération).

---

## F03-bis — ce qui a été fait (correctifs claims 1.1 + 1.2)

Source du mandat : `doc/review_externe_verdicts.md` sections **1.1 et 1.2
uniquement** (le reste des claims est hors session, à traiter plus tard).

### Claim 1.1 — Validation des relations (createLitter + updateLitter)
- Nouvelle exception sérialisable `InvalidLitterRelationException`
  (déclarée dans `lib/src/exceptions/invalid_litter_relation_exception.spy.yaml`,
  pattern strict d'`ActiveLitterLimitException`).
- La mère doit exister, appartenir au kennel de session, être `female` + `active`.
- Le père interne (si fatherId fourni) : mêmes contrôles avec `male` + `active`.
- Refus fatherId ET externalSireName ensemble ; refus si ni l'un ni l'autre.
- Tout refus → exception typée, **jamais** d'`Exception('...')` générique.

### Claim 1.2 — Atomicité freemium + réactivation
- Nouveau service `lib/src/services/litter_activation_guard.dart` :
  `LitterActivationGuard.assertCanActivate(session, transaction, kennel)`
  (count portées actives + statut premium).
- Appelé par **createLitter ET updateLitter** sur réactivation `isActive false→true`.
- `createLitter` et `updateLitter` encapsulent check + insert/update dans
  `session.db.transaction` avec **verrou `LockMode.forUpdate` sur la ligne
  `Kennel` du propriétaire** (stratégie « lock the parent row »).
- `_isKennelPremium` déplacé dans le guard (point d'extension F10 unique).
- Clôture `isActive true→false` reste libre, aucune règle.

### Fichiers touchés
- `lib/src/exceptions/invalid_litter_relation_exception.spy.yaml` (créé)
- `lib/src/services/litter_activation_guard.dart` (créé)
- `lib/src/endpoints/litter_endpoint.dart` (createLitter + updateLitter réécrits)
- `lib/src/generated/protocol.dart`, `lib/src/generated/exceptions/invalid_litter_relation_exception.dart` (régénérés par `serverpod generate`)
- `test/integration/litter_endpoint_test.dart` (8 cas + adaptation des anciens)

---

## Validation F03-bis (référence pour le smoke test / merge)

- `dart test --concurrency=1` : **32/32 verts** (9 anciens F03 + 6 breeder +
  1 greeting + 6 kennel + nouveaux). Tests F03-bis = 18 dans le fichier litter.
- `dart analyze` : **0 warning** côté serveur.
- `dart format` : à jour.
- **Pas de migration** nécessaire (une exception n'est pas une table) :
  seul `serverpod generate` a tourné.

### Les 8 cas de test F03-bis (tous ✅)
1. createLitter mère inexistante → InvalidLitterRelationException
2. createLitter mère d'un autre kennel → typée
3. createLitter mère de sexe male → typée
4. createLitter mère statut inactif → typée
5. fatherId + externalSireName ensemble → refus typé
6. ni père interne ni externe → refus typé
7. updateLitter réactivation sur non-premium avec portée active → ActiveLitterLimitException
8. deux createLitter concurrents même kennel gratuit → un seul réussit

---

## Pattern établi (À RÉPLIQUER sur tous les futurs endpoints)

Le pattern endpoint + test d'intégration a été stabilisé en F01 puis F02, raffiné en F03, durci en F03-bis.
**Toute nouvelle entité backend doit suivre ce canevas.**

### Modèle `.spy.yaml`
- Toujours la clé `table: <name>` (sinon non persisté — piège F01/Kennel, F03/Litter).
- FK vers kennel : `kennelId: int`.

### Exception sérialisable (`.spy.yaml` dans `lib/src/exceptions/`)
```yaml
exception: NameException
fields:
  message: String, default="..."
```
- Après `serverpod generate`, catchable côté client via `on NameException`.
- Une exception n'est PAS une table → **pas de `create_migration`**.
- L'endpoint `throw` l'exception typée (PAS une `Exception` générique) ;
  le ViewModel l'intercepte et expose un enum outcome
  (success / <businessLimit> / error) ; l'écran transforme <businessLimit> en
  navigation paywall, error en SnackBar.

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

### Transaction atomique + verrou (F03-bis, pattern freemium)
- Quand une règle métier dépend d'un count puis d'un insert/update, encapsuler
  dans `session.db.transaction((tx) async {...})` et passer `transaction: tx`
  à chaque requête de la transaction.
- Verrouiller la **ligne parent** (`LockMode.forUpdate` sur le `Kennel` du
  propriétaire) pour sérialiser les opérations concurrentes sur le même kennel.
  **`count` n'accepte PAS de `lockMode` en Serverpod v4** (vérifié dans le
  source du package) — le verrou doit porter sur la ligne parent, pas sur
  les lignes comptées.
- API v4 confirmée : `session.db.transaction(fn, settings: TransactionSettings(
  isolationLevel: IsolationLevel.serializable))`, `LockMode.forUpdate`,
  `LockBehavior.{wait,noWait,skipLocked}`. Imports : tout est dans
  `package:serverpod/serverpod.dart` (exporté via `serverpod/database.dart`).

### Test d'intégration (`test/integration/<entity>_endpoint_test.dart`)
Cas obligatoires (pattern F02) : unauthenticated, forge kennelId, isolation
inter-kennels, update préserve kennelId + throw sur vol. Plus les cas métier.

**Piège tests de concurrence (F03-bis)** : `withServerpod` wrappe chaque test
dans une transaction rollbackée par défaut (`RollbackDatabase.afterEach`) →
notre propre `db.transaction` y niche en savepoint, le verrou `FOR UPDATE`
n'est pas observable par un appel concurrent. Pour tester sainement la
concurrence : `withServerpod(..., rollbackDatabase: RollbackDatabase.disabled)`
+ nettoyage manuel en `tearDown` via `Model.db.deleteWhere`.

Rappel config : la suite tourne avec `dart test --concurrency=1`
(parallèle cassé, claim 5.1 — ne pas réparer).

### Frontend
- `<feature>/data/repositories/serverpod_<entity>_repository.dart` implémente
  l'interface via `client.<entity>.*`.
- Swap dans `main.dart`. `Mock<Entity>Repository` conservé pour les tests.
- **Résoudre les noms (mère, etc.) réellement via le repo, jamais hardcoder.**

---

## Problèmes résolus transportables (F03-bis ajouts)

- **Exceptions sérialisables v4** : `.spy.yaml` `exception: Name` + `fields:`
  dans `lib/src/exceptions/`, catchables côté client via `on NameException`
  après `serverpod generate`. Pas de migration (exception ≠ table).
- **Transactions v4** : `session.db.transaction`, `TransactionSettings`,
  `IsolationLevel`, `LockMode.forUpdate`, `LockBehavior` — tout exporté depuis
  `package:serverpod/serverpod.dart`. `count` n'a pas de param `lockMode`.
- **Test de concurrence** sous `withServerpod` : nécessite
  `rollbackDatabase: RollbackDatabase.disabled` pour que les transactions
  soient autonomes (sinon savepoint imbriqué, course non testable).

(Problèmes transportables antérieurs conservés : `session.authenticated`
synchrone en v4 ; CocoaPods pas SPM ; session auth survit à l'uninstall iOS ;
serverpod start utilise un Postgres embarqué port 8090.)

---

## Next session starts with

**F03-bis est mergé sur main** (merge `ed96718` + doc README `ede6aa9`).
Le push vers origin reste à faire (sur les deux repos) quand l'utilisateur le
demandera.

**F04 — Chiots (CRUD puppies → Serverpod)** (inchangé depuis l'état post-F03)

1. Lire `features/F04*.md` (source de vérité).
2. Backend : `puppy.spy.yaml` (**vérifier clé `table:`** — le modèle existe
   côté client mais la table n'est pas persistée, même piège que litter),
   `puppy_endpoint.dart` (getPuppies by litter, createPuppy, createPuppiesBatch,
   updatePuppy — répliquer pattern litter/breeder, et désormais le pattern
   transaction+verrou si une règle freemium s'applique).
   `serverpod generate` + `create_migration` + `apply_migrations`.
3. Frontend : `ServerpodPuppyRepository` + swap `main.dart`.
4. **Bug F04 connu (ROADMAP)** : `MockPuppyRepository.createPuppiesBatch` fait
   toujours des `add` (jamais d'update) → duplication à chaque sauvegarde ;
   `loadLitterPuppies` pré-remplit 3 chiots mockers ; rien n'est persisté.
5. Tests d'intégration endpoint sur le pattern F02/F03.

---

## Claims review externe ENCORE OUVERTS (hors F03-bis, à traiter plus tard)

Source : `doc/review_externe_verdicts.md` (lu en F03-bis, sections 1.1+1.2
traitées). Reste ouvert, **ne PAS traiter sans session dédiée** :

- **1.3** Absence de relations et contraintes en base (FK/index sur les `.spy.yaml`).
- **1.4** Validation métier dépendante de l'interface (pattern transverse).
- **1.5** Exceptions génériques restantes (ailleurs que litter).
- **2.x** Gestion d'erreurs frontend (exceptions absorbées, faux succès,
  états async incomplets, risques après dispose, courses, état mutable exposé).
- **3.x** Qualité code Flutter (écrans volumineux, dynamic, logique dispersée,
  duplication `_requireKennelId`, N+1).
- **4.x** Bugs métier (batch chiots, pesées, soins groupés, statut vendu,
  onboarding multi-compte, navigation id invalide).
- **5.x** Tests (config parallèle cassée claim 5.1 — `--concurrency=1` requis,
  widget tests absents, intégration Flutter absente, sécurité incomplète,
  tests lents).
- **11** Reproductibilité / gestion dépôt.

---

## Contraintes de session (rappel, inchangées)

- Doc Serverpod v4 obligatoire — via context7.
- **Tu ne lances PAS le serveur** : tu demandes `serverpod start` + run simulateur.
- Toute idée hors périmètre → 1 ligne `ROADMAP.md`, zéro discussion.
- Annonce ton plan et attends le GO avant d'écrire le moindre fichier.
- Workflow git : branche `feat/fXX-*` ou `fix/fXX-*`, commits atomiques,
  INTERDIT commit/push sur main, merge `--no-ff` (user) après smoke test.
