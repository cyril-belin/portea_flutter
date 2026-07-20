# Portea

Application mobile de gestion d'élevage pour éleveurs familiaux de chiens et
de chats. Portea centralise le suivi des portées, des reproducteurs, de la
croissance et des soins, ainsi que la production des documents légaux liés
à la cession d'un animal (attestation, certificat). Le modèle économique
est freemium : les fonctionnalités de base sont gratuites, l'édition de
documents et les options avancées relèvent d'un abonnement.

Ce dépôt contient le client Flutter. Le backend Serverpod et le client
généré vivent dans des dépôts séparés (voir *Topologie* ci-dessous).

---

## Stack

- **Flutter** 3.38 (Dart 3.10), **Clean Architecture** + pattern **MVVM**,
  injection de dépendances et état via **Provider**.
- **go_router** pour le routage déclaratif (redirection d'onboarding,
  navigation par onglets via `ShellRoute`).
- **flutter_local_notifications** + **flutter_timezone** : rappels de soins
  via notifications locales OS (iOS + Android), replanifiés à chaque démarrage.
- **pdf** + **printing** : génération et partage des documents légaux F09
  (attestation de cession, registre d'élevage). Font Unicode NotoSans bundlée
  pour le rendu correct des accents français.
- **purchases_flutter 8.11.0** : SDK RevenueCat côté client. L'app déclenche
  l'achat et la restauration, mais **le serveur reste l'autorité** du statut
  premium (F10-A) — il interroge l'API REST RevenueCat au moyen d'une clé
  secrète jamais embarquée dans le client, et persiste
  `Kennel.premiumUntil`. Le client ne fait que déclencher la synchronisation.
- **share_plus 12.x** : export RGPD des données de l'élevage (F10-B) au format
  JSON via le share sheet OS.
- **Serverpod 4.0.0-beta** : backend en Dart, PostgreSQL,
  authentification intégrée (email), WebSocket typés.

### Topologie

Le projet est un **monorepo en 3 morceaux**, chacun étant un dépôt git
autonome :

| Dépôt            | Rôle                                               |
|------------------|----------------------------------------------------|
| `portea_flutter` | Application Flutter (ce dépôt)                     |
| `portea_server`  | Backend Serverpod, endpoints, modèles, migrations  |
| `portea_client`  | Code client généré, partagé entre les deux         |

> ⚠️ **Ce dépôt ne se clone pas seul.** Un clone sain nécessite les 3 morceaux
> côte à côte sous un **dépôt git parapluie** qui versionne `portea_client/`
> (le client généré) et le `pubspec.yaml` de workspace (résolution
> `workspace:` + `dependency_overrides: win32 ^6.0.0` pour réconcilier le pin
> `win32 ^6` de Serverpod et le pin transitif `win32 ^5` de `share_plus`).
> Sans le parapluie, `portea_flutter pub get` ne résout pas `portea_client` et
> l'app ne compile pas. Voir le `README.md` de la racine du parapluie pour la
> procédure de clonage exacte.

---

## État d'avancement

Le périmètre V1 est découpé en 10 fonctionnalités, spécifiées dans
`features/`. Chaque fonctionnalité est développée feature par feature :
UI puis branchement au backend Serverpod.

| Fonctionnalité                      | Statut              |
|-------------------------------------|---------------------|
| F01 — Onboarding (auth + élevage)   | Backend Serverpod   |
| F02 — Reproducteurs                 | Backend Serverpod   |
| F03 — Portées (limite freemium)     | Backend Serverpod   |
| F04 — Chiots                        | Backend Serverpod   |
| F05 — Pesées                        | Backend Serverpod   |
| F06 — Soins                         | Backend Serverpod   |
| F07 — Rappels (notifications)       | Développé           |
| F08 — Statut chiot                  | Développé           |
| F09 — Documents                     | Développé           |
| F10-A — Premium (RevenueCat)        | Développé           |
| F10-B — RGPD (suppression + export) | Développé           |

**La V1 est code-complete** : les 10 fonctionnalités du périmètre sont
développées et branchées au backend Serverpod. Les données persistent dans
PostgreSQL ; le kennel est dérivé de la session (isolation par utilisateur,
anti-forging du `kennelId`). Il ne reste que des étapes de mise en production
(voir *Restants connus* ci-dessous).

> F10-A (Premium RevenueCat) : l'app déclenche l'achat et la restauration via
> `purchases_flutter`, puis appelle `syncPremiumStatus` pour que le serveur
> interroge RevenueCat (clé secrète serveur) et persiste `Kennel.premiumUntil`.
> Le client **n'est jamais l'autorité** du statut premium — il demande au
> serveur de resynchroniser et lit le résultat via `isPremium`. Un échec API
> ne rétrograde jamais un utilisateur payant : `premiumUntil` est préservé
> tant que la prochaine synchro n'a pas réussi.

> F10-B (RGPD) : suppression de compte à double confirmation (dialogue
> d'irréversibilité puis saisie d'un mot de confirmation) et export des
> données au format JSON via share sheet (`share_plus`). La suppression est
> transactionnelle côté serveur et annule toutes les notifications locales +
> nettoie les `SharedPreferences` + déconnecte avant tout message de succès.
> L'export ne contient aucune donnée d'un autre élevage. Aucun message de
> succès n'est affiché avant confirmation réelle du serveur (les anciens stubs
> « Compte supprimé » et « Données exportées » ont été supprimés).

