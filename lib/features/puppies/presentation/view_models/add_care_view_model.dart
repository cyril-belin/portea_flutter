import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../domain/repositories/i_puppy_repository.dart';
import '../../domain/repositories/i_care_repository.dart';

class AddCareViewModel extends ChangeNotifier {
  final IPuppyRepository _puppyRepository;
  final ICareRepository _careRepository;

  AddCareViewModel({
    required IPuppyRepository puppyRepository,
    required ICareRepository careRepository,
  }) : _puppyRepository = puppyRepository,
       _careRepository = careRepository;

  OperationState _state = OperationState.idle;
  OperationState get state => _state;

  bool get isBusy =>
      _state == OperationState.loading ||
      _state == OperationState.refreshing ||
      _state == OperationState.mutating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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
        // Find all puppies in the litter and add care entries for each
        final puppies = await _puppyRepository.getPuppies(litterId);

        // Also save a main litter care entry
        final groupEntry = CareEntry(
          type: type,
          product: product,
          appliedAt: date,
          litterId: litterId,
          reminderAt: reminderDate,
          notes: notes,
        );
        await _careRepository.addCareEntry(groupEntry);

        for (final p in puppies) {
          final puppyEntry = CareEntry(
            type: type,
            product: product,
            appliedAt: date,
            puppyId: p.id!,
            reminderAt: reminderDate,
            notes: notes,
          );
          await _careRepository.addCareEntry(puppyEntry);
        }
      } else {
        // Individual care entry
        final entry = CareEntry(
          type: type,
          product: product,
          appliedAt: date,
          puppyId: puppyId,
          litterId: litterId,
          reminderAt: reminderDate,
          notes: notes,
        );
        await _careRepository.addCareEntry(entry);
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
