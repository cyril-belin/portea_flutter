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

    final ok = await _plugin.initialize(settings: initSettings);
    debugPrint('[NotificationService] initialize() -> $ok');
    _initialized = true;
  }

  /// Requests the OS notification permission. Returns a [PermissionResult]
  /// describing exactly what happened, so the UI can surface a diagnostic when
  /// the popup never appears (instead of failing silently).
  Future<PermissionResult> requestPermission() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
      if (iosPlugin == null) {
        return PermissionResult(
          platform: 'iOS',
          pluginResolved: false,
          granted: false,
          detail: 'IOSFlutterLocalNotificationsPlugin est null',
        );
      }
      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return PermissionResult(
        platform: 'iOS',
        pluginResolved: true,
        granted: result ?? false,
        detail: 'requestPermissions a retourné: $result',
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
      if (androidPlugin == null) {
        return PermissionResult(
          platform: 'android',
          pluginResolved: false,
          granted: false,
          detail: 'AndroidFlutterLocalNotificationsPlugin est null',
        );
      }
      final result = await androidPlugin.requestNotificationsPermission();
      return PermissionResult(
        platform: 'android',
        pluginResolved: true,
        granted: result ?? false,
        detail: 'requestNotificationsPermission a retourné: $result',
      );
    }

    // Desktop / web: no OS permission model, treat as granted.
    return PermissionResult(
      platform: defaultTargetPlatform.name,
      pluginResolved: false,
      granted: true,
      detail: 'Plateforme desktop/web: pas de modèle de permission',
    );
  }
}

/// Outcome of a notification permission request, with enough detail to
/// diagnose why the OS popup may not have appeared.
class PermissionResult {
  PermissionResult({
    required this.platform,
    required this.pluginResolved,
    required this.granted,
    required this.detail,
  });

  final String platform;
  final bool pluginResolved;
  final bool granted;
  final String detail;

  @override
  String toString() =>
      'plateforme=$platform, pluginResolu=$pluginResolved, '
      'accorde=$granted, detail=$detail';
}
