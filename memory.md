# Memory — Portea (état post-F04 développé, non mergé)

Last updated: 2026-07-17

---

## État du projet

**F01, F02, F03, F03-bis** TERMINÉS, validés et **mergés sur `main`** (deux repos).
**F04 Chiots** DÉVELOPPÉ ce jour sur branche `feat/f04-chiots` des deux repos,
**validation locale verte**, **non mergé** (attente smoke test utilisateur +
purge manuelle des chiots dupliqués en base locale avant merge).

| Fonctionnalité | Backend | Frontend | main |
|----------------|---------|----------|------|
| F01 Onboarding | Serverpod | Serverpod | mergé |
| F02 Reproducteurs | Serverpod | Serverpod | mergé |
| F03 Portées (freemium) | Serverpod | Serverpod | mergé |
| F03-bis Hardening litter | Serverpod | non touché | mergé |
| **F04 Chiots (batch idempotent)** | **Serverpod** | **Serverpod** | **feat/f04-chiots, à merger** |
| F05-F10 | mock | UI mock | — |

- portea_server : branche `feat/f04-chiots`, commit `54b0056` (sur main `ed96718`).
- portea_flutter : branche `feat/f04-chiots`, commit `5f2bd9b` (sur main `b36ee72`).
- **Push origin pas fait** (sur toutes branches, comme avant).

---

## F04 — ce qui a été fait

