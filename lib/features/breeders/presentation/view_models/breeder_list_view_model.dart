import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../domain/repositories/i_breeder_repository.dart';

class BreederListViewModel extends ChangeNotifier {
  BreederListViewModel({required IBreederRepository breederRepository})
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

  List<Breeder> _breeders = [];
  // Claim 2.6: never expose the mutable backing list.
  List<Breeder> get breeders => List.unmodifiable(_breeders);

  Future<void> loadBreeders() async {
    // Refresh vs first load: existing breeders stay visible during a reload.
    _state = _breeders.isEmpty
        ? OperationState.loading
        : OperationState.refreshing;
    _errorMessage = null;
    notifyListeners();

    try {
      _breeders = await _breederRepository.getBreeders();
      _state = OperationState.success;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }
}
