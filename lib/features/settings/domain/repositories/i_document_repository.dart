import 'dart:typed_data';

import 'package:portea_client/portea_client.dart';

/// Document repository — the cession attestation storage surface (F09).
///
/// All methods mirror `DocumentEndpoint`. Kennel scoping is enforced
/// server-side: the client never passes a kennelId. The puppyId /
/// documentId are the authorization anchors — the server re-checks ownership
/// on every call (see `DocumentEndpoint`).
///
/// The two document types have asymmetric storage:
/// - the ATTESTATION is uploaded to the private Serverpod storage and
///   recorded as an `IssuedDocument` (auditable, listed on the puppy file);
/// - the REGISTRY is generated and shared directly (no upload, no record).
/// Only the attestation surfaces go through this repository.
abstract class IDocumentRepository {
  /// Uploads a client-generated cession PDF for [puppyId] to the private
  /// storage. The server validates the puppy is cession-ready BEFORE
  /// accepting a single byte — throws [IncompleteCessionDataException] with
  /// a message enumerating the missing pieces otherwise. Throws
  /// [InvalidPuppyRelationException] for a forged or cross-kennel puppyId.
  /// Returns the freshly inserted [IssuedDocument].
  Future<IssuedDocument> uploadCessionPdf(int puppyId, ByteData bytes);

  /// Lists every cession attestation emitted for [puppyId], most recent
  /// first. Empty list for a puppy with no emission yet (legitimate state).
  Future<List<IssuedDocument>> getIssuedDocuments(int puppyId);

  /// Downloads the bytes of a previously emitted attestation. The only read
  /// path — the storage is private, there is no public URL. Returns null if
  /// the row exists but the underlying file is missing (storage drift — the
  /// UI shows an "unavailable" state). Throws [InvalidPuppyRelationException]
  /// for a forged or cross-kennel documentId.
  Future<ByteData?> downloadCessionPdf(int documentId);
}
