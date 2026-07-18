import 'package:flutter/foundation.dart';
import 'package:portea_client/portea_client.dart';
import 'package:printing/printing.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../../../core/pdf/cession_template.dart';
import '../../../../core/pdf/registre_template.dart';
import '../../../breeders/domain/repositories/i_breeder_repository.dart';
import '../../../litters/domain/repositories/i_litter_repository.dart';
import '../../../onboarding/domain/repositories/i_kennel_repository.dart';
import '../../../puppies/domain/repositories/i_puppy_repository.dart';
import '../../domain/repositories/i_document_repository.dart';
import '../../domain/repositories/i_settings_repository.dart';

/// View model driving the F09 Documents screen and the puppy-file "documents
/// émis" section.
///
/// Two documents are produced here, both gated PREMIUM on the client (the
/// server is NOT the premium authority yet — that is F10; see
/// `doc/review_externe_verdicts.md` claim 3.3):
/// - the ATTESTATION DE CESSION (per sold puppy): generated locally, uploaded
///   to the private Serverpod storage, recorded as an `IssuedDocument`;
/// - the REGISTRE D'ÉLEVAGE (per kennel, all litters): generated locally and
///   shared directly via `Printing.sharePdf()` — never uploaded, never
///   recorded.
///
/// ERROR CHANNEL (review claim 2.1/2.3 — no silent swallowing): every method
/// routes failures through [mapExceptionToMessage] and exposes them via
/// [errorMessage] with [OperationState.error]. The attestation path is
/// strictly honest about success: the snackbar fires ONLY after the server
/// has confirmed the upload and returned an `IssuedDocument` — never on a
/// local-only generation (verdict 2.2, the stub-AlertDialog bug).
///
/// DOUBLE-SUBMIT GUARD (review claim 2.3): every mutation is ignored while
/// another is in flight (`_state == OperationState.mutating`).
class DocumentsViewModel extends ChangeNotifier {
  DocumentsViewModel({
    required IKennelRepository kennelRepository,
    required ILitterRepository litterRepository,
    required IPuppyRepository puppyRepository,
    required IBreederRepository breederRepository,
    required IDocumentRepository documentRepository,
    required ISettingsRepository settingsRepository,
  }) : _kennelRepository = kennelRepository,
       _litterRepository = litterRepository,
       _puppyRepository = puppyRepository,
       _breederRepository = breederRepository,
       _documentRepository = documentRepository,
       _settingsRepository = settingsRepository;

  final IKennelRepository _kennelRepository;
  final ILitterRepository _litterRepository;
  final IPuppyRepository _puppyRepository;
  final IBreederRepository _breederRepository;
  final IDocumentRepository _documentRepository;
  final ISettingsRepository _settingsRepository;

  OperationState _state = OperationState.idle;
  OperationState get state => _state;

  bool get isBusy =>
      _state == OperationState.loading ||
      _state == OperationState.refreshing ||
      _state == OperationState.mutating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Kennel? _kennel;
  Kennel? get kennel => _kennel;

  Litter? _litter;
  Litter? get litter => _litter;

  List<Puppy> _puppies = [];
  // Claim 2.6: never expose the mutable backing list.
  List<Puppy> get puppies => List.unmodifiable(_puppies);

  /// The dam of the loaded litter — used to derive the breed on the
  /// attestation (puppies have no breed field; they inherit the mother's).
  Breeder? _mother;
  Breeder? get mother => _mother;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  /// Per-puppy list of emitted attestations, keyed by puppyId. Populated
  /// lazily by [loadIssuedDocuments] for the puppy-file section. Empty until
  /// loaded.
  final Map<int, List<IssuedDocument>> _documentsByPuppy = {};
  List<IssuedDocument> documentsFor(int puppyId) =>
      List.unmodifiable(_documentsByPuppy[puppyId] ?? const []);

