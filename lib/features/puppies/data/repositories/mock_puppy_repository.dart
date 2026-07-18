import 'package:portea_client/portea_client.dart';
import '../../../../core/data/mock_database.dart';
import '../../domain/repositories/i_puppy_repository.dart';

class MockPuppyRepository implements IPuppyRepository {
  final _db = MockDatabase.instance;

  /// When non-null, the next repository call throws this. Consumed on first
  /// call, then reset to null.
  Object? throwOnNext;

  Future<void> _maybeThrow() async {
    final pending = throwOnNext;
    if (pending != null) {
      throwOnNext = null;
      throw pending;
    }
  }

  /// Same enum and format checks as the server (leçon F06: the mock enforces
  /// the same rules so view-model unit tests exercise the real flow).
  static const _validStatuses = {'available', 'reserved', 'sold'};

  static final _emailRegExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  String? _normalizeOptional(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _validateBuyerFields({String? email, String? phone}) {
    final e = _normalizeOptional(email);
    if (e != null && !_emailRegExp.hasMatch(e)) {
      throw InvalidPuppyInputException(
        message: "L'adresse e-mail de l'acquéreur n'est pas valide.",
      );
    }
    final p = _normalizeOptional(phone);
    if (p != null) {
      final digits = p.replaceAll(RegExp(r'[\s.\-()]'), '');
      final bare = digits.replaceFirst(RegExp(r'^(?:\+33|0033|0)'), '');
      if (!RegExp(r'^[0-9]{9}$').hasMatch(bare)) {
        throw InvalidPuppyInputException(
          message: "Le numéro de téléphone de l'acquéreur n'est pas valide.",
        );
      }
    }
  }

  @override
  Future<List<Puppy>> getPuppies(int litterId) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_db.puppies.where((p) => p.litterId == litterId));
  }

  @override
  Future<Puppy?> getPuppy(int id) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _db.puppies.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Puppy> createPuppy(Puppy puppy) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 150));
    final newId = _db.puppies.isEmpty
        ? 1
        : _db.puppies.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    final created = Puppy(
      id: newId,
      litterId: puppy.litterId,
      name: puppy.name,
      sex: puppy.sex,
      color: puppy.color,
      status: puppy.status,
      chipNumber: puppy.chipNumber,
      birthWeight: puppy.birthWeight,
      photoUrl: puppy.photoUrl,
      buyerName: puppy.buyerName,
      buyerPhone: puppy.buyerPhone,
      buyerEmail: puppy.buyerEmail,
      buyerAddress: puppy.buyerAddress,
    );
    _db.puppies.add(created);
    return created;
  }

  @override
  Future<void> updatePuppy(Puppy puppy) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _db.puppies.indexWhere((p) => p.id == puppy.id);
    if (idx != -1) {
      _db.puppies[idx] = puppy;
    }
  }

  /// Mock implementation of the idempotent batch save, mirroring the server
  /// semantics so unit tests on the view model exercise the real flow.
  ///
  /// Note: the deletion guard (history blocks delete) is trivially true here,
  /// matching the server in F04 — the weighing/care tables are mock-only and
  /// not checked. See F05/F06.
  @override
  Future<List<Puppy>> savePuppiesBatch(int litterId, List<Puppy> items) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 250));

    // Remove puppies of this litter that are absent from the payload.
    final keptIds = items.where((p) => p.id != null).map((p) => p.id!).toSet();
    _db.puppies.removeWhere(
      (p) => p.litterId == litterId && !keptIds.contains(p.id),
    );

    // Insert new puppies (id null), update existing ones (id present).
    for (final item in items) {
      if (item.id == null) {
        await createPuppy(
          Puppy(
            litterId: litterId,
            name: item.name,
            sex: item.sex,
            color: item.color,
            status: item.status,
            chipNumber: item.chipNumber,
            birthWeight: item.birthWeight,
            photoUrl: item.photoUrl,
            buyerName: item.buyerName,
            buyerPhone: item.buyerPhone,
            buyerEmail: item.buyerEmail,
            buyerAddress: item.buyerAddress,
          ),
        );
      } else {
        await updatePuppy(
          Puppy(
            id: item.id,
            litterId: litterId,
            name: item.name,
            sex: item.sex,
            color: item.color,
            status: item.status,
            chipNumber: item.chipNumber,
            birthWeight: item.birthWeight,
            photoUrl: item.photoUrl,
            buyerName: item.buyerName,
            buyerPhone: item.buyerPhone,
            buyerEmail: item.buyerEmail,
            buyerAddress: item.buyerAddress,
          ),
        );
      }
    }

    return getPuppies(litterId);
  }

  /// Mock mirror of `PuppyEndpoint.updatePuppyStatus`. Applies the SAME rules
  /// (leçon F06): enum validation, conservation on `available`, MERGE of
  /// provided buyer* on `reserved`/`sold`, `sold` requires a buyerName
  /// (provided or already stored), cessionDate default today on first `sold`,
  /// email/phone format checks. The anti-forge/cross-kennel checks are moot
  /// here (single-tenant in-memory db) but kept conceptually: a nonexistent
  /// puppyId throws [InvalidPuppyRelationException].
  @override
  Future<Puppy> updatePuppyStatus(
    int puppyId,
    String status, {
    String? buyerName,
    String? buyerPhone,
    String? buyerEmail,
    String? buyerAddress,
    DateTime? cessionDate,
  }) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 150));

    if (!_validStatuses.contains(status)) {
      throw InvalidPuppyInputException(
        message: 'Le statut doit être available, reserved ou sold.',
      );
    }

    final idx = _db.puppies.indexWhere((p) => p.id == puppyId);
    if (idx == -1) {
      throw InvalidPuppyRelationException(
        message: 'Le chiot visé est introuvable.',
      );
    }
    final puppy = _db.puppies[idx];

    if (status == 'available') {
      // Conservation: write status only, preserve buyer* and cessionDate.
      final updated = puppy.copyWith(status: status);
      _db.puppies[idx] = updated;
      return updated;
    }

    final normalizedEmail = _normalizeOptional(buyerEmail);
    final normalizedPhone = _normalizeOptional(buyerPhone);
    _validateBuyerFields(email: normalizedEmail, phone: normalizedPhone);

    final mergedName = _normalizeOptional(buyerName) ?? puppy.buyerName;
    final mergedPhone = normalizedPhone ?? puppy.buyerPhone;
    final mergedEmail = normalizedEmail ?? puppy.buyerEmail;
    final mergedAddress =
        _normalizeOptional(buyerAddress) ?? puppy.buyerAddress;

    if (status == 'sold') {
      if (mergedName == null) {
        throw InvalidPuppyInputException(
          message: "Le nom de l'acquéreur est obligatoire pour un chiot vendu.",
        );
      }
      final effectiveCession =
          cessionDate ?? puppy.cessionDate ?? DateTime.now();
      final updated = puppy.copyWith(
        status: status,
        buyerName: mergedName,
        buyerPhone: mergedPhone,
        buyerEmail: mergedEmail,
        buyerAddress: mergedAddress,
        cessionDate: effectiveCession,
      );
      _db.puppies[idx] = updated;
      return updated;
    }

    // reserved — preserve cessionDate (copyWith leaves it untouched).
    final updated = puppy.copyWith(
      status: status,
      buyerName: mergedName,
      buyerPhone: mergedPhone,
      buyerEmail: mergedEmail,
      buyerAddress: mergedAddress,
    );
    _db.puppies[idx] = updated;
    return updated;
  }
}
