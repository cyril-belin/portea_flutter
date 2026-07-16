import 'package:portea_client/portea_client.dart';

import '../../domain/repositories/i_litter_repository.dart';

/// Litter repository backed by the Serverpod `litter` endpoint.
///
/// The kennel scoping is enforced server-side — the client never passes a
/// kennelId (the `kennelId` field of a newly created [Litter] is ignored by the
/// server, which derives ownership from the session). See `LitterEndpoint` for
/// the authorization and freemium guarantees.
class ServerpodLitterRepository implements ILitterRepository {
  ServerpodLitterRepository(this._client);

  final Client _client;

  @override
  Future<List<Litter>> getLitters() async {
    return _client.litter.getLitters();
  }

  @override
  Future<Litter?> getActiveLitter() async {
    return _client.litter.getActiveLitter();
  }

  @override
  Future<Litter?> getLitter(int id) async {
    return _client.litter.getLitter(id);
  }

  @override
  Future<Litter> createLitter(Litter litter) async {
    return _client.litter.createLitter(litter);
  }

  @override
  Future<void> updateLitter(Litter litter) async {
    await _client.litter.updateLitter(litter);
  }
}
