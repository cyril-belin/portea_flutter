import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../domain/repositories/i_care_repository.dart';

/// View model for the add-care form.
///
/// Handles the two paths from the F06 spec:
/// - group care (the whole litter): a SINGLE call to
///   [ICareRepository.addGroupCare] — the server builds the parent entry
///   (litterId, reminderAt) and one child per puppy (puppyId, reminderAt
///   null) in one transaction;
/// - individual care (one puppy): a single call to
///   [ICareRepository.addCareEntry], where reminderAt lands on the puppy's
///   own entry.
///
/// This rewrite removes the old client-side loop (review claim 4.3): it
/// created entries one by one AND copied reminderAt onto every child, which
/// would have spammed N identical notifications once F07 schedules per
/// non-null reminderAt. The server is now the authority — the contract
/// (`addGroupCare` takes individual params) makes a client-side reminderAt on
/// children impossible by construction.
///
/// Error handling follows the project-wide pattern: the catch maps the
/// exception via [mapExceptionToMessage], stores it in [errorMessage], and
/// sets [state] to [OperationState.error]. The typed care exceptions
/// (`InvalidCareRelationException`, `InvalidCareInputException`) are mapped to
/// their French business message; everything else falls through to the
/// mapper's transport/generic branches.
class AddCareViewModel extends ChangeNotifier {
  AddCareViewModel({required ICareRepository careRepository})
    : _careRepository = careRepository;

  final ICareRepository _careRepository;

  OperationState _state = OperationState.idle;
  OperationState get state => _state;

  bool get isBusy =>
      _state == OperationState.loading ||
      _state == OperationState.refreshing ||
      _state == OperationState.mutating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Saves a care entry. Returns true on success, false on error (with
  /// [errorMessage] populated). Mutations are ignored while another mutation
  /// is in flight (double-submit guard).
  ///
  /// [targetAllLitter] + [litterId] → group care (single `addGroupCare`).
  /// Otherwise → individual care (single `addCareEntry`).
  Future<bool> saveCareEntry({
    required String type, // 'vaccine' | 'deworming' | 'other'
    required String product,
    required DateTime date,
    int? puppyId,
    int? litterId,
    bool targetAllLitter = false,
    DateTime? reminderDate,
    String? notes,
  }) async {
    if (_state == OperationState.mutating) return false;
    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      if (targetAllLitter && litterId != null) {
        // Group care — one call. The server builds the parent (litterId +
        // reminderAt) and one child per puppy (puppyId + reminderAt null) in
        // a single transaction. No client-side loop, no reminderAt on
        // children — the central F06 rule.
        await _careRepository.addGroupCare(
          litterId: litterId,
          type: type,
          product: product,
          appliedAt: date,
          reminderAt: reminderDate,
          notes: notes,
        );
      } else {
        // Individual care: reminderAt lands directly on the puppy's own entry
        // (no parent — there is no group).
        await _careRepository.addCareEntry(
          CareEntry(
            type: type,
            product: product,
            appliedAt: date,
            puppyId: puppyId,
            reminderAt: reminderDate,
            notes: notes,
          ),
        );
      }
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
