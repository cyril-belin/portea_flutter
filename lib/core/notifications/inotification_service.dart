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

  /// Cancels EVERY pending reminder on the device. Used EXCLUSIVELY by the
  /// RGPD account deletion flow (F10-B): a deleted account has no living
  /// care entries, so any reminder still scheduled would ring for a kennel
  /// that no longer exists. There is no other legitimate caller — per-entry
  /// cancellation goes through [cancelReminder].
  Future<void> cancelAll();

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

/// Builds the reminder title from the target name (F07 rule 7, literal).
///
/// - Individual care: `Rappel soin — {puppyName}`.
/// - Group care: `Rappel soin — Portée de {motherName}` (the litter model has
///   no name, so the mother's name qualifies it).
String reminderTitle({String? puppyName, String? motherName}) {
  if (puppyName != null && puppyName.trim().isNotEmpty) {
    return 'Rappel soin — $puppyName';
  }
  if (motherName != null && motherName.trim().isNotEmpty) {
    return 'Rappel soin — Portée de $motherName';
  }
  return 'Rappel soin';
}

/// Builds the reminder body: `{Type} — {produit}`, product omitted when null or
/// blank (F07 rule 7).
String reminderBody({required String type, String? product}) {
  final typeLabel = switch (type) {
    'vaccine' => 'Vaccin',
    'deworming' => 'Vermifuge',
    _ => 'Soin',
  };
  if (product == null || product.trim().isEmpty) return typeLabel;
  return '$typeLabel — $product';
}
