# Memory — Session de cadrage Portea V1

Last updated: 2026-07-15

---

## What was built

Session de **CADRAGE UNIQUEMENT** — aucun code applicatif produit.

Livrables créés :
- `portea_flutter/AGENTS.md` — référentiel agent complet (architecture, règles, stack, routing, workflow, commandes)
- `portea_flutter/features/F01_onboarding.md` — feature file F01 (auth Serverpod, login screen, kennel setup)
- `portea_flutter/features/F02_reproducteurs.md` — feature file F02 (CRUD breeders → Serverpod)
- `portea_flutter/features/F03_portees.md` — feature file F03 (portées, limite freemium → Serverpod)
- `portea_flutter/features/F04_chiots.md` — feature file F04 (batch création chiots → Serverpod)
- `portea_flutter/features/F05_pesees.md` — feature file F05 (pesées + courbe → Serverpod)
- `portea_flutter/features/F06_soins.md` — feature file F06 (soins + rappels → Serverpod)
- `portea_flutter/features/F07_rappels.md` — feature file F07 (flutter_local_notifications réelles)
- `portea_flutter/features/F08_statut_chiot.md` — feature file F08 (statut + acquéreur → Serverpod)
- `portea_flutter/features/F09_documents.md` — feature file F09 (PDF réels, package pdf/printing)
- `portea_flutter/features/F10_premium.md` — feature file F10 (RevenueCat complet + RGPD)
- `portea_flutter/ROADMAP.md` — idées hors scope V1
- `portea_flutter/ui-registry.md` — baseline design system (imprint audit)

---

## Decisions made

### Architecture (non modifiable)
- Clean Architecture + MVVM + Provider. Go_router avec StatefulShellRoute.
- Modèles = uniquement depuis `portea_client` (généré Serverpod). INTERDIT : classes modèles côté app.
- DI centralisée dans `main.dart` via `MultiProvider` + `ChangeNotifierProxyProvider`.

### Bascule Mock → Serverpod
- Complète en V1, **feature par feature** (F01 en premier, débloque le kennelId réel).
- Ordre imposé par la dépendance : F01 (auth + kennel) → F02-F08 → F09-F10.
- `MockXxxRepository` reste pour les tests uniquement.

### Auth (F01)
- Login Serverpod emailIdp réel.
- Flux : Welcome → Login → Kennel Setup → Notifications → Dashboard.
- Session existante → Dashboard direct (redirect go_router).
- Google + Apple Sign-In si config console disponible (email d'abord).
- `lib/screens/sign_in_screen.dart` → migrer en `features/onboarding/presentation/screens/sign_in_screen.dart`. Supprimer `lib/screens/` à la fin de F01.
- Package `flutter_local_notifications` ajouté dès F01 pour pouvoir appeler la vraie méthode de demande de permission OS.

### kennelId
- JAMAIS passé en paramètre client.
- Serveur dérive le kennel depuis `session`.
- 1 user = 1 kennel (contrainte unique), modélisé user→kennel (pas fusion).
- `kennelId` résolu au login → stocké en `SharedPreferences` (cache affichage, pas autorisation).

### Portées (F03)
- Gratuit : 1 seule portée active à la fois.
- Premium : portées actives illimitées (plusieurs portées actives peuvent coexister simultanément). Clôture manuelle ou automatique lorsque tous les chiots sont vendus.

### RevenueCat (F10)
- SDK `purchases_flutter` complet en V1.
- Sandbox pendant le build.
- Webhook RevenueCat → endpoint Serverpod → `Kennel.premiumUntil: DateTime?` (jamais de bool).
- `appUserID` = ID utilisateur Serverpod.
- Prix depuis offerings RevenueCat (jamais hardcodés).

### Notifications (F07)
- `flutter_local_notifications` réelles (ajouté au pubspec en F01).
- Replanification au démarrage de l'app (survie reboot device).
- Deep-link conditionnel : `/puppies/:id` (soin individuel) ou `/litters/:id` (soin de portée) selon le type de soin.
- **Rappels groupés (F06 + F07)** : pour un soin de portée, seule la `CareEntry` parent avec `litterId` porte le `reminderAt` (les entrées par chiot ont `reminderAt = null`), évitant les doublons.
- **Pas d'annulation croisée** : `cancelReminder` n'est appelé que si la `CareEntry` elle-même est modifiée/supprimée.

### PDF (F09)
- Package `pdf` + `printing`. Génération côté client.
- 2 documents en V1 : Attestation de cession (générée + uploadée vers Serverpod Object Storage, listée dans la fiche chiot, pas de versioning/corbeille/partage par lien) et Registre d'élevage (généré à la demande à chaque appel, non archivé).
- Fiche d'accompagnement : hors scope V1 → ROADMAP.md.

### Species & Statut (F08/Kennel)
- 1 espèce par élevage, choisie à l'onboarding, non modifiable en V1.
- Libellés adaptatifs (chiot/chaton).
- Support multi-espèces dans un même élevage → ROADMAP.md.
- Statut `'available'` : les informations acquéreur sont conservées en base mais masquées dans l'interface pour éviter la perte de données si la réservation est annulée puis reprise.

---

## Problems solved

- Audit complet F01-F10 : état réel identifié (fait/partiel/absent) depuis le code source.
- Grill 8 questions validé : toutes les zones floues levées.
- `kennelId: 1` hardcodé identifié dans `LitterDeclarationViewModel` et `MockDatabase` → à corriger en F01/F03.
- `lib/screens/` : dossier orphelin identifié → à supprimer en F01.
- Hardcoded color `Color(0xFFC4664A)` dans `OnboardingWelcomeScreen` → à remplacer par `AppColors.primary` en F01.

---

## Current state

- **Code applicatif** : aucun changement. Tout est encore sur Mock.
- **Livrables cadrage** : écrits et validés.
- **Tests existants** : 9 tests onboarding + tests litters/breeders/puppies/weighing/care — tous en mock, tous passants.
- **Serverpod** : client instancié dans main.dart, auth endpoints (emailIdp + jwtRefresh) générés, **zéro endpoint métier** côté serveur.

---

## Next session starts with

**F01 — Onboarding + Auth Serverpod**

Étapes dans l'ordre :
1. Lire `features/F01_onboarding.md`
2. Charger skills : `flutter-technical` + `flutter-apply-architecture-best-practices`
3. Consulter doc Serverpod v4 auth : https://docs.serverpod.dev/next/concepts/authentication/get-started
4. Backend : vérifier/créer endpoint `kennel` dans `portea_server` (getMyKennel, createKennel, updateKennel — session-based)
5. `serverpod generate`
6. Créer `ServerpodKennelRepository`
7. Migrer `sign_in_screen.dart` → `features/onboarding/presentation/screens/`
8. Intégrer le flux login dans le router (Welcome → Login → Setup → Notifications → Dashboard)
9. Supprimer `lib/screens/` + corriger `Color(0xFFC4664A)` hardcodé

---

## Open questions

- Aucune : toutes les décisions sont prises. Voir feature files pour les critères d'acceptation précis.
