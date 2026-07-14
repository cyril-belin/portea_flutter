import 'package:portea_client/portea_client.dart';
import '../../../../core/data/mock_database.dart';
import '../../domain/repositories/i_care_repository.dart';

class MockCareRepository implements ICareRepository {
  final _db = MockDatabase.instance;

  @override
  Future<List<CareEntry>> getCareEntries({int? puppyId, int? litterId}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var results = _db.careEntries;
    if (puppyId != null) {
      results = results.where((c) => c.puppyId == puppyId).toList();
    } else if (litterId != null) {
      results = results.where((c) => c.litterId == litterId).toList();
    }
    results.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    return List.unmodifiable(results);
  }

  @override
  Future<void> addCareEntry(CareEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newId = _db.careEntries.isEmpty
        ? 1
        : _db.careEntries
                  .map((c) => c.id ?? 0)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    final created = CareEntry(
      id: newId,
      type: entry.type,
      product: entry.product,
      appliedAt: entry.appliedAt,
      puppyId: entry.puppyId,
      litterId: entry.litterId,
      reminderAt: entry.reminderAt,
      notes: entry.notes,
    );
    _db.careEntries.add(created);
  }

  @override
  Future<List<CareEntry>> getUpcomingReminders(int limit) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    final reminders = _db.careEntries
        .where((c) => c.reminderAt != null && c.reminderAt!.isAfter(now))
        .toList();
    reminders.sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
    return List.unmodifiable(reminders.take(limit));
  }
}
