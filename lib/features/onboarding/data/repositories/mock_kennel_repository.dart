import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_kennel_repository.dart';

class MockKennelRepository implements IKennelRepository {
  Kennel? _kennel;

  @override
  Future<Kennel?> getKennel() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _kennel;
  }

  @override
  Future<Kennel> createKennel(Kennel kennel) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _kennel = kennel;
    return kennel;
  }

  @override
  Future<void> updateKennel(Kennel kennel) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _kennel = kennel;
  }
}
