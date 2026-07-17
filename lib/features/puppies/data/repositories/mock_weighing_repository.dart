import 'package:portea_client/portea_client.dart';
import '../../../../core/data/mock_database.dart';
import '../../domain/repositories/i_weighing_repository.dart';

class MockWeighingRepository implements IWeighingRepository {
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

  @override
  Future<List<WeighingEntry>> getWeighings(int puppyId) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 100));
    final entries = _db.weighings.where((w) => w.puppyId == puppyId).toList();
    entries.sort((a, b) => a.weighedAt.compareTo(b.weighedAt));
    return List.unmodifiable(entries);
  }

  @override
  Future<void> addWeighing(WeighingEntry entry) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 100));
    final newId = _db.weighings.isEmpty
        ? 1
        : _db.weighings.map((w) => w.id ?? 0).reduce((a, b) => a > b ? a : b) +
              1;
    final created = WeighingEntry(
      id: newId,
      puppyId: entry.puppyId,
      weighedAt: entry.weighedAt,
      weightGrams: entry.weightGrams,
    );
    _db.weighings.add(created);
  }

  @override
  Future<void> addWeighings(List<WeighingEntry> entries) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 150));
    for (final entry in entries) {
      await addWeighing(entry);
    }
  }

  @override
  Future<List<PuppyWithLastWeighing>> getPuppiesWithLastWeighing(
    int litterId,
  ) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 120));
    // Puppies of the litter, in id order (mirrors the server endpoint).
    final puppies = _db.puppies.where((p) => p.litterId == litterId).toList()
      ..sort((a, b) => a.id!.compareTo(b.id!));
    if (puppies.isEmpty) {
      return const [];
    }
    // Index the most recent weighing per puppy in a single pass.
    final byLast = <int, WeighingEntry>{};
    for (final w in _db.weighings) {
      final current = byLast[w.puppyId];
      if (current == null || w.weighedAt.isAfter(current.weighedAt)) {
        byLast[w.puppyId] = w;
      }
    }
    return [
      for (final p in puppies)
        PuppyWithLastWeighing(puppy: p, lastWeighing: byLast[p.id]),
    ];
  }
}
