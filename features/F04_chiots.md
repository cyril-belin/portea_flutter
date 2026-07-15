# F04 — Chiots

## Objectif

Permettre la création rapide en lot des chiots d'une portée (nom pré-rempli, sexe, couleur, poids de naissance) depuis la fiche portée.

---

## État actuel (audit 2026-07-15)

### Fait ✅
- `PuppyBatchCreationScreen` — interface de création en lot : liste de lignes chiot avec nom auto-incrémenté ("Chiot 1", "Chiot 2"…), sélection sexe, couleur, poids naissance
- `PuppyBatchViewModel` — `loadLitterPuppies()` (pré-remplit si chiots existants), `addItem()`, `removeItem()`, `updateSex()`, `saveBatch()`
- `IPuppyRepository` — `getPuppies`, `getPuppy`, `createPuppy`, `createPuppiesBatch`, `updatePuppy`
- `MockPuppyRepository` — in-memory fonctionnel
- Route `/litters/:id/puppies/batch`
- Tests unitaires `PuppyBatchViewModel` passing

### Absent / partiel ⚠️
- **`ServerpodPuppyRepository`** : absent
- **Poids de naissance** : collecté dans le batch mais `birthWeight` est `double?` dans le modèle — vérifier que le champ est bien envoyé au serveur
- **`chipNumber`** : champ présent sur `Puppy` mais non collecté lors de la création batch (peut être ajouté plus tard sur la fiche individuelle)

---

## Reste à faire

### Backend (portea_server)
- [ ] Endpoint `puppy` : `getPuppies(session, litterId)`, `getPuppy(session, id)`, `createPuppy(session, puppy)`, `createPuppiesBatch(session, puppies)`, `updatePuppy(session, puppy)`
- [ ] Validation serveur : le `litterId` appartient bien au kennel de la session
- [ ] `serverpod generate`

### Data layer
- [ ] `ServerpodPuppyRepository implements IPuppyRepository`
- [ ] Swapper dans `main.dart`

---

## Écrans concernés

| Écran | Fichier | État |
|-------|---------|------|
| Création lot chiots | `puppies/presentation/screens/puppy_batch_creation_screen.dart` | ✅ Fait |

---

## Règles métier

1. La création batch s'accède depuis la fiche portée (`/litters/:id/puppies/batch`).
2. Si des chiots existent déjà pour cette portée, le batch pré-remplit les lignes avec les chiots existants (modification, pas duplication).
3. Nom par défaut : "Chiot N" (ou "Chaton N" si `species = 'cat'`) — le libellé s'adapte à l'espèce du kennel.
4. Sexe obligatoire. Couleur et poids naissance optionnels (mais fortement recommandés).
5. Le `litterId` est transmis au batch depuis la fiche portée.

---

## Critères d'acceptation

- [ ] Création d'un lot de chiots → persisté sur Serverpod.
- [ ] Modification du lot existant → mise à jour correcte.
- [ ] Libellé "Chiot/Chaton" adapté à l'espèce du kennel.
- [ ] `dart analyze` 0 warning.
- [ ] `flutter test` vert sur `PuppyBatchViewModel` tests.
