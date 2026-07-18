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

  /// Updates a puppy's status and (for `reserved`/`sold`) its buyer info and
  /// cession date. Mirrors `PuppyEndpoint.updatePuppyStatus` — see the server
  /// method doc for the F08 rules. In particular, a status of `available`
  /// PRESERVES the stored buyer* and cessionDate (the conservation rule); the
  /// client params for those fields are ignored on that branch.
  ///
  /// For `reserved`/`sold`, a null buyer* param is MERGED (preserves the
  /// stored value); a non-empty param overwrites it. Use this for status
  /// flips and partial buyer updates. To replace the whole dossier at once,
  /// pass every field explicitly.
  ///
  /// Throws [InvalidPuppyInputException] for an out-of-enum status, a `sold`
  /// transition with no buyerName (provided or stored), or invalid email/phone
  /// formats; [InvalidPuppyRelationException] for a forged/cross-kennel
  /// puppyId. Maps to a French user message via [mapExceptionToMessage].
  Future<Puppy> updatePuppyStatus(
    int puppyId,
    String status, {
    String? buyerName,
    String? buyerPhone,
    String? buyerEmail,
    String? buyerAddress,
    DateTime? cessionDate,
  });
}