> F06 (soins) a corrigé un bug de l'audit externe (claim 4.3) : le soin groupé
> crée désormais **une seule entrée parent** portant le rappel, et une entrée
> par chiot avec rappel forcé à `null` — pour éviter de planifier N
> notifications identiques quand F07 gérera les rappels.

> F07 (rappels) repose sur des **notifications locales OS** (`flutter_local_notifications`
> + `flutter_timezone`) : aucune infrastructure push. La date de rappel est
> persistée côté serveur via `CareEntry.reminderAt` (F06) ; la planification OS
> se fait côté Flutter après chaque enregistrement de soin, et toutes les
> notifications futures sont **replanifiées au démarrage** après login (survie au
> reboot device). Le `NotificationService` est injecté via `Provider` et ne fait
> aucun accès base de données : la résolution du nom de la cible (titre de la
> notification) se fait dans le contexte appelant. Deep-link au tap :
> `/puppies/<id>` (soin individuel) ou `/litters/<id>` (soin de portée).

> F08 (statut chiot) branche la fiche chiot sur le backend pour le changement de
> statut (`available`/`reserved`/`sold`) et le dossier acquéreur (nom, téléphone,
> e-mail, adresse). La **règle de conservation** tient : un retour à `available`
> n'efface **jamais** le dossier acquéreur ni la `cessionDate` — ces données
> restent en base et sont simplement masquées en UI (la section acquéreur ne
> s'affiche qu'en `reserved`/`sold`). Le cycle annulation/reprise du terrain
> fonctionne : re-vendre sans ressaisir le dossier conserve le téléphone, l'e-mail
> et l'adresse saisis précédemment. Côté serveur, `updatePuppyStatus` est la seule
> surface d'écriture du statut et de l'acquéreur ; `savePuppiesBatch` ne touche
> plus qu'à l'identité du chiot. Validations UI (e-mail / téléphone) en amont,
> le serveur reste l'autorité.

> F09 prérequis (données d'attestation) rend saisissables et persistées les deux
> catégories de données que la génération de l'attestation de cession exigera :
> - **Informations éleveur** (nouvelle section « Informations éleveur » des
>   réglages) : nom, adresse, téléphone, e-mail, SIRET. Sauvegardées via le
>   nouvel endpoint dédié `updateKennelOwnerInfo` (validations e-mail + SIRET
>   14 chiffres, sémantique remplacement — un champ vidé est effacé, pas
>   préservé). Tous optionnels à la saisie : l'exigence de complétude tombe à
>   la génération (F09), pas ici.
> - **Numéro de puce du chiot** (I-CAD) : champ éditable dans la fiche chiot
>   (section « Identification »), sauvegardé via `savePuppiesBatch` — la
>   surface d'identité du chiot, jamais via `updatePuppyStatus` (qui reste
>   statut + acquéreur + cessionDate). La puce est implantée des semaines
>   après la naissance, d'où l'édition dans la fiche plutôt qu'à la création
>   de portée.
>
> Correctif de mock inclus : `MockPuppyRepository.savePuppiesBatch` reconstruisait
> le `Puppy` sur update sans `cessionDate`, le perdait — une divergence latente
> avec le contrat identity-only du serveur, verrouillée par un nouveau test.

