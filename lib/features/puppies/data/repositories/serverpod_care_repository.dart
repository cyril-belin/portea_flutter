import 'package:portea_client/portea_client.dart';

import '../../domain/repositories/i_care_repository.dart';

/// Care repository backed by the Serverpod `care` endpoint.
///
/// Kennel scoping is enforced server-side — the client never passes a
/// kennelId. Authorization is anchored on the `puppyId` (individual care) or
/// `litterId` (group care) of each entry (the server resolves puppy → litter
/// → kennel and rejects any forged or cross-kennel id with a typed
/// [InvalidCareRelationException]). Payload validation (type enum, non-future
/// appliedAt, reminderAt strictly after appliedAt, non-blank product) is also
/// server-side and raises [InvalidCareInputException]. See `CareEndpoint` for
/// the full authorization, validation and transactional guarantees.
///
/// THE CENTRAL RULE (review claim 4.3 + F06 spec): [addGroupCare] takes
/// individual params — the client CANNOT pass a reminderAt per child, so the
/// invariant "children never carry a reminderAt" is enforced by construction.
/// Individual care routes through [addCareEntry], where reminderAt lands on
/// the puppy's own entry.
class ServerpodCareRepository implements ICareRepository {
  ServerpodCareRepository(this._client);

  final Client _client;

  @override
  Future<List<CareEntry>> getCareEntries({int? puppyId, int? litterId}) {
    // Dispatch to the matching server getter. Exactly one of the two params
    // is expected; if both/neither are set we surface it as a programming
    // error rather than silently hitting the wrong endpoint.
    if (puppyId != null) {
      return _client.care.getCareEntries(puppyId);
    }
    if (litterId != null) {
      return _client.care.getLitterCareEntries(litterId);
    }
    throw ArgumentError(
      'getCareEntries requires exactly one of puppyId or litterId',
    );
  }

  @override
  Future<CareEntry> addCareEntry(CareEntry entry) {
    return _client.care.addCareEntry(entry);
  }

  @override
  Future<List<CareEntry>> addGroupCare({
    required int litterId,
    required String type,
    String? product,
    required DateTime appliedAt,
    DateTime? reminderAt,
    String? notes,
  }) {
    return _client.care.addGroupCare(
      litterId,
      type,
      product,
      appliedAt,
      reminderAt,
      notes,
    );
  }

  @override
  Future<List<CareEntry>> getUpcomingReminders(int limit) {
    return _client.care.getUpcomingReminders(limit);
  }
}
