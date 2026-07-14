import 'package:portea_client/portea_client.dart';
import '../../../../core/data/mock_database.dart';
import '../../domain/repositories/i_breeder_repository.dart';

class MockBreederRepository implements IBreederRepository {
  final _db = MockDatabase.instance;

  @override
  Future<List<Breeder>> getBreeders() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_db.breeders);
  }

  @override
  Future<Breeder?> getBreeder(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _db.breeders.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Breeder> createBreeder(Breeder breeder) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newId = _db.breeders.isEmpty
        ? 1
        : _db.breeders.map((b) => b.id ?? 0).reduce((a, b) => a > b ? a : b) +
              1;
    final created = Breeder(
      id: newId,
      name: breeder.name,
      sex: breeder.sex,
      breed: breeder.breed,
      birthDate: breeder.birthDate,
      chipNumber: breeder.chipNumber,
      tattooNumber: breeder.tattooNumber,
      status: breeder.status,
      photoUrl: breeder.photoUrl,
      kennelId: breeder.kennelId,
    );
    _db.breeders.add(created);
    return created;
  }

  @override
  Future<void> updateBreeder(Breeder breeder) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _db.breeders.indexWhere((b) => b.id == breeder.id);
    if (idx != -1) {
      _db.breeders[idx] = breeder;
    }
  }
}
