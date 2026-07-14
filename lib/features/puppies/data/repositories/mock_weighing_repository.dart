import 'package:portea_client/portea_client.dart';
import '../../../../core/data/mock_database.dart';
import '../../domain/repositories/i_weighing_repository.dart';

class MockWeighingRepository implements IWeighingRepository {
  final _db = MockDatabase.instance;

  @override
  Future<List<WeighingEntry>> getWeighings(int puppyId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final entries = _db.weighings.where((w) => w.puppyId == puppyId).toList();
    entries.sort((a, b) => a.weighedAt.compareTo(b.weighedAt));
    return List.unmodifiable(entries);
  }

  @override
  Future<void> addWeighing(WeighingEntry entry) async {
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
    await Future.delayed(const Duration(milliseconds: 150));
    for (final entry in entries) {
      await addWeighing(entry);
    }
  }
}
