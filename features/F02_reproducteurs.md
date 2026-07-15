# F02 — Reproducteurs

## Objectif

Permettre à l'éleveur de gérer ses reproducteurs (mâles et femelles) : créer, consulter et modifier leur fiche avec photo, identification (puce/tatouage), statut (Actif/Retraité), race, date de naissance.

---

## État actuel (audit 2026-07-15)

### Fait ✅
- `BreedersListScreen` — liste des reproducteurs avec statut badge, sexe, race
- `BreederProfileScreen` — fiche complète : nom, sexe, race, date naissance, puce, tatouage, statut, photo URL
- `BreederListViewModel` + `BreederProfileViewModel` — CRUD complet
- `IBreederRepository` — interface complète : `getBreeders`, `getBreeder`, `createBreeder`, `updateBreeder`
- `MockBreederRepository` — implémentation in-memory fonctionnelle
- Routes `/breeders`, `/breeders/new`, `/breeders/:id`
- Tests unitaires passing (`breeders_test.dart`)

### Absent / partiel ⚠️
- **`ServerpodBreederRepository`** : absent — toutes les données viennent de `MockDatabase.breeders`
- **Upload photo réel** : `photoUrl` est une String, aucun picker/upload implémenté. Le champ existe dans le modèle (`Breeder.photoUrl`).
- **Filtrage par `kennelId`** : `MockBreederRepository` renvoie tous les breeders (pas de filtre kennel). Le modèle `Breeder` a un champ `kennelId` qui devra correspondre au kennel de l'utilisateur connecté côté serveur.

---

## Reste à faire

### Backend (portea_server)
- [ ] Endpoint `breeder` : `getBreeders(session)`, `createBreeder(session, breeder)`, `updateBreeder(session, breeder)`, `getBreeder(session, id)`
- [ ] Filtre serveur : `WHERE kennelId = session.kennel.id` sur tous les endpoints (sécurité)
- [ ] `serverpod generate`

### Data layer
- [ ] `ServerpodBreederRepository implements IBreederRepository`
- [ ] Swapper dans `main.dart`

### Photo upload (optionnel fin de sprint)
- [ ] Ajouter `image_picker` au pubspec
- [ ] Upload via endpoint Serverpod ou stockage externe (à décider — hors scope V1 strict si ça bloque)
- [ ] En attendant : champ `photoUrl` accepte une URL saisie manuellement

---

## Écrans concernés

| Écran | Fichier | État |
|-------|---------|------|
| Liste reproducteurs | `breeders/presentation/screens/breeders_list_screen.dart` | ✅ Fait |
| Profil reproducteur | `breeders/presentation/screens/breeder_profile_screen.dart` | ✅ Fait |

---

## Règles métier

1. Un reproducteur appartient à un et un seul élevage (`kennelId`).
2. Statuts : `'active'` (en activité) | `'retired'` (retraité). Un retraité n'apparaît pas dans les listes de sélection pour la déclaration de portée.
3. La puce (`chipNumber`) et le tatouage (`tattooNumber`) sont optionnels mais au moins un des deux est recommandé.
4. La race (`breed`) est une String libre (pas de liste fermée en V1).
5. Le sexe (`sex`) est figé à la création : `'male'` | `'female'`.

---

## Critères d'acceptation

- [ ] Créer, modifier un reproducteur → données persistées sur Serverpod.
- [ ] Les reproducteurs d'un utilisateur ne sont pas visibles par un autre.
- [ ] Reproducteur `'retired'` → absent des listes de sélection de `LitterDeclarationScreen`.
- [ ] `dart analyze` 0 warning.
- [ ] `flutter test` vert sur `breeders_test.dart`.
