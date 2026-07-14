import 'package:portea_client/portea_client.dart';

abstract class IKennelRepository {
  Future<Kennel?> getKennel();
  Future<Kennel> createKennel(Kennel kennel);
  Future<void> updateKennel(Kennel kennel);
}
