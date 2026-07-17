import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/core/notifications/inotification_service.dart';

/// Test double for [INotificationService]. Records every call so tests can
/// assert on scheduling/cancellation without touching the real OS plugin.
///
/// The OS scheduling itself is not unit-testable; this mock is what makes the
/// view-model logic (schedule after success, never cancel, idempotence, past-
/// date guard, payload routing) verifiable.
class MockNotificationService implements INotificationService {
  /// Calls to [scheduleReminder], in order: (notificationId, payload).
  final List<({int id, String payload})> scheduled = [];

  /// Calls to [cancelReminder], in order.
  final List<int> cancelled = [];

  /// Calls to [rescheduleAll], in order (each entry's scheduled id list).
  final List<List<int>> rescheduledBatches = [];

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
    scheduled.add((id: notificationId, payload: payload));
  }

  @override
  Future<void> cancelReminder(int notificationId) async {
    cancelled.add(notificationId);
  }

  @override
  Future<void> rescheduleAll(List<CareEntry> entries) async {
    rescheduledBatches.add(entries.map((e) => e.id!).toList());
    for (final entry in entries) {
      final id = entry.id;
      final reminderAt = entry.reminderAt;
      if (id == null || reminderAt == null) continue;
      if (!reminderAt.isAfter(DateTime.now())) continue;
      scheduled.add((
        id: id,
        payload: entry.puppyId != null
            ? '/puppies/${entry.puppyId}'
            : '/litters/${entry.litterId}',
      ));
    }
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
    rescheduledBatches.clear();
    _initializeCalls = 0;
  }
}
