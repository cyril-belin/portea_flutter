import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
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

  OperationState _state = OperationState.idle;
  OperationState get state => _state;

  bool get isBusy =>
      _state == OperationState.loading ||
      _state == OperationState.refreshing ||
      _state == OperationState.mutating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Breeder> _mothers = [];
  // Claim 2.6: never expose the mutable backing list.
  List<Breeder> get mothers => List.unmodifiable(_mothers);

  List<Breeder> _fathers = [];
  // Claim 2.6: never expose the mutable backing list.
  List<Breeder> get fathers => List.unmodifiable(_fathers);

  Future<void> loadBreedersForDeclaration() async {
    _state = OperationState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final all = await _breederRepository.getBreeders();
      _mothers = all
          .where((b) => b.sex == 'female' && b.status == 'active')
          .toList();
      _fathers = all
          .where((b) => b.sex == 'male' && b.status == 'active')
          .toList();
      _state = OperationState.success;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
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
  ///
  /// [ActiveLitterLimitException] is deliberately caught *before* the generic
  /// branch so the mapper never turns the paywall into a SnackBar.
  Future<LitterDeclarationResult> declareLitter({
    required int motherId,
    int? fatherId,
    String? externalSireName,
    String? externalSireId,
    required DateTime birthDate,
  }) async {
    if (_state == OperationState.mutating) {
      return LitterDeclarationResult(
        outcome: LitterDeclarationOutcome.error,
        errorMessage: 'Une déclaration est déjà en cours.',
      );
    }
    _state = OperationState.mutating;
    _errorMessage = null;
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
      _state = OperationState.success;
      return LitterDeclarationResult(
        outcome: LitterDeclarationOutcome.success,
        litter: created,
      );
    } on ActiveLitterLimitException catch (e) {
      // Paywall signal — NOT a generic error. Preserved verbatim.
      _state = OperationState.idle;
      return LitterDeclarationResult(
        outcome: LitterDeclarationOutcome.activeLimitReached,
        errorMessage: e.message,
      );
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.idle;
      return LitterDeclarationResult(
        outcome: LitterDeclarationOutcome.error,
        errorMessage: _errorMessage,
      );
    } finally {
      notifyListeners();
    }
  }
}
