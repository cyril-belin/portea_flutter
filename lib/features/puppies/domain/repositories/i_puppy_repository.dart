import 'package:portea_client/portea_client.dart';

abstract class IPuppyRepository {
  Future<List<Puppy>> getPuppies(int litterId);
  Future<Puppy?> getPuppy(int id);
  Future<Puppy> createPuppy(Puppy puppy);
  Future<List<Puppy>> createPuppiesBatch(List<Puppy> puppies);
  Future<void> updatePuppy(Puppy puppy);
}