> F09 (documents) génère deux PDF légaux pré-remplis depuis les données réelles :
> - **Attestation de cession** (par chiot `sold`) : générée côté client (package
>   `pdf`), téléversée vers le storage **private** Serverpod, enregistrée comme
>   `IssuedDocument`. Le snack de succès ne s'affiche **qu'après** confirmation
>   serveur (mort du stub AlertDialog « PDF généré » — verdict 2.2). Si le
>   dossier est incomplet (statut ≠ `sold`, `cessionDate` manquante, acquéreur
>   incomplet), le serveur refuse avec une `IncompleteCessionDataException` dont
>   le message **énumère** les champs manquants. Date de cession =
>   `puppy.cessionDate` (jamais `DateTime.now()` — doc légal). Si `chipNumber`
>   est null, un dialogue de **consentement éclairé** précise que l'attestation
>   portera « Non renseigné » avant de générer (pas un blocage).
> - **Registre d'élevage** (par élevage, toutes portées) : généré et partagé via
>   `Printing.sharePdf()` à chaque appel. **Aucun upload, aucun enregistrement**
>   — la surface serveur est exclusivement l'attestation.
>
> La lecture d'une attestation archivée passe par un endpoint **authentifié**
> (`downloadCessionPdf`) : le storage étant private, aucune URL publique ne fuit
> (anti-forge re-vérifié sur le `documentId` via le puppy). Font Unicode NotoSans
> bundlée — la font par défaut (Helvetica) droupe les accents français, ce qui
> est inacceptable sur un document légal.

---

## Setup développeur

### Prérequis

- **Flutter SDK** 3.38+
- **Serverpod CLI** (`dart pub global activate serverpod_cli`)

> `serverpod start` embarque et lance un PostgreSQL dédié (data sous
> `portea_server/.serverpod/`) : aucun Docker externe requis en développement.

### Installation

```bash
# Configuration de l'application
cp assets/config.example.json assets/config.json
# Éditer assets/config.json : apiUrl du backend Serverpod

# Dépendances — depuis la racine du parapluie (workspace), PAS depuis
# portea_flutter/ seul : la résolution workspace et l'override win32 y vivent.
flutter pub get
```

### Lancement

```bash
# Démarre le backend Serverpod (PostgreSQL embarqué) + l'app Flutter
# avec hot reload sur les deux. À lancer depuis la racine du parapluie.
serverpod start
```

Alternative pour le frontend seul :

```bash
flutter run
```

### Tests

```bash
# Frontend : depuis portea_flutter/
flutter test

# Backend : depuis portea_server/, en SÉQUENTIEL (dette de harnais parallèle)
dart test -j 1
```

---

## Restants connus (post-V1, code-complete)

La V1 est code-complete. Reste à mettre en production :

- **Configuration RevenueCat stores** : `purchases_flutter` est intégré mais
  les configurations App Store Connect / Google Play (produits, entitlements,
  clés partagées) et le secret RevenueCat côté serveur (`revenueCatSecretApiKey`
  dans `portea_server/config/passwords.yaml`) ne sont pas encore positionnés en
  production.
- **Déploiement VPS + webhook RevenueCat** : déploiement du serveur en
  production et branchement optionnel d'un webhook RevenueCat pour
  synchroniser `premiumUntil` sans dépendre uniquement des déclenchements
  client (la synchro client existe déjà ; le webhook fiabiliserait les
  remboursements / annulations hors app).

---

## Captures d'écran

| | | |
|:---:|:---:|:---:|
| ![Welcome](doc/screenshots/01_welcome.png) | ![Dashboard](doc/screenshots/05_dashboard.png) | ![Reproducteurs](doc/screenshots/06_breeders_list.png) |
| ![Portée](doc/screenshots/09_litter_detail.png) | ![Pesée de groupe](doc/screenshots/11_group_weighing.png) | ![Fiche chiot](doc/screenshots/12_puppy_file.png) |

---

## Méthode

Développement assisté par IA, feature par feature. Les spécifications de
chaque fonctionnalité vivent dans `features/`.
