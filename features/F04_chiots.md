# F04 — Chiots

## Objectif

Permettre la création rapide en lot des chiots d'une portée (nom pré-rempli, sexe, couleur, poids de naissance) depuis la fiche portée, avec sauvegarde idempotente (création + modification + suppression), persistée sur Serverpod.

---

## État actuel (audit 2026-07-15, corrigé 2026-07-17 après audit contradictoire — verdict 4.1 CONFIRMÉ)

### Fait ✅
- `PuppyBatchCreationScreen` — interface de création en lot : liste de lignes chiot, sélection sexe, couleur, poids naissance
- `IPuppyRepository` — `getPuppies`, `getPuppy`, `createPuppy`, `createPuppiesBatch`, `updatePuppy`
- `MockPuppyRepository` — in-memory
- Route `/litters/:id/puppies/batch`
- Tests unitaires `PuppyBatchViewModel` passing (mais ils valident le comportement buggé — à réécrire)

### Buggé / faux ❌ (verdict 4.1 — preuves ligne par ligne dans `doc/review_externe_verdicts.md`)
- **L'écran ne charge jamais les chiots existants** : `puppy_batch_creation_screen.dart:26` appelle `loadLitterPuppies([])` avec une liste vide littérale.
- **Le ViewModel pré-remplit 3 chiots mock en dur** (`puppy_batch_view_model.dart:42-63`) au lieu d'appeler le repository.
- **`saveBatch()` = insert-only** (lignes 92-118) : jamais d'update. Chaque sauvegarde ajoute de nouveaux chiots → duplication constatée en usage réel le 2026-07-17 (édition d'un nom → +3 chiots).
- **`PuppyBatchItem` n'a pas de champ `id`** (lignes 5-17) : les IDs des chiots existants sont perdus au mapping.
- **Libellé « Chiot » hardcodé** (lignes 45-60, 71, 100) : jamais « Chaton », `Kennel.species` jamais consulté.

### Absent ⚠️
- **Backend inexistant** : aucun endpoint `puppy` ; `puppy.spy.yaml` existe côté serveur mais **sans clé `table:`** → modèle non persisté (même piège que litter avant F03, verdict 4.2).
- **`ServerpodPuppyRepository`** : absent.
- **`chipNumber`** : présent sur le modèle, non collecté au batch (fiche individuelle, plus tard — hors F04).

---

## Reste à faire

### Backend (portea_server)
- [ ] `puppy.spy.yaml` : ajouter la clé `table: puppy` (+ champ `cessionDate: DateTime?` posé dès maintenant pour éviter une migration en F08 — champ non utilisé en F04, aucune logique dessus).
- [ ] `serverpod generate` + migration + apply.
- [ ] Endpoint `puppy` (pattern F02/F03 : `requireLogin`, kennel dérivé de la session, anti-forge) :
  - `getPuppies(session, litterId)` — vérifie que le litter appartient au kennel de la session.
  - `getPuppy(session, id)` — filtre par kennel via le litter.
  - `savePuppiesBatch(session, litterId, items)` — **transactionnel et idempotent** (voir règles métier 6-9).
- [ ] Exceptions métier typées sérialisables (pattern `ActiveLitterLimitException` / `InvalidLitterRelationException`) : litter introuvable/étranger, puppy forgé, suppression refusée. Pas d'`Exception('...')` générique.

### Data layer (portea_flutter)
- [ ] `ServerpodPuppyRepository implements IPuppyRepository` + swap dans `main.dart`.
- [ ] `IPuppyRepository` : remplacer `createPuppiesBatch` par `savePuppiesBatch(litterId, items)` (adapter le Mock pour les tests unitaires).

