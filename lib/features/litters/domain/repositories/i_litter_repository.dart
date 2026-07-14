import 'package:portea_client/portea_client.dart';

abstract class ILitterRepository {
  Future<List<Litter>> getLitters();
  Future<Litter?> getActiveLitter();
  Future<Litter?> getLitter(int id);
  Future<Litter> createLitter(Litter litter);
  Future<void> updateLitter(Litter litter);
}