  /// Loads the data needed to render both documents for [litterId]:
  /// the kennel, the litter, its puppies, and the dam (for the breed).
  /// Also refreshes the premium flag (client-side gating — see class doc).
  ///
  /// Existing data is preserved during a refresh (the screen does not blank
  /// out on reload — review claim 2.3).
  Future<void> loadDocumentData(int litterId) async {
    final hasData = _kennel != null && _litter != null;
    _state = hasData ? OperationState.refreshing : OperationState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _kennelRepository.getKennel(),
        _litterRepository.getLitter(litterId),
        _puppyRepository.getPuppies(litterId),
        _settingsRepository.isPremium(),
      ]);
      _kennel = results[0] as Kennel?;
      _litter = results[1] as Litter?;
      _puppies = results[2] as List<Puppy>;
      _isPremium = results[3] as bool;

      // Resolve the dam (for the breed on the attestation). Optional — a
      // missing mother renders "Non renseignée" on the PDF, not an error.
      if (_litter != null) {
        _mother = await _breederRepository.getBreeder(_litter!.motherId);
      }

      _state = OperationState.success;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Generates the cession attestation PDF for [puppy] and uploads it to the
  /// private Serverpod storage.
  ///
  /// SUCCESS SEMANTICS (verdict 2.2): the caller may only treat the operation
  /// as successful once this future completes with no exception — i.e. the
  /// server has confirmed the upload and returned an `IssuedDocument`. The
  /// local PDF generation step alone is NOT a success signal.
  ///
  /// On failure, [errorMessage] is populated with a mapped French message.
  /// [IncompleteCessionDataException] surfaces the server's verbatim list of
  /// missing dossier fields; [InvalidPuppyRelationException] surfaces the
  /// authorization message; transport errors map to the generic wording.
  ///
  /// Returns the freshly inserted [IssuedDocument] on success (the caller can
  /// use it to refresh the puppy-file section without a re-fetch).
  Future<IssuedDocument?> generateCessionPdf(Puppy puppy) async {
    if (_state == OperationState.mutating) return null;
    if (_kennel == null || _litter == null) {
      _errorMessage = 'Les données de l\'élevage ne sont pas chargées.';
      _state = OperationState.error;
      notifyListeners();
      return null;
    }

    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Generate the PDF locally from already-loaded data. No network.
      final bytes = await buildCessionPdf(
        kennel: _kennel!,
        litter: _litter!,
        puppy: puppy,
        mother: _mother,
      );
      // 2. Upload — the server validates the dossier and stores. The success
      //    snackbar is keyed on the RETURN of this call, never on step 1.
      final byteData = ByteData.sublistView(bytes);
      final doc = await _documentRepository.uploadCessionPdf(
        puppy.id!,
        byteData,
      );
      // 3. Update the in-memory cache so the puppy-file section reflects the
      //    new emission immediately (no reload needed).
      final list = List<IssuedDocument>.from(_documentsByPuppy[puppy.id] ?? []);
      list.insert(0, doc);
      _documentsByPuppy[puppy.id!] = list;
      _state = OperationState.success;
      notifyListeners();
      return doc;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
      notifyListeners();
      return null;
    }
  }

  /// Generates the breeding registry PDF and shares it via the native share
  /// sheet (iOS share / Android intent).
  ///
  /// NO upload, NO `IssuedDocument` row — the registry is regenerated on
  /// demand from the current state of the kennel. This call does NOT mutate
  /// `_state` to `mutating` for the full duration: the generation is local
  /// and the share sheet is user-paced, so blocking the UI on it would be
  /// wrong. Errors during generation still surface via [errorMessage].
  ///
  /// Returns true if the share sheet was invoked successfully.
  Future<bool> generateRegistrePdf() async {
    if (_kennel == null) {
      _errorMessage = 'Les données de l\'élevage ne sont pas chargées.';
      _state = OperationState.error;
      notifyListeners();
      return false;
    }

    try {
      // The registry spans ALL litters of the kennel, not just the loaded
      // one. Fetch them fresh (the loadDocumentData call only loaded the
      // current litter for the attestation).
      final litters = await _litterRepository.getLitters();
      final mothers = <int, Breeder?>{};
      final puppiesByLitter = <int, List<Puppy>>{};
      for (final litter in litters) {
        // Resolve each unique dam once. A missing breeder stores null — the
        // template renders "Mère inconnue" in that case.
        if (!mothers.containsKey(litter.motherId)) {
          mothers[litter.motherId] = await _breederRepository.getBreeder(
            litter.motherId,
          );
        }
        puppiesByLitter[litter.id!] = await _puppyRepository.getPuppies(
          litter.id!,
        );
      }

      final bytes = await buildRegistrePdf(
        kennel: _kennel!,
        litters: litters,
        mothers: mothers,
        puppiesByLitter: puppiesByLitter,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'registre-elevage-${DateTime.now().toIso8601String()}.pdf',
      );
      return true;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
      notifyListeners();
      return false;
    }
  }

  /// Loads the emitted attestations for [puppyId] (puppy-file section).
  /// Preserves previously-loaded data on refresh — no blank state.
  Future<void> loadIssuedDocuments(int puppyId) async {
    try {
      _documentsByPuppy[puppyId] = await _documentRepository.getIssuedDocuments(
        puppyId,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
      notifyListeners();
    }
  }

  /// Opens (shares) a previously emitted attestation. Fetches the bytes from
  /// the private storage via the authenticated endpoint and hands them to
  /// the native share sheet.
  ///
  /// Returns true if the share sheet was invoked successfully. A null byte
  /// response (storage drift) surfaces as an error message rather than a
  /// silent no-op.
  Future<bool> openIssuedDocument(int documentId) async {
    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      final bytes = await _documentRepository.downloadCessionPdf(documentId);
      if (bytes == null) {
        _errorMessage =
            'Le fichier est introuvable sur le serveur (peut-être supprimé).';
        _state = OperationState.error;
        notifyListeners();
        return false;
      }
      await Printing.sharePdf(
        bytes: bytes.buffer.asUint8List(),
        filename: 'attestation-cession-$documentId.pdf',
      );
      _state = OperationState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
      notifyListeners();
      return false;
    }
  }
}
