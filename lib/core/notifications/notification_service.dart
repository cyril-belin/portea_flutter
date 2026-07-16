import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wrapper around `flutter_local_notifications`.
///
/// F01 scope: initialize the plugin and request the OS notification permission.
/// Reminder scheduling (channels, timed notifications, deep links) is added in
/// F07 — this service is the single entry point that will host it.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initializes the plugin. Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Requests the OS notification permission (iOS alert/badge/sound, Android
  /// POST_NOTIFICATIONS on API 33+). Returns whether permission was granted.
  /// Must be called after [initialize].
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
}
