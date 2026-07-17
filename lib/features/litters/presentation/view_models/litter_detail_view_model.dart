import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../domain/repositories/i_litter_repository.dart';
import '../../../breeders/domain/repositories/i_breeder_repository.dart';
import '../../../puppies/domain/repositories/i_puppy_repository.dart';

class LitterDetailViewModel extends ChangeNotifier {
  final ILitterRepository _litterRepository;
  final IBreederRepository _breederRepository;
  final IPuppyRepository _puppyRepository;

  LitterDetailViewModel({
    required ILitterRepository litterRepository,
    required IBreederRepository breederRepository,
    required IPuppyRepository puppyRepository,
  }) : _litterRepository = litterRepository,
       _breederRepository = breederRepository,
       _puppyRepository = puppyRepository;

  OperationState _state = OperationState.idle;
  OperationState get state => _state;

  bool get isBusy =>
      _state == OperationState.loading ||
      _state == OperationState.refreshing ||
      _state == OperationState.mutating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Litter? _litter;
  Litter? get litter => _litter;

  Breeder? _mother;
  Breeder? get mother => _mother;

  Breeder? _father;
  Breeder? get father => _father;

  List<Puppy> _puppies = [];
  // Claim 2.6: never expose the mutable backing list.
  List<Puppy> get puppies => List.unmodifiable(_puppies);

  Future<void> loadLitterDetail(int id) async {
    // Refresh vs first load: existing detail stays visible during a reload.
    final hasData = _litter != null;
    _state = hasData ? OperationState.refreshing : OperationState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _litter = await _litterRepository.getLitter(id);
      if (_litter != null) {
        _mother = await _breederRepository.getBreeder(_litter!.motherId);
        if (_litter!.fatherId != null) {
          _father = await _breederRepository.getBreeder(_litter!.fatherId!);
        } else {
          _father = null;
        }
        _puppies = await _puppyRepository.getPuppies(_litter!.id!);
      }
      _state = OperationState.success;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }
}
