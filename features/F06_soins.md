# F06 — Soins

## Objectif

Permettre l'enregistrement de soins (vaccins, vermifuges, autres) pour un chiot individuel ou pour toute la portée, avec configuration d'un rappel optionnel.

---

## État actuel (audit 2026-07-15)

### Fait ✅
- `AddCareScreen` — formulaire complet : type (vaccin/vermifuge/autre), produit, date, cible (chiot individuel ou toute la portée), rappel optionnel (toggle + durée en jours)
- `AddCareViewModel.saveCareEntry()` — gère les deux cas : soin individuel (`CareEntry.puppyId`) et soin groupé (`CareEntry.litterId` + une entrée par chiot)
- `ICareRepository` — `getCareEntries({puppyId, litterId})`, `addCareEntry()`, `getUpcomingReminders(limit)`
- `MockCareRepository` — in-memory fonctionnel
- Route `/litters/:id/care?puppyId=<optional>` — `puppyId` en query param pour pré-sélectionner un chiot
- Tests unitaires `AddCareViewModel` + `CareRepository` passing (incluant cas groupé)

### Absent / partiel ⚠️
- **`ServerpodCareRepository`** : absent
- **Rappel réel** : `CareEntry.reminderAt` est calculé et stocké, mais la notification OS n'est pas planifiée (F07)
- **Timeline soins** dans `PuppyFileScreen` : visible mais basée sur le mock — sera mis à jour avec F07

---

## Reste à faire

### Backend (portea_server)
- [ ] Endpoint `care` : `getCareEntries(session, {puppyId?, litterId?})`, `addCareEntry(session, entry)`, `getUpcomingReminders(session, limit)`
- [ ] Validation serveur : `puppyId` / `litterId` appartient au kennel de la session
- [ ] `serverpod generate`

### Data layer
- [ ] `ServerpodCareRepository implements ICareRepository`
- [ ] Swapper dans `main.dart`

### Intégration F07
- [ ] Après `addCareEntry`, si `reminderAt != null` → planifier la notification locale (voir F07)
- [ ] La notification est planifiée/mise à jour à chaque soin enregistré avec rappel

---

## Écrans concernés

| Écran | Fichier | État |
|-------|---------|------|
| Saisie soin | `puppies/presentation/screens/add_care_screen.dart` | ✅ Fait |
| Timeline soins (lecture) | `puppies/presentation/screens/puppy_file_screen.dart` | ✅ Fait |

---

## Modèle CareEntry

```
CareEntry {
  id?: int
  type: String          // 'vaccine' | 'deworming' | 'other'
  product?: String      // Nom du produit
  appliedAt: DateTime   // Date d'application
  puppyId?: int         // null si soin groupé
  litterId?: int        // null si soin individuel
  reminderAt?: DateTime // null si pas de rappel
  notes?: String
}
```

---

## Règles métier

1. Un soin peut cibler **un chiot** (`puppyId`) ou **toute la portée** (`litterId` + une entrée par chiot).
2. Pour un soin groupé : une `CareEntry` parent avec `litterId` (qui portera le `reminderAt` si configuré) + une `CareEntry` enfant par chiot avec `puppyId` (dont le `reminderAt` sera forcé à `null` pour éviter les notifications en doublon). Cela permet de voir le soin dans la timeline de chaque chiot ET d'avoir une seule notification pour toute la portée.
3. `type` : `'vaccine'`, `'deworming'`, `'other'`.
4. Le rappel est optionnel. Si activé : `reminderAt = appliedAt + reminderDays` (uniquement sur la `CareEntry` parent `litterId` pour les soins groupés, ou sur la `CareEntry` individuelle `puppyId` pour les soins individuels).
5. Les soins sont affichés chronologiquement (du plus récent au plus ancien) dans la timeline chiot.

---

## Critères d'acceptation

- [ ] Soin individuel → persisté avec `puppyId` sur Serverpod.
- [ ] Soin groupé → 1 entrée `litterId` + 1 entrée par chiot persistées.
- [ ] Timeline soins du chiot affiche les soins corrects.
- [ ] Si rappel configuré → `reminderAt` persisté correctement.
- [ ] `dart analyze` 0 warning.
- [ ] `flutter test` vert sur `AddCareViewModel` + `CareRepository` tests.
