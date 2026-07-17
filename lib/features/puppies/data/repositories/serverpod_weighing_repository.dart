import 'package:portea_client/portea_client.dart';

import '../../domain/repositories/i_weighing_repository.dart';

/// Weighing repository backed by the Serverpod `weighing` endpoint.
///
/// Kennel scoping is enforced server-side — the client never passes a
/// kennelId. Authorization is anchored on the `puppyId` of each entry (the
/// server resolves puppy → litter → kennel and rejects any forged or
/// cross-kennel puppyId with a typed [InvalidWeighingRelationException]).
/// Payload validation (weightGrams > 0, non-future date) is also server-side
/// and raises [InvalidWeighingInputException]. See `WeighingEndpoint` for the
/// full authorization, validation and transactional guarantees.
class ServerpodWeighingRepository implements IWeighingRepository {
  ServerpodWeighingRepository(this._client);

  final Client _client;

  @override
  Future<List<WeighingEntry>> getWeighings(int puppyId) {
    return _client.weighing.getWeighings(puppyId);
  }

  @override
  Future<WeighingEntry> addWeighing(WeighingEntry entry) {
    return _client.weighing.addWeighing(entry);
  }

  @override
  Future<List<WeighingEntry>> addWeighings(List<WeighingEntry> entries) {
    return _client.weighing.addWeighings(entries);
  }

  @override
  Future<List<PuppyWithLastWeighing>> getPuppiesWithLastWeighing(
    int litterId,
  ) {
    return _client.weighing.getPuppiesWithLastWeighing(litterId);
  }
}
