import 'package:portea_client/portea_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../../domain/repositories/i_account_repository.dart';

/// Account repository backed by Serverpod. Thin wrapper around the generated
/// `client.account` endpoint — the auth-sign-out surface is delegated to the
/// client's session manager, which handles the local state cleanup in its
/// `finally` block regardless of the server's response.
class ServerpodAccountRepository implements IAccountRepository {
  ServerpodAccountRepository(this._client);

  final Client _client;

  @override
  Future<void> deleteAccount() => _client.account.deleteAccount();

  @override
  Future<KennelDataExport> exportMyData() => _client.account.exportMyData();

  @override
  Future<bool> signOutDevice() => _client.auth.signOutDevice();
}