### ViewModel / écran
- [ ] `PuppyBatchItem` : ajouter le champ `id: int?` (null = nouveau chiot).
- [ ] `loadLitterPuppies(litterId)` : charger les vrais chiots via le repository. Suppression des 3 mocks en dur. Portée sans chiots → formulaire vide + bouton d'ajout (état vide existant).
- [ ] `saveBatch()` : envoyer les items avec leurs IDs à `savePuppiesBatch`. Après succès, recharger depuis le serveur (les nouveaux chiots récupèrent leurs IDs).
- [ ] Libellé « Chiot N » / « Chaton N » dérivé de `Kennel.species` — plus aucune chaîne espèce en dur.
- [ ] Écran : passer le vrai `litterId` de la route (fin du `[]` littéral).

### Nettoyage préalable au smoke test
- [ ] Purger les chiots dupliqués créés lors des tests du 2026-07-17 (base locale), sinon le comptage du smoke test est invérifiable.

---

## Écrans concernés

| Écran | Fichier | État |
|-------|---------|------|
| Création lot chiots | `puppies/presentation/screens/puppy_batch_creation_screen.dart` | UI ✅ / logique ❌ (verdict 4.1) |

---

## Règles métier

1. La création batch s'accède depuis la fiche portée (`/litters/:id/puppies/batch`). Le `litterId` vient de la route.
2. Si des chiots existent déjà pour cette portée, le batch pré-remplit les lignes avec les chiots existants **chargés depuis le serveur** (modification, pas duplication).
3. Nom par défaut : « Chiot N » ou « Chaton N » selon `Kennel.species`.
4. Sexe obligatoire. Couleur et poids naissance optionnels.
5. Le serveur vérifie que le `litterId` appartient au kennel de la session, et que **chaque `item.id` fourni appartient bien à ce litter** (anti-forge : un id étranger → exception typée, rien n'est écrit).
6. `savePuppiesBatch` distingue : `id` null → création ; `id` présent → mise à jour ; chiot en base absent des items → suppression (règle 7).
7. **Suppression** : autorisée uniquement si le chiot n'a aucune pesée ni entrée de soin. Sinon → exception typée, la sauvegarde entière est refusée (message : retirer d'abord l'historique ou garder le chiot). Note : en F04, les tables `weighing_entry`/`care_entry` n'existent pas encore côté serveur, donc le check est codé mais trivialement vrai. Le poser maintenant évite l'oubli en F05/F06.
8. **Transaction unique** : tout le batch (inserts + updates + deletes) dans une seule `db.transaction`. Échec en cours → aucune écriture partielle.
9. **Idempotence** : sauvegarder deux fois le même formulaire sans modification ne change rien en base (mêmes chiots, mêmes IDs, même compte).

---

## Critères d'acceptation

- [ ] Création d'un lot → persisté sur Serverpod, IDs récupérés côté app.
- [ ] **Éditer le nom d'un chiot existant et sauvegarder → le chiot est modifié, aucun chiot créé** (le bug du 2026-07-17 ne peut plus se produire).
- [ ] **Double sauvegarde sans modification → zéro changement en base** (test d'intégration).
- [ ] Retirer une ligne et sauvegarder → chiot supprimé en base (cas sans historique).
- [ ] Batch avec un `item.id` d'un autre litter → exception typée, aucune écriture.
- [ ] `litterId` d'un autre kennel → exception typée (isolation, pattern F02).
- [ ] Élevage `species = cat` → « Chaton N » partout.
- [ ] Tests d'intégration endpoint sur le pattern F02/F03 (auth, isolation, anti-forge, idempotence, transaction).
- [ ] Tests unitaires `PuppyBatchViewModel` réécrits sur le nouveau comportement, verts.
- [ ] `dart test --concurrency=1` (serveur) + `flutter test` : tout vert. `dart analyze` / `flutter analyze` : 0 warning.

---

## Hors périmètre F04 (rappel)

- `chipNumber` au batch, upload photo chiot → fiche individuelle / ROADMAP.
- Toute logique sur `cessionDate` (le champ est posé au modèle, point) → F08.
- Statut chiot (disponible/réservé/vendu) → F08.
- Pesées et soins → F05/F06.