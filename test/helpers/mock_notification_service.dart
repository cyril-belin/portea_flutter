import 'package:portea_flutter/core/notifications/inotification_service.dart';

/// Recorded single schedule call: notificationId, title, body and payload.
typedef ScheduledCall = ({
  int id,
  String title,
  String body,
  String payload,
});

/// Test double for [INotificationService]. Records every call so tests can
/// assert on scheduling/cancellation without touching the real OS plugin.
///
/// The OS scheduling itself is not unit-testable; this mock is what makes the
/// view-model logic (schedule after success, never cancel, payload routing,
/// title/body content) verifiable.
class MockNotificationService implements INotificationService {
  /// Calls to [scheduleReminder], in order.
  final List<ScheduledCall> scheduled = [];

  /// Calls to [cancelReminder], in order.
  final List<int> cancelled = [];

  /// Number of calls to [cancelAll] (RGPD account deletion flow).
  int cancelAllCalls = 0;

  bool permissionGranted = true;
  int _initializeCalls = 0;
  int get initializeCalls => _initializeCalls;

  @override
  Future<void> initialize({
    void Function(String payload)? onNotificationTap,
  }) async {
    _initializeCalls++;
  }

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> scheduleReminder({
    required int notificationId,
    required DateTime scheduledAt,
    required String title,
    required String body,
    required String payload,
  }) async {
    scheduled.add((
      id: notificationId,
      title: title,
      body: body,
      payload: payload,
    ));
  }

  @override
  Future<void> cancelReminder(int notificationId) async {
    cancelled.add(notificationId);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  String handleNotificationPayload(String? payload) =>
      parseNotificationPayload(payload);

  @override
  Future<({bool didLaunchApp, String? payload})?>
  getNotificationAppLaunchDetails() async => null;

  /// Resets recorded calls between tests.
  void reset() {
    scheduled.clear();
    cancelled.clear();
    cancelAllCalls = 0;
    _initializeCalls = 0;
  }
}
