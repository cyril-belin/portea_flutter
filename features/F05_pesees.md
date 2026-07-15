# F05 — Pesées

## Objectif

Permettre la pesée groupée de tous les chiots d'une portée, la pesée individuelle depuis la fiche chiot, l'affichage de l'historique des poids et des courbes de croissance.

---

## État actuel (audit 2026-07-15)

### Fait ✅
- `GroupWeighingScreen` — pesée groupée : liste des chiots avec dernier poids, saisie du nouveau poids, sauvegarde en lot
- `GroupWeighingViewModel` — `loadLitterPuppies()` avec dernier poids résolu, `updateWeight()`, `saveWeighingSession()`
- `PuppyFileScreen` — historique des pesées + dialog "Ajouter une pesée" individuelle (bottom sheet)
- `PuppyFileViewModel.addSingleWeight()` — ajout d'une pesée individuelle
- `IWeighingRepository` — `getWeighings(puppyId)`, `addWeighing()`, `addWeighings()`
- `MockWeighingRepository` — in-memory fonctionnel, trié par date
- Route `/litters/:id/weighing`
- Tests unitaires `GroupWeighingViewModel` + `WeighingRepository` passing

### Absent / partiel ⚠️
- **`ServerpodWeighingRepository`** : absent
- **Courbe de croissance** : les données sont présentes (liste de `WeighingEntry` triée par date) mais le rendu graphique dans `PuppyFileScreen` doit être vérifié — si absent, il faut l'ajouter avec un package de chart (ex. `fl_chart`)
- **Premium — courbe exportable** : listé dans les avantages premium de `PorteaPremiumScreen` mais non implémenté

---

## Reste à faire

### Backend (portea_server)
- [ ] Endpoint `weighing` : `getWeighings(session, puppyId)`, `addWeighing(session, entry)`, `addWeighings(session, entries)`
- [ ] Validation serveur : le `puppyId` appartient au kennel de la session
- [ ] `serverpod generate`

### Data layer
- [ ] `ServerpodWeighingRepository implements IWeighingRepository`
- [ ] Swapper dans `main.dart`

### UI
- [ ] Vérifier la présence d'un rendu de courbe de croissance dans `PuppyFileScreen`
  - Si absent : ajouter `fl_chart` au pubspec + widget `GrowthCurveWidget` (courbe date/poids)
  - Si présent : valider qu'il affiche correctement avec données réelles
- [ ] Export de la courbe (PNG/PDF) — premium — à implémenter en F09 si possible, ou V2

---

## Écrans concernés

| Écran | Fichier | État |
|-------|---------|------|
| Pesée groupée | `puppies/presentation/screens/group_weighing_screen.dart` | ✅ Fait |
| Fiche chiot (pesées) | `puppies/presentation/screens/puppy_file_screen.dart` | ✅ Fait (partiel) |

---

## Règles métier

1. Les poids sont en **grammes** (`double` dans le modèle `WeighingEntry.weightGrams`).
2. L'historique est trié par date croissante (du plus ancien au plus récent).
3. Le "dernier poids" affiché est le `weightGrams` de l'entrée la plus récente.
4. La pesée groupée crée une `WeighingEntry` par chiot ayant un poids saisi (les cases vides = non pesés = ignorés).
5. La courbe de croissance est accessible sur la fiche chiot. En premium, elle peut être exportée.
6. `WeighingEntry.puppyId` est obligatoire.

---

## Critères d'acceptation

- [ ] Pesée groupée → toutes les entrées persistées sur Serverpod.
- [ ] Pesée individuelle depuis la fiche chiot → persistée.
- [ ] Historique affiché correctement trié par date.
- [ ] Courbe de croissance visible sur la fiche chiot.
- [ ] `dart analyze` 0 warning.
- [ ] `flutter test` vert sur `GroupWeighingViewModel` + `WeighingRepository` tests.
