# F07 — Rappels (Notifications locales)

## Objectif

Planifier des notifications locales OS (iOS + Android) replanifiées à chaque soin enregistré avec un rappel. Deep-link conditionnel : vers la **fiche chiot** (`/puppies/:id`) si soin individuel, vers le **détail de portée** (`/litters/:id`) si soin de portée entière. Replanification au démarrage de l'app pour survivre à un reboot device.

---

## État actuel (audit 2026-07-15)

### Fait ✅
- `CareEntry.reminderAt` — champ DateTime présent dans le modèle, persisté
- `ICareRepository.getUpcomingReminders(limit)` — interface et implémentation mock
- `DashboardViewModel` — charge les 3 prochains rappels via `getUpcomingReminders(3)`
- `DashboardScreen` — affiche les rappels à venir (UI présente)
- `OnboardingNotificationsScreen` — écran de demande de permission (UI présente)
- Route deep-link `/puppies/:id` — déjà définie dans le router

### Absent ❌
- **`flutter_local_notifications`** : absent du pubspec
- **Demande de permission OS réelle** : `OnboardingNotificationsScreen` affiche l'UI mais n'appelle pas l'API système
- **Planification de notification** : aucune notification OS planifiée nulle part
- **Deep-link depuis notification** : mécanisme de payload → go_router absent
- **Replanification** : aucune logique de mise à jour/annulation de notification existante lors d'un nouveau soin

---

## Reste à faire

### Package
- [ ] Ajouter `flutter_local_notifications` au pubspec (avec `flutter_timezone` pour iOS) **dès l'étape F01** (permet d'initialiser et de faire la demande réelle de permission OS à l'onboarding).
- [ ] Configurer les permissions iOS (`Info.plist`) : `NSUserNotificationUsageDescription`
- [ ] Configurer les permissions Android (`AndroidManifest.xml`) : `SCHEDULE_EXACT_ALARM` (Android 12+), `RECEIVE_BOOT_COMPLETED` (pour replanifier au démarrage)

### Service de notifications
- [ ] Créer `lib/core/services/notification_service.dart` :
  - `initialize()` — initialisation flutter_local_notifications
  - `requestPermission()` — demande de permission OS (iOS + Android 13+)
  - `scheduleReminder({required int notificationId, required DateTime scheduledAt, required String title, required String body, required String payload})` — planifie une notif à date précise
  - `cancelReminder(int notificationId)` — annule une notif par ID
  - `handleNotificationPayload(String payload)` — parse le payload et navigue via go_router

### Intégration
- [ ] `OnboardingNotificationsScreen` : appeler `NotificationService.requestPermission()` (vrai appel OS)
- [ ] `AddCareViewModel.saveCareEntry()` : après persistance, si `reminderAt != null` → `NotificationService.scheduleReminder(notificationId: careEntry.id, ...)`. L'ID de notification = `CareEntry.id` (stable, idempotent).
- [ ] `NotificationService.initialize()` appelé dans `main()` avant `runApp()`
- [ ] Deep-link conditionnel dans le payload :
  - `CareEntry.puppyId != null` → payload = `'/puppies/<puppyId>'`
  - `CareEntry.litterId != null && puppyId == null` → payload = `'/litters/<litterId>'`
  - `onSelectNotification` appelle `goRouter.push(payload)`

### Replanification au démarrage (survie au reboot device)
- [ ] Au démarrage de l'app (après login) : appeler `NotificationService.rescheduleAll()` :
  - `getCareRepository.getUpcomingReminders()` → filtre `reminderAt.isAfter(now())`
  - Pour chaque entrée : `scheduleReminder(...)` (idempotent — remplace la notif si déjà programmée)
- [ ] Permission `RECEIVE_BOOT_COMPLETED` dans Android Manifest déjà prévue → permet aussi une replanification via BroadcastReceiver au boot si nécessaire (vérifier support flutter_local_notifications)

---

## Règles métier

1. Une notification = un `CareEntry` avec `reminderAt != null`.
2. L'`id` de notification = `CareEntry.id!` (int, unique, stable).
3. **Deep-link conditionnel** selon la cible du soin :
   - `CareEntry.puppyId != null` → `/puppies/<puppyId>` (fiche chiot)
   - `CareEntry.litterId != null && puppyId == null` → `/litters/<litterId>` (détail portée)
4. **Pas d'annulation croisée** : L'enregistrement d'un soin ne doit jamais annuler les rappels programmés d'autres soins pour le même chiot. `cancelReminder` n'est invoqué que si la `CareEntry` spécifique associée est modifiée ou supprimée.
5. **Replanification au démarrage** : toutes les notifications futures sont replanifiées après login. Garantit la survie au reboot device. Appel idempotent (remplace les notifs déjà planifiées).
6. Les notifications sont locales (pas de push Serverpod). Les données de rappel sont stockées en base via `CareEntry.reminderAt`.
7. Titre de la notif : "Rappel soin — [nom cible]". Corps : "[type de soin] avec [produit] prévu aujourd'hui".

---

## Critères d'acceptation

- [ ] Permission notifications demandée à l'onboarding (vrai appel OS).
- [ ] Après enregistrement d'un soin avec rappel → notification planifiée dans l'OS.
- [ ] La notification s'affiche à la date prévue.
- [ ] Tap sur notif de soin individuel → ouvre `/puppies/:id`.
- [ ] Tap sur notif de soin de portée → ouvre `/litters/:id`.
- [ ] Au redémarrage de l'app (après login) → toutes les notifications futures replanifiées (survie au reboot device).
- [ ] `dart analyze` 0 warning.
