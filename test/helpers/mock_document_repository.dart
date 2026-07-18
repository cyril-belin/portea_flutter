import 'dart:typed_data';

import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/features/settings/domain/repositories/i_document_repository.dart';

/// In-memory mock document repository for unit tests.
///
/// Records every call so the view-model tests can assert that the attestation
/// path uploads AFTER generating, and that the registry path NEVER uploads.
/// The upload handler is injectable so a test can simulate a server refusal
/// ([IncompleteCessionDataException]) or a transport error without spinning
/// up a real server.
class MockDocumentRepository implements IDocumentRepository {
  MockDocumentRepository({this.uploadHandler});

  /// Injected upload behavior. Defaults to a plain success that returns a
  /// fresh [IssuedDocument] with an incrementing id. Set this to throw an
  /// exception to simulate a server refusal.
  IssuedDocument Function(int puppyId, ByteData bytes)? uploadHandler;

  final List<UploadedCall> uploadCalls = [];
  final List<int> getIssuedCalls = [];
  final List<int> downloadCalls = [];

  int _nextId = 1;
  final Map<int, List<IssuedDocument>> _storage = {};

  @override
  Future<IssuedDocument> uploadCessionPdf(int puppyId, ByteData bytes) async {
    uploadCalls.add(UploadedCall(puppyId: puppyId, bytes: bytes));
    if (uploadHandler != null) {
      final doc = uploadHandler!(puppyId, bytes);
      _storage.putIfAbsent(puppyId, () => []).insert(0, doc);
      return doc;
    }
    final doc = IssuedDocument(
      id: _nextId++,
      puppyId: puppyId,
      storagePath:
          'cessions/1/$puppyId/${DateTime.now().toIso8601String()}.pdf',
      issuedAt: DateTime.now().toUtc(),
    );
    _storage.putIfAbsent(puppyId, () => []).insert(0, doc);
    return doc;
  }

  @override
  Future<List<IssuedDocument>> getIssuedDocuments(int puppyId) async {
    getIssuedCalls.add(puppyId);
    return List.unmodifiable(_storage[puppyId] ?? const []);
  }

  @override
  Future<ByteData?> downloadCessionPdf(int documentId) async {
    downloadCalls.add(documentId);
    // Walk the storage to find the doc — the tests assert bytes round-trip.
    for (final list in _storage.values) {
      for (final doc in list) {
        if (doc.id == documentId) {
          return ByteData(8);
        }
      }
    }
    return null;
  }

  void reset() {
    uploadCalls.clear();
    getIssuedCalls.clear();
    downloadCalls.clear();
    _storage.clear();
    _nextId = 1;
  }
}

class UploadedCall {
  final int puppyId;
  final ByteData bytes;

  UploadedCall({required this.puppyId, required this.bytes});
}
