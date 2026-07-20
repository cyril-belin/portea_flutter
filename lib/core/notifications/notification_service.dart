import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'inotification_service.dart';

/// Concrete [INotificationService] backed by `flutter_local_notifications`.
///
/// Single entry point for all OS local-notification work. Injected via Provider
/// (see `main.dart`) — no global singleton. The OS scheduling itself is not
/// unit-testable; tests run against a mock that implements
/// [INotificationService].
///
/// Notification id = `CareEntry.id` (F07 rule 2). Re-scheduling the same id
/// replaces the pending notification (idempotent).
class NotificationService implements INotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(String payload)? _onNotificationTap;

  /// Android notification channel for care reminders.
  static const _channelId = 'care_reminders';
  static const _channelName = 'Rappels de soins';
  static const _channelDescription =
      'Rappels pour les soins à venir (vermifuges, vaccins…).';

  @override
  Future<void> initialize({
    void Function(String payload)? onNotificationTap,
  }) async {
    if (_initialized) return;

    // Load the IANA timezone database once, then pin the device's local zone
    // so zonedSchedule resolves the reminder time correctly on-device.
    tz_data.initializeTimeZones();
    try {
      final identifier = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(identifier));
    } catch (_) {
      // Non-fatal: scheduling still works, just in UTC. The OS still fires the
      // alarm; only the wall-clock interpretation is less precise.
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    _onNotificationTap = onNotificationTap;
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    _initialized = true;
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _onNotificationTap?.call(payload);
    }
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return result ?? false;
    }

    // Desktop / web: no OS permission model, treat as granted.
    return true;
  }

  @override
  Future<({bool didLaunchApp, String? payload})?>
  getNotificationAppLaunchDetails() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null) return null;
    return (
      didLaunchApp: details.didNotificationLaunchApp,
      payload: details.notificationResponse?.payload,
    );
  }

  @override
  Future<void> scheduleReminder({
    required int notificationId,
    required DateTime scheduledAt,
    required String title,
    required String body,
    required String payload,
  }) async {
    await initialize();

    // Past-date guard: the plugin throws ArgumentError on a past scheduledDate,
    // and some platforms fire immediately. Silently skip.
    if (!scheduledAt.isAfter(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(scheduledAt, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final scheduleMode = await _resolveAndroidScheduleMode(androidPlugin);

    await _plugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      payload: payload,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: scheduleMode,
    );
  }

  /// Picks exact scheduling when the OS grants `SCHEDULE_EXACT_ALARM`, else
  /// falls back to inexact mode that still survives Doze. Android 14+ restricts
  /// the exact-alarm permission, so this prevents a crash when it is denied.
  Future<AndroidScheduleMode> _resolveAndroidScheduleMode(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    if (androidPlugin == null) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    final canScheduleExact = await androidPlugin
        .canScheduleExactNotifications();
    if (canScheduleExact == false) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    return AndroidScheduleMode.exactAllowWhileIdle;
  }

  @override
  Future<void> cancelReminder(int notificationId) async {
    await _plugin.cancel(id: notificationId);
  }

  @override
  Future<void> cancelAll() async {
    // No initialize() guard here: cancelAll runs after account deletion,
    // when the plugin is already initialized (it was at app startup in
    // main()). A pristine state is the goal — every pending reminder for
    // the now-deleted kennel must disappear.
    await _plugin.cancelAll();
  }

  @override
  String handleNotificationPayload(String? payload) =>
      parseNotificationPayload(payload);
}
