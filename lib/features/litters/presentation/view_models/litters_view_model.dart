import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../domain/repositories/i_litter_repository.dart';
import '../../../breeders/domain/repositories/i_breeder_repository.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';

class LittersViewModel extends ChangeNotifier {
  final ILitterRepository _litterRepository;
  final IBreederRepository _breederRepository;
  final ISettingsRepository _settingsRepository;

  LittersViewModel({
    required ILitterRepository litterRepository,
    required IBreederRepository breederRepository,
    required ISettingsRepository settingsRepository,
  }) : _litterRepository = litterRepository,
       _breederRepository = breederRepository,
       _settingsRepository = settingsRepository;

  OperationState _state = OperationState.idle;
  OperationState get state => _state;

  bool get isBusy =>
      _state == OperationState.loading ||
      _state == OperationState.refreshing ||
      _state == OperationState.mutating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Litter? _activeLitter;
  Litter? get activeLitter => _activeLitter;

  String? _activeMotherName;
  String? get activeMotherName => _activeMotherName;

  List<Litter> _pastLitters = [];
  // Claim 2.6: never expose the mutable backing list.
  List<Litter> get pastLitters => List.unmodifiable(_pastLitters);

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> loadLitters() async {
    // Refresh vs first load: existing litters stay visible during a reload.
    final hasData = _activeLitter != null || _pastLitters.isNotEmpty;
    _state = hasData ? OperationState.refreshing : OperationState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _isPremium = await _settingsRepository.isPremium();
      final all = await _litterRepository.getLitters();

      final activeIndex = all.indexWhere((l) => l.isActive);
      if (activeIndex != -1) {
        _activeLitter = all[activeIndex];
        _pastLitters = all.where((l) => !l.isActive).toList();
        // Resolve the active litter's mother name from real data (no more
        // hardcoded placeholder).
        final mother = await _breederRepository.getBreeder(
          _activeLitter!.motherId,
        );
        _activeMotherName = mother?.name;
      } else {
        _activeLitter = null;
        _activeMotherName = null;
        _pastLitters = all;
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
