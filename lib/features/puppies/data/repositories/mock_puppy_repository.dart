import 'package:portea_client/portea_client.dart';
import '../../../../core/data/mock_database.dart';
import '../../domain/repositories/i_puppy_repository.dart';

class MockPuppyRepository implements IPuppyRepository {
  final _db = MockDatabase.instance;

  @override
  Future<List<Puppy>> getPuppies(int litterId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_db.puppies.where((p) => p.litterId == litterId));
  }

  @override
  Future<Puppy?> getPuppy(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _db.puppies.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Puppy> createPuppy(Puppy puppy) async {
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
  Future<List<Puppy>> createPuppiesBatch(List<Puppy> puppies) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final createdList = <Puppy>[];
    for (final p in puppies) {
      final created = await createPuppy(p);
      createdList.add(created);
    }
    return createdList;
  }

  @override
  Future<void> updatePuppy(Puppy puppy) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _db.puppies.indexWhere((p) => p.id == puppy.id);
    if (idx != -1) {
      _db.puppies[idx] = puppy;
    }
  }
}
