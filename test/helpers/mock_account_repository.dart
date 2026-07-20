import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/features/settings/domain/repositories/i_account_repository.dart';

/// Test double for [IAccountRepository]. Records every call in the order it
/// was made, so tests can assert on the exact sequence (deleteAccount →
/// cancelAll → clearLocalState → signOutDevice) — the RGPD ordering rule.
///
/// Failures are injectable: set [deleteAccountError] or [exportMyDataError]
/// to make the corresponding call throw, exercising the failure paths.
class MockAccountRepository implements IAccountRepository {
  /// Ordered log of method names invoked on the repository. Tests assert
  /// against this list (e.g. `expect(repo.calls, ['deleteAccount',
  /// 'signOutDevice'])`).
  final List<String> calls = [];

  /// Optional error to throw on the next `deleteAccount`. Cleared after use.
  Object? deleteAccountError;

  /// Optional error to throw on the next `exportMyData`. Cleared after use.
  Object? exportMyDataError;

  /// Optional error to throw on `signOutDevice`. Defaults to none — the
  /// real session manager swallows signOut errors in its `finally` block,
  /// and we want the mock to mirror that happy posture by default.
  Object? signOutDeviceError;

  /// The payload returned by `exportMyData`. Defaults to an empty export.
  KennelDataExport exportPayload = KennelDataExport(
    exportedAt: DateTime.utc(2026, 7, 20),
    kennel: Kennel(
      name: 'Élevage Test',
      species: 'dog',
      createdAt: DateTime(2026, 1, 1),
    ),
    breeders: const [],
    litters: const [],
    puppies: const [],
    weighings: const [],
    careEntries: const [],
    issuedDocuments: const [],
  );

  @override
  Future<void> deleteAccount() async {
    calls.add('deleteAccount');
    final error = deleteAccountError;
    deleteAccountError = null;
    if (error != null) throw error;
  }

  @override
  Future<KennelDataExport> exportMyData() async {
    calls.add('exportMyData');
    final error = exportMyDataError;
    exportMyDataError = null;
    if (error != null) throw error;
    return exportPayload;
  }

  @override
  Future<bool> signOutDevice() async {
    calls.add('signOutDevice');
    final error = signOutDeviceError;
    signOutDeviceError = null;
    if (error != null) throw error;
    return true;
  }

  /// Clears the call log between tests.
  void reset() {
    calls.clear();
    deleteAccountError = null;
    exportMyDataError = null;
    signOutDeviceError = null;
  }
}
