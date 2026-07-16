import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_litter_repository.dart';
import '../../../breeders/domain/repositories/i_breeder_repository.dart';

/// Outcome of a litter declaration attempt.
///
/// The screen turns `activeLimitReached` into a navigation to `/premium`. Any
/// other failure is surfaced as a normal error message — the paywall is never
/// triggered on a generic error.
enum LitterDeclarationOutcome { success, activeLimitReached, error }

/// Result of [LitterDeclarationViewModel.declareLitter].
class LitterDeclarationResult {
  LitterDeclarationResult({
    required this.outcome,
    this.litter,
    this.errorMessage,
  });

  final LitterDeclarationOutcome outcome;

  /// The created litter, only set when [outcome] is `success`.
  final Litter? litter;

  /// Human-readable message, set for `activeLimitReached` and `error`.
  final String? errorMessage;
}

class LitterDeclarationViewModel extends ChangeNotifier {
  LitterDeclarationViewModel({
    required ILitterRepository litterRepository,
    required IBreederRepository breederRepository,
  }) : _litterRepository = litterRepository,
       _breederRepository = breederRepository;

  final ILitterRepository _litterRepository;
  final IBreederRepository _breederRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Breeder> _mothers = [];
  List<Breeder> get mothers => _mothers;

  List<Breeder> _fathers = [];
  List<Breeder> get fathers => _fathers;

  Future<void> loadBreedersForDeclaration() async {
    _isLoading = true;
    notifyListeners();

    try {
      final all = await _breederRepository.getBreeders();
      _mothers = all
          .where((b) => b.sex == 'female' && b.status == 'active')
          .toList();
      _fathers = all
          .where((b) => b.sex == 'male' && b.status == 'active')
          .toList();
    } catch (_) {
      // Ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Declares a new litter.
  ///
  /// The `kennelId` is never trusted by the server (derived from the session),
  /// so a sentinel `0` is sent here. The previous active litter is NEVER
  /// silently deactivated — closure is a manual action. When the kennel is not
  /// premium and already has an active litter, the server raises an
  /// [ActiveLitterLimitException], surfaced here as
  /// [LitterDeclarationOutcome.activeLimitReached] so the screen can open the
  /// paywall rather than showing a generic error.
  Future<LitterDeclarationResult> declareLitter({
    required int motherId,
    int? fatherId,
    String? externalSireName,
    String? externalSireId,
    required DateTime birthDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newLitter = Litter(
        motherId: motherId,
        fatherId: fatherId,
        externalSireName: externalSireName?.trim().isEmpty ?? true
            ? null
            : externalSireName!.trim(),
        externalSireId: externalSireId?.trim().isEmpty ?? true
            ? null
            : externalSireId!.trim(),
        birthDate: birthDate,
        kennelId:
            0, // sentinel — the server derives the real kennel from the session
        isActive: true,
      );

      final created = await _litterRepository.createLitter(newLitter);
      return LitterDeclarationResult(
        outcome: LitterDeclarationOutcome.success,
        litter: created,
      );
    } on ActiveLitterLimitException catch (e) {
      return LitterDeclarationResult(
        outcome: LitterDeclarationOutcome.activeLimitReached,
        errorMessage: e.message,
      );
    } catch (e) {
      return LitterDeclarationResult(
        outcome: LitterDeclarationOutcome.error,
        errorMessage: 'Impossible de déclarer la portée. Veuillez réessayer.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
