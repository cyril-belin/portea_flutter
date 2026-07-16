import 'package:portea_client/portea_client.dart';

import '../../domain/repositories/i_breeder_repository.dart';

/// Breeder repository backed by the Serverpod `breeder` endpoint.
///
/// The kennel scoping is enforced server-side — the client never passes a
/// kennelId. See `BreederEndpoint` for the authorization guarantees.
class ServerpodBreederRepository implements IBreederRepository {
  ServerpodBreederRepository(this._client);

  final Client _client;

  @override
  Future<List<Breeder>> getBreeders() async {
    return _client.breeder.getBreeders();
  }

  @override
  Future<Breeder?> getBreeder(int id) async {
    return _client.breeder.getBreeder(id);
  }

  @override
  Future<Breeder> createBreeder(Breeder breeder) async {
    return _client.breeder.createBreeder(breeder);
  }

  @override
  Future<void> updateBreeder(Breeder breeder) async {
    await _client.breeder.updateBreeder(breeder);
  }
}
