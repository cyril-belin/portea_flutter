import 'package:portea_client/portea_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/i_kennel_repository.dart';

/// Kennel repository backed by the Serverpod `kennel` endpoint.
///
/// The `kennelId` resolved at login is cached in `SharedPreferences` to avoid
/// a server round-trip on every cold start. This cache is read-only display
/// data — it is NEVER used for authorization (the server derives the kennel
/// from the authenticated session).
class ServerpodKennelRepository implements IKennelRepository {
  ServerpodKennelRepository(this._client);

  final Client _client;

  static const _kennelIdKey = 'cached_kennel_id';

  @override
  Future<Kennel?> getKennel() async {
    final kennel = await _client.kennel.getMyKennel();
    if (kennel?.id != null) {
      await _cacheKennelId(kennel!.id!);
    }
    return kennel;
  }

  @override
  Future<Kennel> createKennel(Kennel kennel) async {
    final created = await _client.kennel.createKennel(kennel);
    await _cacheKennelId(created.id!);
    return created;
  }

  @override
  Future<void> updateKennel(Kennel kennel) async {
    await _client.kennel.updateKennel(kennel);
  }

  @override
  Future<Kennel> updateKennelOwnerInfo({
    String? ownerName,
    String? ownerAddress,
    String? ownerPhone,
    String? ownerEmail,
    String? siret,
  }) async {
    return _client.kennel.updateKennelOwnerInfo(
      ownerName: ownerName,
      ownerAddress: ownerAddress,
      ownerPhone: ownerPhone,
      ownerEmail: ownerEmail,
      siret: siret,
    );
  }

  /// Reads the cached kennel id, or `null` if none has been stored yet.
  /// Display cache only — never used for authorization.
  static Future<int?> getCachedKennelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kennelIdKey);
  }

  Future<void> _cacheKennelId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kennelIdKey, id);
  }
}
