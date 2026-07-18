# F09 — Documents

## Objectif

Générer **deux** documents légaux PDF pré-remplis depuis les données réelles :

1. **Attestation de cession** (par chiot vendu, status `'sold'`) — émise à la demande, uploadée vers l'object storage Serverpod, listée dans la fiche chiot.
2. **Registre d'élevage** (par élevage, toutes portées) — régénéré à la demande à chaque appel, non archivé.

Fonctionnalité **premium** uniquement.

> La fiche d'accompagnement est **hors scope V1** → voir ROADMAP.md.

---

## État actuel (audit 2026-07-15)

### Fait ✅
- `DocumentsScreen` — liste 3 types de documents avec paywall si non-premium
- Paywall déclenché : non-premium → tap sur document → `/premium`
- Premium : tap sur document → AlertDialog "document généré" (stub)
- Route `/litters/:id/documents`
- `SettingsViewModel.isPremium` accessible dans `DocumentsScreen`

### Absent ❌
- **Package `pdf` / `printing`** : absent du pubspec
- **Génération PDF réelle** : zéro — le dialog est un stub vide
- **Pré-remplissage données** : `DocumentsScreen` ne charge pas les données de la portée, des chiots ni du kennel
- **`DocumentsViewModel`** : absent (la screen utilise directement `SettingsViewModel`)
- **2 types de documents réels** :
  - Attestation de cession : pré-remplie avec infos kennel + chiot + acquéreur — upload vers object storage après génération, liste dans fiche chiot
  - Registre d'élevage DDPP : toutes les portées avec dates + chiots — régénéré à la demande, non archivé
- **Upload object storage** : aucune implémentation Serverpod File Upload côté app
- **Liste documents émis** : absente de `PuppyFileScreen`

---

## Reste à faire

### Packages
- [ ] Ajouter `pdf: ^3.x` et `printing: ^5.x` au pubspec

### DocumentsViewModel
- [ ] Créer `features/settings/presentation/view_models/documents_view_model.dart` :
  - `loadDocumentData(litterId)` : charge `Litter`, ses `Puppy`, leur `Kennel`
  - `generateCessionPdf(Puppy puppy)` → `Future<Uint8List>` (génère + uploade)
  - `generateRegistrePdf()` → `Future<Uint8List>` (génère, partage direct, pas d'archivage)
  - `loadIssuedDocuments(puppyId)` → liste des attestations émises pour un chiot
- [ ] Injection du `DocumentsViewModel` dans `main.dart` (ProxyProvider avec les repositories nécessaires)

### Templates PDF
- [ ] `lib/core/pdf/cession_template.dart` — attestation de cession (conforme formulaire DDPP) :
  - Infos éleveur : `Kennel.ownerName`, `ownerAddress`, `ownerPhone`, `ownerEmail`, `siret`, `affix`
  - Infos animal : `Puppy.name`, `sex`, `color`, `chipNumber`, `birthDate` (via `Litter.birthDate`), `breed` (via mère)
  - Infos acquéreur : `Puppy.buyerName`, `buyerPhone`, `buyerEmail`, `buyerAddress`
  - Date de cession : date du jour à la génération
- [ ] `lib/core/pdf/registre_template.dart` — registre d'élevage DDPP :
  - Liste de toutes les portées avec date mise bas, mère, père, nombre chiots
  - Pour chaque chiot : nom, sexe, statut, date cession si sold, acquéreur

### Serverpod — Object storage (Attestation de cession)
- [ ] Vérifier la disponibilité de Serverpod File Upload / Object Storage v4 (doc : https://docs.serverpod.dev/next)
- [ ] Endpoint `document` côté serveur : `uploadCessionPdf(session, Uint8List bytes, int puppyId)` → retourne l'URL stockée
- [ ] Endpoint `getIssuedDocuments(session, puppyId)` → `List<IssuedDocument>` (modèle à créer : id, puppyId, url, issuedAt)
- [ ] Modèle YAML `IssuedDocument` : `id, puppyId, url, issuedAt`
- [ ] `serverpod generate` + migration DB
- [ ] `IDocumentRepository` + `ServerpodDocumentRepository` dans `features/settings/data/repositories/`

### UI — DocumentsScreen
- [ ] `DocumentsScreen` : `initState` → `loadDocumentData(litterId)`
- [ ] Attestation de cession : bouton par chiot avec statut `'sold'` → génère PDF → upload → affiche snackbar
- [ ] Registre : bouton → génère PDF → `Printing.sharePdf()` (pas d'upload, pas d'archivage)
- [ ] Réduire la liste à 2 entrées (supprimer la 3e "Fiche d'accompagnement")

### UI — PuppyFileScreen
- [ ] Ajouter section "Documents émis" dans `PuppyFileScreen` : liste des attestations uploadées avec date et bouton de téléchargement
- [ ] Afficher uniquement si le chiot a statut `'sold'`

---

## Écrans concernés

| Écran | Fichier | État |
|-------|---------|------|
| Documents | `settings/presentation/screens/documents_screen.dart` | ⚠️ Stub |

---

## Règles métier

1. Toute génération de document est **premium** (paywall si non-premium → `/premium`).
2. **Attestation de cession** :
   - Nécessite `Puppy.status == 'sold'` et infos acquéreur renseignées.
   - Après génération : upload vers object storage Serverpod.
   - URL stockée dans `IssuedDocument` (liée au `puppyId`).
   - Listée dans `PuppyFileScreen` → section "Documents émis".
   - **Pas de versioning, pas de corbeille, pas de partage par lien** (V1).
3. **Registre d'élevage** :
   - Inclut toutes les portées (actives + historique) → premium.
   - Régénéré à chaque demande — non archivé, non versionné.
   - Partagé via `Printing.sharePdf()` (sheet iOS / intent Android).
4. **Fiche d'accompagnement** : hors scope V1 → ROADMAP.md.
5. Les PDFs sont générés **côté client** (package `pdf` Dart). Les données viennent de Serverpod.

---

## Critères d'acceptation

- [x] En gratuit : tap document → paywall (gating `isPremium` client conservé).
- [x] En premium : tap "Attestation de cession" pour un chiot vendu → PDF généré, uploadé sur Serverpod (storage **private**), `IssuedDocument` enregistré. Snackbar de succès **uniquement** après confirmation serveur.
- [x] `PuppyFileScreen` liste les attestations émises pour un chiot `'sold'` (section « Documents émis » + ouverture via endpoint authentifié).
- [x] En premium : tap "Registre d'élevage" → PDF de toutes les portées → partagé via `Printing.sharePdf()`.
- [x] Registre ne crée aucun enregistrement en base (pas d'archivage) — testé.
- [x] `DocumentsScreen` n'affiche que 2 entrées (fiche d'accompagnement retirée).
- [x] Les données PDF viennent de Serverpod (kennel + litter + puppies + mère).
- [x] `dart analyze` 0 warning (serveur + Flutter).
- [x] Validation serveur du dossier cession (status, cessionDate, buyerName, buyerAddress, contact) → `IncompleteCessionDataException` avec champs manquants énumérés.
- [x] Consentement éclairé : `chipNumber` null → dialogue de confirmation avant génération (pas un blocage).
- [x] Fonts Unicode (NotoSans) — les accents français et le tiret long rendent correctement.
- [x] Tests backend : 13/13 (`document_endpoint_test.dart`) + suite complète 109/109.
- [x] Tests Flutter : 167/167 (ViewModel, error_mapper, templates).
