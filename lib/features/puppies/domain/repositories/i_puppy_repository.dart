import 'package:portea_client/portea_client.dart';

abstract class IPuppyRepository {
  Future<List<Puppy>> getPuppies(int litterId);
  Future<Puppy?> getPuppy(int id);
  Future<Puppy> createPuppy(Puppy puppy);
  Future<void> updatePuppy(Puppy puppy);

  /// Saves a batch of puppies for a litter, idempotently.
  ///
  /// An item with `id == null` is inserted; an item with an `id` is updated.
  /// A puppy present in the database for [litterId] but absent from [items] is
  /// deleted (server rules apply — see `PuppyEndpoint.savePuppiesBatch`).
  /// Returns the fresh list of puppies for the litter (newly inserted puppies
  /// carry their assigned ids).
  Future<List<Puppy>> savePuppiesBatch(int litterId, List<Puppy> items);
}