### Backend (portea_server, commit `54b0056`)
- `lib/src/models/puppy.spy.yaml` : clé **`table: puppy`** ajoutée (même piège
  que litter — sans elle rien n'était persisté) + champ **`cessionDate: DateTime?`**
  posé dès maintenant pour F08 (**aucune logique F04 dessus**).
- **Exceptions sérialisables** (pattern `.spy.yaml`, pas de migration) :
  - `invalid_puppy_relation_exception.spy.yaml` — item.id n'appartenant pas au
    litter / puppy introuvable.
  - `puppy_deletion_not_allowed_exception.spy.yaml` — suppression refusée
    (historique présent).
  - `InvalidLitterRelationException` (existante) reste **réservée aux cas litter**
    (litter introuvable/étranger).
- `lib/src/endpoints/puppy_endpoint.dart` (pattern F02/F03 : requireLogin,
  kennel dérivé session, anti-forge) :
  - `getPuppies(litterId)` : assert litter ∈ kennel session.
  - `getPuppy(id)` : foreign puppy → **null** (cohérent avec getLitter/getBreeder,
    ne leak jamais l'existence).
  - **`savePuppiesBatch(litterId, items)`** — cœur F04 : **une seule
    `session.db.transaction`**. id null → insert ; id présent → update après
    vérif appartenance litter (forgé → `InvalidPuppyRelationException`, rien
    écrit) ; chiots en base absents des items → delete si `_canDelete` (check
    codé mais **trivialement vrai en F04** — tables pesées/soins inexistantes,
    TODO F05/F06). Retourne la liste fraîche. Échec → rollback, aucune écriture
    partielle.
- Migration `20260717104830956` : CREATE TABLE `puppy` (+ cessionDate).
- `test/integration/puppy_endpoint_test.dart` : **12 cas** (unauth, isolation
  inter-kennels getPuppies/savePuppiesBatch/getPuppy, anti-forge item.id →
  rollback total, édition sans duplication, idempotence double-save même ids,
  drop-line → delete, échec mid-batch → litter inchangée).
- **Suite serveur : 44/44 verts** (`dart test --concurrency=1`). `dart analyze` : 0.

### Frontend (portea_flutter, commit `5f2bd9b`)
- `IPuppyRepository` : `createPuppiesBatch` → **`savePuppiesBatch(litterId, items)`
  → `List<Puppy>`**. `MockPuppyRepository` adapte (miroir sémantique serveur).
- **`ServerpodPuppyRepository`** (nouveau, `client.puppy.*`), swappé dans `main.dart`.
- **`PuppyBatchViewModel` réécrit** (correction bugs verdict 4.1) :
  - `PuppyBatchItem` gagne **`int? id`** (clé de l'idempotence).
  - Injecte **`IKennelRepository`** ; `loadLitterPuppies(litterId)` async résout
    `species` elle-même (l'écran ne pousse rien), charge via le repo. **Suppression
    des 3 mocks en dur**. Litter vide → form vide.
  - `saveBatch` envoie items avec ids, recharge depuis le serveur (nouveaux ids).
  - Libellés **« Chiot N »/« Chaton N »** dérivés de `Kennel.species` (getters
    `youngNoun`/`youngNounPlural`/`youngNounCapitalized`). **Zéro chaîne espèce en dur**.
- **`puppy_batch_creation_screen.dart`** : `loadLitterPuppies(widget.litterId)`
  (fin du `[]` littéral) ; état vide chargé → bouton d'ajout ; libellés
  species-aware ; SnackBar sur échec.
- `main.dart` : `PuppyBatchViewModel` passe en `ChangeNotifierProxyProvider2<
  IKennelRepository, IPuppyRepository, ...>`.
- `test/features/puppies/puppies_test.dart` : tests `PuppyBatchViewModel` **réécrits**
  (les anciens validaient le bug — ex. `dbList.length == 6` après édition).
  11 nouveaux cas VM + 3 Mock savePuppiesBatch.
- **Suite flutter : 77/77 verts.** `flutter analyze` : 0 issues.

### Correction des 3 retours utilisateur (vs plan initial)
1. **Exception dédiée** `InvalidPuppyRelationException` (pas réutilisation de
   `InvalidLitterRelationException` pour les cas puppy).
2. **`IKennelRepository` injecté** dans le VM (pas de setter alimenté par l'écran) ;
   `loadLitterPuppies` résout species seule.
3. **Test transaction échec** : harnais par défaut (rollback niché), pas de
   `RollbackDatabase.disabled`.

---

## Validation F04 (référence pour smoke test / merge)

- `dart test --concurrency=1` (serveur) : **44/44 verts** (32 existants + 12 puppy).
- `flutter test` : **77/77 verts**.
- `dart analyze` (serveur) + `flutter analyze` : **0 warning**.
- Migration appliquée (`20260717104830956`). `hot_restart` MCP : OK, pas d'erreur
  runtime dans `tail_flutter_logs` / `tail_server_logs`.

### À FAIRE AVANT MERGE (par l'utilisateur)
- **Purger les chiots dupliqués** créés lors des tests du 2026-07-17 (base locale)
  — sinon le smoke test est invérifiable. **C'est l'utilisateur qui le fait.**
- Smoke test manuel (création batch, édition sans duplication, espèce cat).
- Puis : merge `--no-ff` par l'utilisateur + suppression branche.

---

## Pattern F04 — ajout transportable (au pattern F01-F03-bis)

- **Batch idempotent transactionnel** : une seule `session.db.transaction((tx) async {...})`
  englobant inserts/updates/deletes ; id null → insert, id présent → update après
  vérif d'appartenance (anti-forge via findFirstRow id & parent), absents du
  payload → delete (avec garde métier). Retourne l'état frais. Tout échec →
  exception typée → rollback automatique.
- **`getPuppy` foreign → null** (pas d'exception) pour rester cohérent avec les
  getters existants (getLitter/getBreeder retournent null sur foreign).
- **`.spy.yaml` exception avec message contenant parenthèses/apostrophes** : le
  parseur inline casse sur `default="...(...)"`. Simplifier le message (éviter
  les parenthèses) ou le format marche. Apostrophes simples OK.
- **VM qui dépend de Kennel.species** : injecter `IKennelRepository`, résoudre
  dans la méthode de load (un seul point d'entrée), jamais de setter alimenté
  par l'écran (ordre d'init fragile). Getters publics pour les libellés.

---

## Next session starts with

**F04 développé et validé localement, en attente de smoke test + purge base +
merge par l'utilisateur.** Si l'utilisateur confirme le merge, reprendre sur
**F05 (Pesées)** ou **F06 (Soins groupés)** — les TODO `_canDelete` dans
`puppy_endpoint.dart` pointent exactement où décommenter les checks de suppression
une fois ces tables créées (le verrou anti-suppression-avec-historique est déjà
en place, trivialement vrai tant que les tables n'existent pas).

Rappel config : `dart test --concurrency=1` (parallèle cassé, claim 5.1).

---

## Contraintes de session (rappel, inchangées)

- Doc Serverpod v4 obligatoire — via context7.
- **Tu ne lances PAS le serveur** : tu demandes `serverpod start` + run simulateur.
- Toute idée hors périmètre → 1 ligne `ROADMAP.md`, zéro discussion.
- Workflow git : branche `feat/fXX-*`, commits atomiques, INTERDIT commit/push
  sur main, merge `--no-ff` (user) après smoke test.
