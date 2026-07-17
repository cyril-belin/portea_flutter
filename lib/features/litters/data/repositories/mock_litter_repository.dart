import 'package:portea_client/portea_client.dart';
import '../../../../core/data/mock_database.dart';
import '../../domain/repositories/i_litter_repository.dart';

class MockLitterRepository implements ILitterRepository {
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
  Future<List<Litter>> getLitters() async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_db.litters);
  }

  @override
  Future<Litter?> getActiveLitter() async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _db.litters.firstWhere((l) => l.isActive);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Litter?> getLitter(int id) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _db.litters.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Litter> createLitter(Litter litter) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 200));
    final newId = _db.litters.isEmpty
        ? 1
        : _db.litters.map((l) => l.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    final created = Litter(
      id: newId,
      motherId: litter.motherId,
      fatherId: litter.fatherId,
      externalSireName: litter.externalSireName,
      externalSireId: litter.externalSireId,
      birthDate: litter.birthDate,
      kennelId: litter.kennelId,
      isActive: litter.isActive,
    );
    _db.litters.add(created);
    return created;
  }

  @override
  Future<void> updateLitter(Litter litter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _db.litters.indexWhere((l) => l.id == litter.id);
    if (idx != -1) {
      _db.litters[idx] = litter;
    }
  }
}
