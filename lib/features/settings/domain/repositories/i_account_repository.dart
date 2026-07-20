import 'package:portea_client/portea_client.dart';

/// Account repository contract — RGPD right to erasure (article 17) and data
/// portability (article 20).
///
/// The deleted/exported account is ALWAYS the authenticated session's — never
/// an id passed from the caller. The server endpoint derives ownership from
/// the session, mirroring every other repository here.
///
/// `signOutDevice` is exposed here (not in a separate auth service) because
/// post-deletion sign-out is logically part of the account lifecycle: a
/// successful `deleteAccount` MUST be followed by clearing the local auth
/// state, and the ViewModel needs to call them in the right order (see
/// `SettingsViewModel.deleteAccount`).
abstract class IAccountRepository {
  /// Irreversibly deletes the authenticated user's account and ALL its data
  /// on the server. Returns normally on success; raises on failure. The
  /// absence of an exception IS the success signal.
  ///
  /// The server wipes every kennel-scoped table in a single transaction,
  /// cascades through the auth user (refresh tokens, sessions, providers),
  /// and purges the private storage best-effort — see
  /// `AccountEndpoint.deleteAccount` for the exact ordering and the
  /// rationale on storage cleanup.
  Future<void> deleteAccount();

  /// Exports every structured row owned by the session's kennel as a single
  /// [KennelDataExport] payload (article 20). PDF bytes are excluded — the
  /// attestations remain reachable through `DocumentEndpoint` for as long
  /// as the account exists.
  Future<KennelDataExport> exportMyData();

  /// Signs the user out from THIS device. Post-deletion this is a best-effort
  /// call: the server may have already invalidated the session (AuthUser
  /// cascade), in which case the call returns false but STILL clears the
  /// local auth state — that is the behaviour we rely on to leave the client
  /// in a clean logged-out state after `deleteAccount`.
  Future<bool> signOutDevice();
}
