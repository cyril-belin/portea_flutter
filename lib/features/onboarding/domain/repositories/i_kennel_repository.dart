import 'package:portea_client/portea_client.dart';

abstract class IKennelRepository {
  Future<Kennel?> getKennel();
  Future<Kennel> createKennel(Kennel kennel);
  Future<void> updateKennel(Kennel kennel);

  /// Updates the breeder (owner) info of the authenticated user's kennel:
  /// `ownerName`, `ownerAddress`, `ownerPhone`, `ownerEmail` and `siret`.
  ///
  /// Mirrors the dedicated server endpoint (F09 prerequisite). All params are
  /// optional and REPLACEMENT in semantics: a field left empty (or null) is
  /// erased on the row, not preserved. The server validates email shape and
  /// SIRET (14 digits) and raises [InvalidKennelInputException] otherwise.
  ///
  /// Returns the fresh kennel row.
  Future<Kennel> updateKennelOwnerInfo({
    String? ownerName,
    String? ownerAddress,
    String? ownerPhone,
    String? ownerEmail,
    String? siret,
  });
}
