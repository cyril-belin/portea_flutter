# Portea

Application mobile de gestion d'élevage pour éleveurs familiaux de chiens et
de chats. Portea centralise le suivi des portées, des reproducteurs, de la
croissance et des soins, ainsi que la production des documents légaux liés
à la cession d'un animal (attestation, certificat). Le modèle économique
est freemium : les fonctionnalités de base sont gratuites, l'édition de
documents et les options avancées relèvent d'un abonnement.

Ce dépôt contient le client Flutter. Le backend Serverpod et le client
généré vivent dans des dépôts séparés (voir *Monorepo* ci-dessous).

---

## Stack

- **Flutter** 3.38 (Dart 3.10), **Clean Architecture** + pattern **MVVM**,
  injection de dépendances et état via **Provider**.
- **go_router** pour le routage déclaratif (redirection d'onboarding,
  navigation par onglets via `ShellRoute`).
- **flutter_local_notifications** + **flutter_timezone** : rappels de soins
  via notifications locales OS (iOS + Android), replanifiés à chaque démarrage.
- **Serverpod 4.0.0-beta** : backend en Dart, PostgreSQL,
  authentification intégrée (email), WebSocket typés.
- **RevenueCat** : prévu pour la gestion d'abonnement (non intégré à ce
  stade).

### Monorepo

Le projet est organisé en trois packages :

| Dépôt            | Rôle                                               |
|------------------|----------------------------------------------------|
| `portea_flutter` | Application Flutter (ce dépôt)                     |
| `portea_server`  | Backend Serverpod, endpoints, modèles, migrations  |
| `portea_client`  | Code client généré, partagé entre les deux         |

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
| F09 — Documents                     | Prérequis développé |
| F10 — Premium (RevenueCat + RGPD)   | UI faite, mock      |

Les fonctionnalités branchées au backend Serverpod (F01–F08) persistent les
données dans PostgreSQL ; le kennel est dérivé de la session (isolation par
utilisateur, anti-forging du `kennelId`). La ligne F09 « Prérequis développé »
désigne les **données** exigées par l'attestation de cession (infos éleveur +
numéro de puce du chiot) : elles sont saisissables et persistées en base, mais
la **génération** du document reste à faire (mock). Les fonctionnalités
« UI faite, mock » s'appuient sur un `MockDatabase` en mémoire : l'interface est
navigable, les données ne sont pas persistées.

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

# Dépendances
flutter pub get
```

### Lancement

```bash
# Démarre le backend Serverpod (PostgreSQL embarqué) + l'app Flutter
# avec hot reload sur les deux. À lancer depuis la racine du monorepo.
serverpod start
```

Alternative pour le frontend seul :

```bash
flutter run
```

### Tests

```bash
flutter test
```

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
