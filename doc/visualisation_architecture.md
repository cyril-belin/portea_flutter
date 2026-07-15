# Visualisation Technique — Portea Flutter

Ce document présente une cartographie complète et structurée de l'application **Portea Flutter**, basée sur l'audit statique et l'analyse de dépendances réalisée via l'outil `graphify` sur le codebase.

---

## 1. Architecture en couches par Feature

L'application respecte une **Clean Architecture en 3 couches** combinée avec le pattern de présentation **MVVM (Model-View-ViewModel)**. 

### Structure des 3 couches :
1. **Presentation** : Contient les Screens UI (Flutter Widgets) et les ViewModels (`ChangeNotifier`). Les ViewModels consomment les interfaces du Domain et notifient l'UI en cas de changement.
2. **Domain** : Contient la logique métier pure et les définitions d'interfaces de dépôt (`IXxxRepository`). *Note : Conformément aux règles absolues du projet, il n'y a pas de classes modèles côté app ; les entités de données proviennent exclusivement du client Serverpod généré.*
3. **Data** : Contient les implémentations des dépôts. Actuellement, toutes les implémentations actives sont des mocks (`MockXxxRepository`) s'interfaçant avec une base de données en mémoire locale (`MockDatabase`). À terme, elles seront remplacées par des implémentations Serverpod (`ServerpodXxxRepository`).

```mermaid
graph TD
    %% Couches
    subgraph Presentation ["Couche Présentation (Presentation)"]
        UI["Screens & Widgets UI"]
        VM["ViewModels - ChangeNotifier"]
    end
    
    subgraph Domain ["Couche Domaine (Domain)"]
        RepoInterface["Interfaces - IXxxRepository"]
    end
    
    subgraph Data ["Couche Données (Data)"]
        MockRepo["Implémentations Mocks"]
        ServerpodRepo["Implémentations Serverpod (Futur)"]
    end
    
    %% Relations
    UI -->|Événements utilisateur & Lectures| VM
    VM -->|Appelle les méthodes de| RepoInterface
    MockRepo -.->|Implémente| RepoInterface
    ServerpodRepo -.->|Implémente| RepoInterface
    
    classDef pres fill:#e3f2fd,stroke:#1e88e5,stroke-width:2px;
    classDef dom fill:#f1f8e9,stroke:#7cb342,stroke-width:2px;
    classDef dat fill:#fff8e1,stroke:#ffb300,stroke-width:2px;
    
    class UI,VM pres;
    class RepoInterface dom;
    class MockRepo,ServerpodRepo dat;
```

### Répartition par Feature

