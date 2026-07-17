import 'package:portea_client/portea_client.dart';

/// Notification service contract.
///
/// Exists so view models and the auth flow can depend on an injectable,
/// mockable abstraction rather than the concrete [NotificationService] that
/// wraps `flutter_local_notifications`. The OS scheduling itself is not
/// unit-testable; everything behind this interface is.
///
/// Notification id contract (F07 rule 2): the id of a reminder notification is
/// the persisted [CareEntry.id]. Stable and unique — re-scheduling the same id
/// replaces the pending notification (idempotent).
abstract class INotificationService {
  /// Initializes the plugin and resolves the device's local timezone.
  ///
  /// Safe to call multiple times. Must run once before any scheduling — in
  /// practice from `main()` before `runApp`. [onNotificationTap] is invoked
  /// when the user taps a notification while the app is alive.
  Future<void> initialize({
    void Function(String payload)? onNotificationTap,
  });

  /// Requests the OS notification permission (iOS alert/badge/sound, Android
  /// POST_NOTIFICATIONS on API 33+). Returns whether permission was granted.
  ///
  /// Permission denied is a handled state: the app keeps working normally and
  /// reminders are simply silent. No error, no blocking, no aggressive
  /// re-prompting.
  Future<bool> requestPermission();

  /// Returns whether the app was launched by the user tapping a notification
  /// (the killed-app case), and the tapped notification's payload if so. Null
  /// where the platform doesn't expose launch details.
  ///
  /// Call once at startup (main); the tap-while-alive case is delivered via the
  /// [initialize] `onNotificationTap` callback instead.
  Future<({bool didLaunchApp, String? payload})?>
  getNotificationAppLaunchDetails();

  /// Schedules a local reminder. Idempotent by [notificationId]: re-scheduling
  /// the same id replaces the pending notification.
  ///
  /// Past-date guard: if [scheduledAt] is already in the past, this is a no-op
  /// (some platforms crash or fire immediately otherwise).
  ///
  /// Android exact-alarm: if the OS denies `SCHEDULE_EXACT_ALARM` (Android 14+
  /// restricts it), the call falls back to inexact mode rather than crashing.
  Future<void> scheduleReminder({
    required int notificationId,
    required DateTime scheduledAt,
    required String title,
    required String body,
    required String payload,
  });

  /// Cancels the single reminder with the given id. Only ever invoked when the
  /// specific [CareEntry] it belongs to is modified or deleted — NEVER on care
  /// registration (F07 rule 4: no cross-cancellation).
  Future<void> cancelReminder(int notificationId);

  /// Re-schedules every future reminder found in [entries]. Idempotent: calling
  /// twice yields the same set of scheduled ids. Used at startup (after login)
  /// to survive a device reboot. Entries with a past [CareEntry.reminderAt] or
  /// a null id are skipped.
  Future<void> rescheduleAll(List<CareEntry> entries);

  /// Parses a notification [payload] into a go_router route.
  ///
  /// - `/puppies/<id>` — individual care (puppy file).
  /// - `/litters/<id>` — group care (litter detail; the parent entry carries
  ///   the reminderAt).
  /// - Anything invalid or null falls back to `/dashboard` — never crashes.
  String handleNotificationPayload(String? payload);
}

/// Pure payload → route parser, usable without a service instance (e.g. from
/// the top-level notification-tap handler wired in `main()`).
///
/// Contract mirrored by [INotificationService.handleNotificationPayload].
String parseNotificationPayload(String? payload) {
  if (payload == null || payload.isEmpty) return '/dashboard';

  final puppyMatch = RegExp(r'^/puppies/(\d+)$').firstMatch(payload);
  if (puppyMatch != null) return '/puppies/${puppyMatch.group(1)}';

  final litterMatch = RegExp(r'^/litters/(\d+)$').firstMatch(payload);
  if (litterMatch != null) return '/litters/${litterMatch.group(1)}';

  return '/dashboard';
}
