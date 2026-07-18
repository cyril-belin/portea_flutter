import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_kennel_repository.dart';

class MockKennelRepository implements IKennelRepository {
  Kennel? _kennel;

  /// When non-null, the next repository call throws this. Useful for view
  /// model error-path tests. The flag is consumed on the first call and reset
  /// to null, so only the next single call fails.
  Object? throwOnNext;

  Future<void> _maybeThrow() async {
    final pending = throwOnNext;
    if (pending != null) {
      throwOnNext = null;
      throw pending;
    }
  }

  @override
  Future<Kennel?> getKennel() async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 200));
    return _kennel;
  }

  @override
  Future<Kennel> createKennel(Kennel kennel) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 200));
    _kennel = kennel;
    return kennel;
  }

  @override
  Future<void> updateKennel(Kennel kennel) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 200));
    _kennel = kennel;
  }

  /// Mirrors the server's `updateKennelOwnerInfo` rules, so view-model tests
  /// exercise the same validation as the real endpoint: email shape and SIRET
  /// (14 digits) are checked, every value is trimmed, and empty → null. The
  /// semantics are REPLACEMENT (the form resubmits the whole dossier), so a
  /// cleared field is erased on the mock row, not preserved.
  @override
  Future<Kennel> updateKennelOwnerInfo({
    String? ownerName,
    String? ownerAddress,
    String? ownerPhone,
    String? ownerEmail,
    String? siret,
  }) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 200));

    final normalizedEmail = _normalize(ownerEmail);
    if (normalizedEmail != null &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(normalizedEmail)) {
      throw InvalidKennelInputException(
        message: "L'adresse e-mail de l'éleveur n'est pas valide.",
      );
    }

    final normalizedSiret = _normalize(siret);
    if (normalizedSiret != null &&
        !RegExp(r'^[0-9]{14}$').hasMatch(normalizedSiret)) {
      throw InvalidKennelInputException(
        message: 'Le numéro SIRET doit comporter exactement 14 chiffres.',
      );
    }

    final k = _kennel;
    if (k == null) {
      throw Exception('No kennel found for this user');
    }

    _kennel = k.copyWith(
      ownerName: _normalize(ownerName),
      ownerAddress: _normalize(ownerAddress),
      ownerPhone: _normalize(ownerPhone),
      ownerEmail: normalizedEmail,
      siret: normalizedSiret,
    );
    return _kennel!;
  }

  /// Trims and collapses empty/whitespace-only values to null (mirrors the
  /// server's `_normalizeOptional`).
  String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
