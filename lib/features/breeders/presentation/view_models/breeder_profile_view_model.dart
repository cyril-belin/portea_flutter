import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../domain/repositories/i_breeder_repository.dart';

class BreederProfileViewModel extends ChangeNotifier {
  BreederProfileViewModel({required IBreederRepository breederRepository})
    : _breederRepository = breederRepository;

  final IBreederRepository _breederRepository;

  OperationState _state = OperationState.idle;
  OperationState get state => _state;

  bool get isBusy =>
      _state == OperationState.loading ||
      _state == OperationState.refreshing ||
      _state == OperationState.mutating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Breeder? _breeder;
  Breeder? get breeder => _breeder;

  Future<void> loadBreeder(int id) async {
    _state = _breeder == null
        ? OperationState.loading
        : OperationState.refreshing;
    _errorMessage = null;
    notifyListeners();

    try {
      _breeder = await _breederRepository.getBreeder(id);
      _state = OperationState.success;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }

  void setupNewBreeder() {
    _breeder = null;
    _errorMessage = null;
    _state = OperationState.idle;
    notifyListeners();
  }

  /// Creates or updates the breeder. Returns true on success.
  ///
  /// On update the local [breeder] is mutated optimistically then restored from
  /// its pre-edit snapshot if the repository call fails, so a refused edit does
  /// not leave a divergent form.
  Future<bool> saveBreeder({
    required String name,
    required String sex,
    required String breed,
    required DateTime? birthDate,
    required String chipNumber,
    required String tattooNumber,
    required String status,
  }) async {
    if (_state == OperationState.mutating) return false;
    _state = OperationState.mutating;
    _errorMessage = null;

    // Snapshot for rollback (update path mutates _breeder! in place).
    final Breeder? snapshot = _breeder == null
        ? null
        : Breeder(
            id: _breeder!.id,
            name: _breeder!.name,
            sex: _breeder!.sex,
            breed: _breeder!.breed,
            birthDate: _breeder!.birthDate,
            chipNumber: _breeder!.chipNumber,
            tattooNumber: _breeder!.tattooNumber,
            status: _breeder!.status,
            photoUrl: _breeder!.photoUrl,
            kennelId: _breeder!.kennelId,
          );
    notifyListeners();

    try {
      if (_breeder == null) {
        final newBreeder = Breeder(
          name: name,
          sex: sex,
          breed: breed,
          birthDate: birthDate,
          chipNumber: chipNumber.isEmpty ? null : chipNumber,
          tattooNumber: tattooNumber.isEmpty ? null : tattooNumber,
          status: status,
          kennelId: 1, // Default mock kennel id
        );
        await _breederRepository.createBreeder(newBreeder);
      } else {
        _breeder!.name = name;
        _breeder!.sex = sex;
        _breeder!.breed = breed;
        _breeder!.birthDate = birthDate;
        _breeder!.chipNumber = chipNumber.isEmpty ? null : chipNumber;
        _breeder!.tattooNumber = tattooNumber.isEmpty ? null : tattooNumber;
        _breeder!.status = status;
        await _breederRepository.updateBreeder(_breeder!);
      }
      _state = OperationState.success;
      notifyListeners();
      return true;
    } catch (e) {
      if (snapshot != null) {
        _breeder = snapshot;
      }
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
      notifyListeners();
      return false;
    }
  }
}
