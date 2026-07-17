import 'package:flutter_test/flutter_test.dart';
import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/core/notifications/inotification_service.dart';

import '../../helpers/mock_notification_service.dart';

void main() {
  group('parseNotificationPayload (deep-link routing)', () {
    test('individual care route → puppy file', () {
      expect(parseNotificationPayload('/puppies/42'), '/puppies/42');
    });

    test('group care route → litter detail', () {
      expect(parseNotificationPayload('/litters/7'), '/litters/7');
    });

    test('null payload → dashboard, never crashes', () {
      expect(parseNotificationPayload(null), '/dashboard');
    });

    test('empty payload → dashboard', () {
      expect(parseNotificationPayload(''), '/dashboard');
    });

    test('garbage payload → dashboard', () {
      expect(parseNotificationPayload('not-a-route'), '/dashboard');
    });

    test('route with non-numeric id → dashboard', () {
      expect(parseNotificationPayload('/puppies/abc'), '/dashboard');
    });

    test('route with extra path segments → dashboard', () {
      expect(parseNotificationPayload('/puppies/1/extra'), '/dashboard');
    });
  });

  group('MockNotificationService.rescheduleAll', () {
    late MockNotificationService service;

    setUp(() {
      service = MockNotificationService();
    });

    test(
      'schedules only future reminders, skips past and null-reminder ones',
      () {
        final now = DateTime.now();
        final entries = [
          CareEntry(
            id: 1,
            type: 'vaccine',
            product: 'Rabigen',
            appliedAt: now,
            puppyId: 10,
            reminderAt: now.add(const Duration(days: 2)), // future → scheduled
          ),
          CareEntry(
            id: 2,
            type: 'deworming',
            product: 'Milbemax',
            appliedAt: now,
            litterId: 5,
            reminderAt: now.subtract(const Duration(days: 1)), // past → skipped
          ),
          CareEntry(
            id: 3,
            type: 'vaccine',
            product: 'Rabigen',
            appliedAt: now,
            puppyId: 11,
            // reminderAt null → skipped
          ),
        ];

        service.rescheduleAll(entries);

        // Only the future one (id 1) is scheduled; past (id 2) and null (id 3)
        // are skipped. This mirrors NotificationService's past-date guard.
        expect(service.scheduled, [
          (id: 1, payload: '/puppies/10'),
        ]);
        expect(service.rescheduledBatches.length, 1);
      },
    );

    test('idempotent: two calls schedule the same set of ids', () {
      final now = DateTime.now();
      final entries = [
        CareEntry(
          id: 1,
          type: 'vaccine',
          product: 'Rabigen',
          appliedAt: now,
          puppyId: 10,
          reminderAt: now.add(const Duration(days: 2)),
        ),
        CareEntry(
          id: 2,
          type: 'vaccine',
          product: 'Rabigen',
          appliedAt: now,
          puppyId: 11,
          reminderAt: now.add(const Duration(days: 3)),
        ),
      ];

      service.rescheduleAll(entries);
      final firstRun = List<({int id, String payload})>.from(service.scheduled);

      service.scheduled.clear();
      service.rescheduleAll(entries);
      final secondRun = service.scheduled;

      // Re-scheduling the same ids replaces (idempotent): same set both times.
      expect(secondRun, firstRun);
      expect(service.rescheduledBatches.length, 2);
    });
  });
}
