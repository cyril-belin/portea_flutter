import 'package:portea_client/portea_client.dart';
import '../../../../core/data/mock_database.dart';
import '../../domain/repositories/i_puppy_repository.dart';

class MockPuppyRepository implements IPuppyRepository {
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
  Future<List<Puppy>> getPuppies(int litterId) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_db.puppies.where((p) => p.litterId == litterId));
  }

  @override
  Future<Puppy?> getPuppy(int id) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _db.puppies.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Puppy> createPuppy(Puppy puppy) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 150));
    final newId = _db.puppies.isEmpty
        ? 1
        : _db.puppies.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    final created = Puppy(
      id: newId,
      litterId: puppy.litterId,
      name: puppy.name,
      sex: puppy.sex,
      color: puppy.color,
      status: puppy.status,
      chipNumber: puppy.chipNumber,
      birthWeight: puppy.birthWeight,
      photoUrl: puppy.photoUrl,
      buyerName: puppy.buyerName,
      buyerPhone: puppy.buyerPhone,
      buyerEmail: puppy.buyerEmail,
      buyerAddress: puppy.buyerAddress,
    );
    _db.puppies.add(created);
    return created;
  }

  @override
  Future<void> updatePuppy(Puppy puppy) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _db.puppies.indexWhere((p) => p.id == puppy.id);
    if (idx != -1) {
      _db.puppies[idx] = puppy;
    }
  }

  /// Mock implementation of the idempotent batch save, mirroring the server
  /// semantics so unit tests on the view model exercise the real flow.
  ///
  /// Note: the deletion guard (history blocks delete) is trivially true here,
  /// matching the server in F04 — the weighing/care tables are mock-only and
  /// not checked. See F05/F06.
  @override
  Future<List<Puppy>> savePuppiesBatch(int litterId, List<Puppy> items) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 250));

    // Remove puppies of this litter that are absent from the payload.
    final keptIds = items.where((p) => p.id != null).map((p) => p.id!).toSet();
    _db.puppies.removeWhere(
      (p) => p.litterId == litterId && !keptIds.contains(p.id),
    );

    // Insert new puppies (id null), update existing ones (id present).
    for (final item in items) {
      if (item.id == null) {
        await createPuppy(
          Puppy(
            litterId: litterId,
            name: item.name,
            sex: item.sex,
            color: item.color,
            status: item.status,
            chipNumber: item.chipNumber,
            birthWeight: item.birthWeight,
            photoUrl: item.photoUrl,
            buyerName: item.buyerName,
            buyerPhone: item.buyerPhone,
            buyerEmail: item.buyerEmail,
            buyerAddress: item.buyerAddress,
          ),
        );
      } else {
        await updatePuppy(
          Puppy(
            id: item.id,
            litterId: litterId,
            name: item.name,
            sex: item.sex,
            color: item.color,
            status: item.status,
            chipNumber: item.chipNumber,
            birthWeight: item.birthWeight,
            photoUrl: item.photoUrl,
            buyerName: item.buyerName,
            buyerPhone: item.buyerPhone,
            buyerEmail: item.buyerEmail,
            buyerAddress: item.buyerAddress,
          ),
        );
      }
    }

    return getPuppies(litterId);
  }
}
