import 'package:portea_client/portea_client.dart';

abstract class IBreederRepository {
  Future<List<Breeder>> getBreeders();
  Future<Breeder?> getBreeder(int id);
  Future<Breeder> createBreeder(Breeder breeder);
  Future<void> updateBreeder(Breeder breeder);
}
