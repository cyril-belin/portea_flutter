import 'package:portea_client/portea_client.dart';

import '../../domain/repositories/i_puppy_repository.dart';

/// Puppy repository backed by the Serverpod `puppy` endpoint.
///
/// Kennel scoping is enforced server-side — the client never passes a
/// kennelId. The `litterId` is always provided explicitly to
/// [savePuppiesBatch] (it is the authorization anchor); the `litterId` carried
/// by individual [Puppy] items is ignored by the server, which enforces the
/// route's `litterId`. See `PuppyEndpoint` for the authorization, anti-forge
/// and transactional guarantees.
class ServerpodPuppyRepository implements IPuppyRepository {
  ServerpodPuppyRepository(this._client);

  final Client _client;

  @override
  Future<List<Puppy>> getPuppies(int litterId) {
    return _client.puppy.getPuppies(litterId);
  }

  @override
  Future<Puppy?> getPuppy(int id) {
    return _client.puppy.getPuppy(id);
  }

  @override
  Future<Puppy> createPuppy(Puppy puppy) {
    // Single-row creation is not exposed by the endpoint (F04 uses the batch
    // path exclusively). Kept for interface completeness and future use.
    throw UnimplementedError(
      'Single puppy creation is not supported — use savePuppiesBatch.',
    );
  }

  @override
  Future<void> updatePuppy(Puppy puppy) {
    // Same rationale as createPuppy: the batch path is the only write surface.
    throw UnimplementedError(
      'Single puppy update is not supported — use savePuppiesBatch.',
    );
  }

  @override
  Future<List<Puppy>> savePuppiesBatch(int litterId, List<Puppy> items) {
    return _client.puppy.savePuppiesBatch(litterId, items);
  }
}
