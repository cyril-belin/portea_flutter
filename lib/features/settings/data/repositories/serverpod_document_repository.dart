import 'dart:typed_data';

import 'package:portea_client/portea_client.dart';

import '../../domain/repositories/i_document_repository.dart';

/// Document repository backed by the Serverpod `document` endpoint (F09).
///
/// Kennel scoping is enforced server-side — the client never passes a
/// kennelId. See `IDocumentRepository` for the storage model and
/// `DocumentEndpoint` for the authorization guarantees.
class ServerpodDocumentRepository implements IDocumentRepository {
  ServerpodDocumentRepository(this._client);

  final Client _client;

  @override
  Future<IssuedDocument> uploadCessionPdf(int puppyId, ByteData bytes) {
    return _client.document.uploadCessionPdf(puppyId, bytes);
  }

  @override
  Future<List<IssuedDocument>> getIssuedDocuments(int puppyId) {
    return _client.document.getIssuedDocuments(puppyId);
  }

  @override
  Future<ByteData?> downloadCessionPdf(int documentId) {
    return _client.document.downloadCessionPdf(documentId);
  }
}
