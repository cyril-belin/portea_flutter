# F08 — Statut chiot

## Objectif

Permettre à l'éleveur de mettre à jour le statut d'un chiot (disponible, réservé, vendu) et de saisir les informations de l'acquéreur (nom, téléphone, email, adresse).

---

## État actuel (audit 2026-07-15)

### Fait ✅
- `PuppyFileScreen` — section statut avec 3 options (disponible/réservé/vendu), section acquéreur avec formulaire (nom, tel, email, adresse)
- `PuppyFileViewModel.updateStatus()` — met à jour `Puppy.status` + appelle `updatePuppy()`
- `PuppyFileViewModel.saveBuyerInfo()` — met à jour `buyerName`, `buyerPhone`, `buyerEmail`, `buyerAddress` + appelle `updatePuppy()`
- `StatusBadgeWidget` — widget partagé affichant le badge coloré (available=vert, reserved=orange, sold=gris)
- `IPuppyRepository.updatePuppy()` — interface présente
- `MockPuppyRepository` — in-memory fonctionnel
- Tests unitaires `PuppyFileViewModel` passing (updateStatus + saveBuyerInfo)

### Absent / partiel ⚠️
- **`ServerpodPuppyRepository`** : absent (partagé avec F04 — même repository)
- **Validation email/téléphone** : champs libres, aucune validation de format
- **Statut "vendu" + infos acquéreur** : pré-remplissage du formulaire acquéreur présent dans l'UI (`initState` charge `buyerName` etc.) mais les données viennent du mock

---

## Reste à faire

### Backend (portea_server)
- Partagé avec F04 — le même endpoint `puppy` couvre `updatePuppy`
- [ ] Valider que `updatePuppy` filtre bien par kennel de session côté serveur

### Data layer
- [ ] `ServerpodPuppyRepository` (partagé F04/F08) — `updatePuppy` doit envoyer tous les champs modifiés
- [ ] Swapper dans `main.dart` (une seule fois, F04 ou F08)

### UI
- [ ] Validation email basique (format) et téléphone (longueur) — côté UI avec `FormField.validator`
- [ ] Confirmations visuelles (SnackBar) après changement de statut ou sauvegarde acquéreur

---

## Écrans concernés

| Écran | Fichier | État |
|-------|---------|------|
| Fiche chiot | `puppies/presentation/screens/puppy_file_screen.dart` | ✅ Fait |

---

## Modèle Puppy (champs F08)

```
Puppy {
  status: String        // 'available' | 'reserved' | 'sold'
  buyerName?: String
  buyerPhone?: String
  buyerEmail?: String
  buyerAddress?: String
}
```

---

## Règles métier

1. Statuts : `'available'` (disponible), `'reserved'` (réservé), `'sold'` (vendu).
2. Statut `'sold'` → les infos acquéreur sont requises pour l'attestation de cession (F09).
3. Statut `'available'` → les informations acquéreur précédemment saisies sont conservées en base (pour éviter toute perte de données si une réservation est annulée puis reprise), mais elles sont masquées dans l'interface utilisateur. Elles ne s'affichent et ne se modifient que si le statut est `'reserved'` ou `'sold'`.
4. La mise à jour du statut ne crée pas de nouvelle entité — elle modifie l'objet `Puppy` existant.
5. Les infos acquéreur sont pré-remplies dans `DocumentsScreen` (F09) pour l'attestation de cession.

---

## Critères d'acceptation

- [ ] Changement de statut → persisté sur Serverpod.
- [ ] Infos acquéreur → persistées sur Serverpod.
- [ ] `StatusBadgeWidget` affiche la bonne couleur selon le statut.
- [ ] Pré-remplissage du formulaire acquéreur au chargement de la fiche.
- [ ] `dart analyze` 0 warning.
- [ ] `flutter test` vert sur `PuppyFileViewModel` (updateStatus + saveBuyerInfo).
