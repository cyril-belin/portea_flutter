import 'package:portea_client/portea_client.dart';
import '../../../../core/data/mock_database.dart';
import '../../domain/repositories/i_care_repository.dart';

class MockCareRepository implements ICareRepository {
  final _db = MockDatabase.instance;

  /// When non-null, the next repository call throws this. Consumed on first
  /// call, then reset to null.
  Object? throwOnNext;

  Future<void> _maybeThrow() async {
    final pending = throwOnNext;
    if (pending != null) {
      throwOnNext = null;
      throw pending;
    }
  }

  int _nextId() => _db.careEntries.isEmpty
      ? 1
      : _db.careEntries.map((c) => c.id ?? 0).reduce((a, b) => a > b ? a : b) +
            1;

  @override
  Future<List<CareEntry>> getCareEntries({int? puppyId, int? litterId}) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 100));
    List<CareEntry> results;
    if (puppyId != null) {
      results = _db.careEntries.where((c) => c.puppyId == puppyId).toList();
    } else if (litterId != null) {
      // Group-care parent entries only (the server's getLitterCareEntries
      // returns parents, not the per-puppy children).
      results = _db.careEntries.where((c) => c.litterId == litterId).toList();
    } else {
      throw ArgumentError(
        'getCareEntries requires exactly one of puppyId or litterId',
      );
    }
    results.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    return List.unmodifiable(results);
  }

  @override
  Future<CareEntry> addCareEntry(CareEntry entry) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 100));
    final created = CareEntry(
      id: _nextId(),
      type: entry.type,
      product: entry.product,
      appliedAt: entry.appliedAt,
      puppyId: entry.puppyId,
      // Mirrors the server: individual care attaches to the puppy, never the
      // litter. A client-supplied litterId is ignored.
      litterId: null,
      reminderAt: entry.reminderAt,
      notes: entry.notes,
    );
    _db.careEntries.add(created);
    return created;
  }

  /// Group care — mirrors the server's transactional addGroupCare and its
  /// central rule (review claim 4.3): ONE parent (litterId, reminderAt) + ONE
  /// child per puppy (puppyId, reminderAt forced null). The children NEVER
  /// carry a reminderAt — that is the rule this mock exists to pin in the
  /// Flutter tests.
  @override
  Future<List<CareEntry>> addGroupCare({
    required int litterId,
    required String type,
    String? product,
    required DateTime appliedAt,
    DateTime? reminderAt,
    String? notes,
  }) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 100));

    final created = <CareEntry>[];

    // Parent: carries the litterId AND the reminderAt.
    final parent = CareEntry(
      id: _nextId(),
      type: type,
      product: product,
      appliedAt: appliedAt,
      puppyId: null,
      litterId: litterId,
      reminderAt: reminderAt,
      notes: notes,
    );
    _db.careEntries.add(parent);
    created.add(parent);

    // One child per puppy of the litter. reminderAt FORCED to null — never
    // set on a child. This is the heart of the F06 rule.
    final puppies = _db.puppies.where((p) => p.litterId == litterId).toList();
    for (final puppy in puppies) {
      final child = CareEntry(
        id: _nextId(),
        type: type,
        product: product,
        appliedAt: appliedAt,
        puppyId: puppy.id,
        litterId: null,
        reminderAt: null, // FORCED — never set on a child.
        notes: notes,
      );
      _db.careEntries.add(child);
      created.add(child);
    }

    return List.unmodifiable(created);
  }

  @override
  Future<List<CareEntry>> getUpcomingReminders(int limit) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    final reminders = _db.careEntries
        .where((c) => c.reminderAt != null && c.reminderAt!.isAfter(now))
        .toList();
    reminders.sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
    return List.unmodifiable(reminders.take(limit));
  }
}
