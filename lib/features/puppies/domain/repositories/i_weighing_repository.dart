import 'package:portea_client/portea_client.dart';

abstract class IWeighingRepository {
  Future<List<WeighingEntry>> getWeighings(int puppyId);
  Future<void> addWeighing(WeighingEntry entry);
  Future<void> addWeighings(List<WeighingEntry> entries);

  /// Returns each puppy of a litter joined with its most recent weighing (or
  /// `null` when the puppy has never been weighed). This is the anti-N+1 read
  /// for the group-weighing screen (review claim 3.5): one call replaces one
  /// `getWeighings` request per puppy.
  Future<List<PuppyWithLastWeighing>> getPuppiesWithLastWeighing(
    int litterId,
  );
}
