# F03 — Portées

## Objectif

Permettre à l'éleveur de déclarer une nouvelle portée (mère, père interne ou saillie externe, date de mise bas), de consulter la portée active et l'historique, avec la limitation freemium : 1 portée active max en gratuit.

---

## État actuel (audit 2026-07-15)

### Fait ✅
- `LittersHistoryScreen` — affiche portée active + liste des portées passées (verrouillées en gratuit)
- `LitterDeclarationScreen` — formulaire complet : sélection mère (femelles actives), père interne (mâles actifs) OU saillie externe (`externalSireName`, `externalSireId`), date de mise bas
- `LitterDetailScreen` — détail d'une portée : infos, liste chiots, accès pesées/soins/documents
- `LittersViewModel` — `loadLitters()`, distinction active/passées, `isPremium`
- `LitterDeclarationViewModel` — `loadBreedersForDeclaration()`, `declareLitter()`
- `LitterDetailViewModel` — chargement portée + chiots + reproducteurs
- `ILitterRepository` — interface complète
- `MockLitterRepository` — in-memory fonctionnel
- Paywall déclenché : tentative de voir l'historique en gratuit → `/premium`
- 8 tests unitaires passing (`litters_test.dart`)

### Absent / partiel ⚠️
- **`ServerpodLitterRepository`** : absent
- **`kennelId: 1` hardcodé** dans `LitterDeclarationViewModel.declareLitter()` — doit utiliser le vrai kennelId de la session
- **Limite 1 portée active** : en gratuit, l'éleveur est limité à 1 portée active maximum. La validation doit se faire côté serveur.
- **Paywall 2e portée** : le déclencheur existe dans `LittersHistoryScreen` mais la vérification est basée sur le bool `isPremium` du mock.

---

## Reste à faire

### Backend (portea_server)
- [ ] Endpoint `litter` : `getLitters(session)`, `getActiveLitter(session)`, `getLitter(session, id)`, `createLitter(session, litter)`, `updateLitter(session, litter)`
- [ ] Règle serveur : si non-premium et déjà 1 portée active → retourner une erreur métier (pas bloquer via kennelId)
- [ ] Tous les endpoints filtrent par `kennel.id` dérivé de la session
- [ ] `serverpod generate`

### Data layer
- [ ] `ServerpodLitterRepository implements ILitterRepository`
- [ ] Swapper dans `main.dart`
- [ ] Supprimer le `kennelId: 1` hardcodé → utiliser le kennelId résolu au login

### Logic
- [ ] `LitterDeclarationViewModel` : lire le `kennelId` depuis un provider ou SharedPreferences (résolu au login via F01)
- [ ] Gérer l'erreur serveur "portée active déjà existante" (utilisateur gratuit)

---

## Écrans concernés

| Écran | Fichier | État |
|-------|---------|------|
| Historique portées | `litters/presentation/screens/litters_history_screen.dart` | ✅ Fait |
| Déclaration portée | `litters/presentation/screens/litter_declaration_screen.dart` | ✅ Fait |
| Détail portée | `litters/presentation/screens/litter_detail_screen.dart` | ✅ Fait |

---

## Règles métier

1. **Gratuit** : 1 seule portée active à la fois. Tentative de créer une 2e → paywall `/premium`.
2. **Premium** : portées actives illimitées (plusieurs portées actives peuvent coexister simultanément, par ex. deux femelles mettant bas à quelques semaines d'écart), historique accessible.
3. La clôture d'une portée (passage de `isActive` à `false`) est une action manuelle par l'éleveur (ou automatique lorsque tous les chiots de la portée sont vendus). La déclaration d'une nouvelle portée en Premium ne désactive jamais automatiquement la portée précédente. En gratuit, si une portée active existe déjà, la création d'une nouvelle est bloquée.
4. La mère doit être un `Breeder` de sexe `'female'` et statut `'active'`.
5. Le père peut être : un `Breeder` de sexe `'male'` et statut `'active'` (interne) OU une saillie externe (champs `externalSireName` / `externalSireId` libres).
6. `kennelId` est dérivé de la session côté serveur — jamais passé par le client.
7. Le modèle `Litter` doit conserver `isActive: bool` pour la distinction actif/historique.

---

## Critères d'acceptation

- [ ] Déclarer une portée → persistée sur Serverpod.
- [ ] En gratuit : 2e tentative de déclaration → paywall.
- [ ] En premium : historique complet visible.
- [ ] Père interne et saillie externe fonctionnent tous les deux.
- [ ] `kennelId` hardcodé à 1 → supprimé.
- [ ] `dart analyze` 0 warning.
- [ ] `flutter test` vert sur `litters_test.dart`.