| Feature | Composants Présentation (UI & VM) | Interfaces Domaine | Implémentations Data (Actuel) |
| :--- | :--- | :--- | :--- |
| **F01 — Onboarding** | [OnboardingWelcomeScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/onboarding/presentation/screens/onboarding_welcome_screen.dart)<br>[SignInScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/onboarding/presentation/screens/sign_in_screen.dart) *(à migrer)*<br>[KennelSetupScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/onboarding/presentation/screens/kennel_setup_screen.dart)<br>[OnboardingNotificationsScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/onboarding/presentation/screens/onboarding_notifications_screen.dart)<br>[OnboardingViewModel](file:///Users/cyril/dev/portea/portea_flutter/lib/features/onboarding/presentation/view_models/onboarding_view_model.dart) | [IKennelRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/onboarding/domain/repositories/i_kennel_repository.dart) | [MockKennelRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/onboarding/data/repositories/mock_kennel_repository.dart) |
| **F02 — Reproducteurs** | [BreedersListScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/breeders/presentation/screens/breeders_list_screen.dart)<br>[BreederProfileScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/breeders/presentation/screens/breeder_profile_screen.dart)<br>[BreederListViewModel](file:///Users/cyril/dev/portea/portea_flutter/lib/features/breeders/presentation/view_models/breeder_list_view_model.dart)<br>[BreederProfileViewModel](file:///Users/cyril/dev/portea/portea_flutter/lib/features/breeders/presentation/view_models/breeder_profile_view_model.dart) | [IBreederRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/breeders/domain/repositories/i_breeder_repository.dart) | [MockBreederRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/breeders/data/repositories/mock_breeder_repository.dart) |
| **F03 — Portées** | [LittersHistoryScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/litters/presentation/screens/litters_history_screen.dart)<br>[LitterDeclarationScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/litters/presentation/screens/litter_declaration_screen.dart)<br>[LitterDetailScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/litters/presentation/screens/litter_detail_screen.dart)<br>[LittersViewModel](file:///Users/cyril/dev/portea/portea_flutter/lib/features/litters/presentation/view_models/litters_view_model.dart)<br>[LitterDeclarationViewModel](file:///Users/cyril/dev/portea/portea_flutter/lib/features/litters/presentation/view_models/litter_declaration_view_model.dart)<br>[LitterDetailViewModel](file:///Users/cyril/dev/portea/portea_flutter/lib/features/litters/presentation/view_models/litter_detail_view_model.dart) | [ILitterRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/litters/domain/repositories/i_litter_repository.dart) | [MockLitterRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/litters/data/repositories/mock_litter_repository.dart) |
| **F04 à F08 — Chiots, Pesées & Soins** | [PuppyBatchCreationScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/presentation/screens/puppy_batch_creation_screen.dart)<br>[GroupWeighingScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/presentation/screens/group_weighing_screen.dart)<br>[PuppyFileScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/presentation/screens/puppy_file_screen.dart)<br>[AddCareScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/presentation/screens/add_care_screen.dart)<br>[PuppyBatchViewModel](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/presentation/view_models/puppy_batch_view_model.dart)<br>[GroupWeighingViewModel](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/presentation/view_models/group_weighing_view_model.dart)<br>[PuppyFileViewModel](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/presentation/view_models/puppy_file_view_model.dart)<br>[AddCareViewModel](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/presentation/view_models/add_care_view_model.dart) | [IPuppyRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/domain/repositories/i_puppy_repository.dart)<br>[IWeighingRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/domain/repositories/i_weighing_repository.dart)<br>[ICareRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/domain/repositories/i_care_repository.dart) | [MockPuppyRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/data/repositories/mock_puppy_repository.dart)<br>[MockWeighingRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/data/repositories/mock_weighing_repository.dart)<br>[MockCareRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/puppies/data/repositories/mock_care_repository.dart) |
| **Dashboard** | [DashboardScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/dashboard/presentation/screens/dashboard_screen.dart)<br>[DashboardViewModel](file:///Users/cyril/dev/portea/portea_flutter/lib/features/dashboard/presentation/view_models/dashboard_view_model.dart) | *Pas de dépôt dédié* (consomme les autres interfaces) | *Pas de dépôt dédié* |
| **Settings & Premium (F09-F10)** | [SettingsScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/settings/presentation/screens/settings_screen.dart)<br>[DocumentsScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/settings/presentation/screens/documents_screen.dart)<br>[PorteaPremiumScreen](file:///Users/cyril/dev/portea/portea_flutter/lib/features/settings/presentation/screens/portea_premium_screen.dart)<br>[SettingsViewModel](file:///Users/cyril/dev/portea/portea_flutter/lib/features/settings/presentation/view_models/settings_view_model.dart) | [ISettingsRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/settings/domain/repositories/i_settings_repository.dart) | [MockSettingsRepository](file:///Users/cyril/dev/portea/portea_flutter/lib/features/settings/data/repositories/mock_settings_repository.dart) |

---

## 2. Graphe d'Injection de Dépendances (main.dart)

La résolution des dépendances de l'application est centralisée dans [main.dart](file:///Users/cyril/dev/portea/portea_flutter/lib/main.dart).
Elle utilise une structure de providers imbriqués (`MultiProvider`) organisée en deux étapes majeures :
1. **Enregistrement des Dépôts** (comme interfaces Domain via `Provider<IXxxRepository>.value`)
2. **Enregistrement des ViewModels** (via `ChangeNotifierProvider` pour l'onboarding et `ChangeNotifierProxyProvider` pour ceux qui dépendent des dépôts).

Voici le graphe d'injection actuel :

```mermaid
graph TD
    %% Instanciation brute
    subgraph Mocks ["Mocks Instanciés au démarrage"]
        M_Ken["MockKennelRepository"]
        M_Brd["MockBreederRepository"]
        M_Lit["MockLitterRepository"]
        M_Pup["MockPuppyRepository"]
        M_Wgh["MockWeighingRepository"]
        M_Car["MockCareRepository"]
        M_Set["MockSettingsRepository"]
    end

    %% Providers de Repositories
    subgraph RepoProviders ["Providers d'interfaces (Domain)"]
        P_Ken["Provider<IKennelRepository>"]
        P_Brd["Provider<IBreederRepository>"]
        P_Lit["Provider<ILitterRepository>"]
        P_Pup["Provider<IPuppyRepository>"]
        P_Wgh["Provider<IWeighingRepository>"]
        P_Car["Provider<ICareRepository>"]
        P_Set["Provider<ISettingsRepository>"]
    end

    %% Cablage Mocks -> Providers
    M_Ken --> P_Ken
    M_Brd --> P_Brd
    M_Lit --> P_Lit
    M_Pup --> P_Pup
    M_Wgh --> P_Wgh
    M_Car --> P_Car
    M_Set --> P_Set

    %% ViewModels
    subgraph ViewModels ["ViewModels (ChangeNotifier)"]
        VM_Onb["OnboardingViewModel"]
        VM_Dsh["DashboardViewModel"]
        VM_BrdLst["BreederListViewModel"]
        VM_BrdPrf["BreederProfileViewModel"]
        VM_LitLst["LittersViewModel"]
        VM_LitDet["LitterDetailViewModel"]
        VM_LitDec["LitterDeclarationViewModel"]
        VM_PupBtc["PuppyBatchViewModel"]
        VM_GrpWgh["GroupWeighingViewModel"]
        VM_PupFil["PuppyFileViewModel"]
        VM_AddCar["AddCareViewModel"]
        VM_Settings["SettingsViewModel"]
    end

    %% Injections dans les ViewModels (ProxyProviders)
    P_Ken -->|Injection| VM_Onb
    
    P_Ken & P_Lit & P_Pup & P_Car & P_Set -->|Proxy5| VM_Dsh
    P_Brd -->|Proxy| VM_BrdLst
    P_Brd -->|Proxy| VM_BrdPrf
    P_Lit & P_Set -->|Proxy2| VM_LitLst
    P_Lit & P_Brd & P_Pup -->|Proxy3| VM_LitDet
    P_Lit & P_Brd -->|Proxy2| VM_LitDec
    P_Pup -->|Proxy| VM_PupBtc
    P_Pup & P_Wgh -->|Proxy2| VM_GrpWgh
    P_Pup & P_Wgh & P_Car & P_Set -->|Proxy4| VM_PupFil
    P_Pup & P_Car -->|Proxy2| VM_AddCar
    P_Ken & P_Set -->|Proxy2| VM_Settings

    classDef repo fill:#e8f5e9,stroke:#2e7d32,stroke-width:1px;
    classDef prov fill:#e3f2fd,stroke:#1565c0,stroke-width:1.5px;
    classDef vmod fill:#fff3e0,stroke:#ef6c00,stroke-width:2px;
    
    class M_Ken,M_Brd,M_Lit,M_Pup,M_Wgh,M_Car,M_Set repo;
    class P_Ken,P_Brd,P_Lit,P_Pup,P_Wgh,P_Car,P_Set prov;
    class VM_Onb,VM_Dsh,VM_BrdLst,VM_BrdPrf,VM_LitLst,VM_LitDet,VM_LitDec,VM_PupBtc,VM_GrpWgh,VM_PupFil,VM_AddCar,VM_Settings vmod;
```

---

## 3. Carte de Navigation `go_router`

Le routage est structuré de façon déclarative dans [app_router.dart](file:///Users/cyril/dev/portea/portea_flutter/lib/core/routing/app_router.dart) avec un `StatefulShellRoute` pour l'interface principale à onglets, et des routes directes sur le root navigator pour les flux d'onboarding, de paywall et de fiches détaillées.

### Schéma global des Routes :

```mermaid
graph TD
    %% Racine du routeur
    Root(((Navigator racine)))
    
    %% Routes onboarding
    subgraph Onboarding ["Onboarding (Hors-Onglets)"]
        R_Welcome["/onboarding/welcome"]
        R_Setup["/onboarding/setup"]
        R_Notif["/onboarding/notifications"]
    end
    
    Root --> R_Welcome
    Root --> R_Setup
    Root --> R_Notif
    
    %% Shell Navigation
    subgraph ShellTab ["StatefulShellRoute (Onglets principaux)"]
        %% Branch 1
        subgraph Branch1 ["Onglet 1: Accueil"]
            R_Dsh["/dashboard"]
        end
        %% Branch 2
        subgraph Branch2 ["Onglet 2: Reproducteurs"]
            R_Breeders["/breeders"]
        end
        %% Branch 3
        subgraph Branch3 ["Onglet 3: Portées"]
            R_Litters["/litters"]
        end
        %% Branch 4
        subgraph Branch4 ["Onglet 4: Réglages"]
            R_Set["/settings"]
        end
    end
    
    Root --> ShellTab
    
    %% Sous-routes poussant sur le Root Navigator (parentNavigatorKey)
    subgraph RootSubroutes ["Sous-routes poussées au premier plan (sur le Root)"]
        %% Breeder Profile
        R_BreedersNew["/breeders/new"]
        R_BreedersId["/breeders/:id"]
        
        %% Litter Details & actions
        R_LittersNew["/litters/new"]
        R_LittersId["/litters/:id"]
        R_PupBatch["/litters/:id/puppies/batch"]
        R_GrpWeighing["/litters/:id/weighing"]
        R_AddCare["/litters/:id/care"]
        R_Docs["/litters/:id/documents"]
        
        %% Puppy File
        R_PuppyId["/puppies/:id"]
        
        %% Premium
        R_Premium["/premium"]
    end

    %% Liaisons de navigation logique
    R_Breeders --> R_BreedersNew & R_BreedersId
    R_Litters --> R_LittersNew & R_LittersId
    R_LittersId --> R_PupBatch & R_GrpWeighing & R_AddCare & R_Docs
    Root --> R_PuppyId
    Root --> R_Premium

    classDef rootRoute fill:#eceff1,stroke:#37474f,stroke-width:2px;
    classDef shellRoute fill:#ede7f6,stroke:#4527a0,stroke-width:1.5px;
    classDef specRoute fill:#fbe9e7,stroke:#d84315,stroke-width:1.5px;
    
    class Root rootRoute;
    class R_Dsh,R_Breeders,R_Litters,R_Set shellRoute;
    class R_Welcome,R_Setup,R_Notif,R_BreedersNew,R_BreedersId,R_LittersNew,R_LittersId,R_PupBatch,R_GrpWeighing,R_AddCare,R_Docs,R_PuppyId,R_Premium specRoute;
```

### Logique de Redirection (Guards) :

Au chargement de l'application et à chaque mise à jour du `OnboardingViewModel` (qui sert de `refreshListenable`), la fonction de redirection est appelée :

```mermaid
flowchart TD
    Start([Route demandée par l'utilisateur]) --> Guard1{L'utilisateur tente d'aller sur /onboarding/* ?}
    
    Guard1 -- NON --> Guard2{Onboarding complété ?<br>isOnboardingCompleted}
    Guard2 -- OUI --> Allow([Laisser passer vers la route cible])
    Guard2 -- NON --> RedirWelcome([Rediriger vers /onboarding/welcome])
    
    Guard1 -- OUI --> Guard3{Onboarding complété ?<br>isOnboardingCompleted}
    Guard3 -- OUI --> RedirDashboard([Rediriger vers /dashboard])
    Guard3 -- NON --> Allow
```

---

## 4. Flux de Données Actuel (Mock) vs Cible (Serverpod)

Le passage de la version actuelle (100% Mockée en mémoire) à la version de production nécessite de remplacer la source de données par le serveur Serverpod `portea_server`.

```mermaid
sequenceDiagram
    autonumber
    rect rgb(240, 248, 255)
        note right of ViewModel: FLUX ACTUEL (MOCK)
        ViewModel->>MockRepository: Appelle getXxx() / createXxx()
        MockRepository->>MockDatabase: Lit/écrit dans les Listes locales en mémoire
        MockDatabase-->>MockRepository: Retourne les objets de test
        MockRepository-->>ViewModel: Retourne les modèles simulés
    end
    rect rgb(245, 245, 220)
        note right of ViewModel: FLUX CIBLE (SERVERPOD)
        ViewModel->>ServerpodRepository: Appelle getXxx() / createXxx()
        ServerpodRepository->>portea_client (Client): Appelle l'endpoint de l'API cliente
        portea_client (Client)->>Serverpod Server: Requête WebSocket/HTTP (Session incluse)
        Serverpod Server->>PostgreSQL DB: Requête SQL sécurisée (Filtre par kennelId de la session)
        PostgreSQL DB-->>Serverpod Server: Retourne les données brutes
        Serverpod Server-->>portea_client (Client): Envoie les objets sérialisés
        portea_client (Client)-->>ServerpodRepository: Retourne le modèle généré
        ServerpodRepository-->>ViewModel: Retourne les modèles Serverpod
    end
```

### Cartographie des endpoints Serverpod à créer (par feature)

| Feature | Méthode Repository Cible | Endpoint Serverpod à implémenter | Détails & Logique Métier Serveur |
| :--- | :--- | :--- | :--- |
| **F01 Onboarding** | `ServerpodKennelRepository` | `kennel` endpoint :<br>- `getMyKennel()` : `Future<Kennel?>`<br>- `createKennel(Kennel)` : `Future<Kennel>` | - Dérive l'ID utilisateur de la `Session` (jamais de paramètre client).<br>- Garantit une relation 1:1 stricte entre l'utilisateur et l'élevage.<br>- Résout si l'onboarding est complété en vérifiant si `getMyKennel()` retourne un élevage (non nul). Pas de flag de complétion dédié stocké en base. |
| **F02 Reproducteurs** | `ServerpodBreederRepository` | `breeder` endpoint :<br>- `getBreeders()` : `Future<List<Breeder>>`<br>- `getBreeder(id)` : `Future<Breeder>`<br>- `createBreeder(Breeder)` : `Future<Breeder>`<br>- `updateBreeder(Breeder)` : `Future<Breeder>` | - Filtrage systématique : `WHERE kennelId = session.kennel.id`.<br>- Le sexe (`sex`) est figé lors de la création.<br>- Un reproducteur `'retired'` est exclu des listes de sélection pour les futures portées. |
| **F03 Portées** | `ServerpodLitterRepository` | `litter` endpoint :<br>- `getLitters()` : `Future<List<Litter>>`<br>- `getActiveLitter()` : `Future<Litter?>`<br>- `getLitter(id)` : `Future<Litter>`<br>- `createLitter(Litter)` : `Future<Litter>`<br>- `updateLitter(Litter)` : `Future<Litter>` | - **Contrôle Freemium** : Si l'utilisateur est gratuit et a déjà 1 portée active, renvoie une erreur métier bloquante lors de la création d'une nouvelle portée.<br>- Filtrage par `kennelId` dérivé. |
| **F04 / F08 Chiots** | `ServerpodPuppyRepository` | `puppy` endpoint :<br>- `getPuppies(litterId)` : `Future<List<Puppy>>`<br>- `getPuppy(id)` : `Future<Puppy>`<br>- `createPuppiesBatch(List<Puppy>)` : `Future<List<Puppy>>`<br>- `updatePuppy(Puppy)` : `Future<Puppy>` | - La création en lot pré-remplit les lignes existantes si appel de mise à jour.<br>- Validation : la portée (`litterId`) doit bien appartenir à l'élevage de l'utilisateur.<br>- Les infos acquéreur sont stockées dans `Puppy` mais masquées dans l'UI si statut `'available'`. |
| **F05 Pesées** | `ServerpodWeighingRepository` | `weighing` endpoint :<br>- `getWeighings(puppyId)` : `Future<List<WeighingEntry>>`<br>- `addWeighings(List<WeighingEntry>)` : `Future<void>` | - Poids en grammes (`double`).<br>- Validation d'appartenance du chiot à l'élevage de la session.<br>- Trié chronologiquement sur le serveur. |
| **F06 / F07 Soins** | `ServerpodCareRepository` | `care` endpoint :<br>- `getCareEntries(puppyId?, litterId?)`<br>- `addCareEntry(CareEntry)` : `Future<CareEntry>`<br>- `getUpcomingReminders(limit)` : `Future<List<CareEntry>>` | - Soin groupé : 1 entrée parent avec `litterId` (porte la date de rappel `reminderAt`) + N entrées enfants avec `puppyId` (`reminderAt` forcé à null pour éviter les doublons).<br>- Les rappels sont persistés en base mais déclenchés localement par l'application (F07). |
| **F09 Documents** | `ServerpodDocumentRepository` | `document` endpoint :<br>- `uploadCessionPdf(bytes, puppyId)` : `Future<String>` *(retourne l'URL)*<br>- `getIssuedDocuments(puppyId)` : `Future<List<IssuedDocument>>` | - Upload de l'attestation de cession vers l'Object Storage Serverpod.<br>- Enregistre l'historique dans la table `IssuedDocument`. |
| **F10 Premium** | `ServerpodSettingsRepository` | `webhooks` endpoint *(HTTP standard)* :<br>- `POST /webhooks/revenuecat` | - Webhook appelé par RevenueCat pour mettre à jour la valeur `Kennel.premiumUntil` (date/heure). Le client ne fait jamais d'écriture directe sur le statut premium. |
