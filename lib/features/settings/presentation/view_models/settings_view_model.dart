import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../../onboarding/domain/repositories/i_kennel_repository.dart';
import '../../domain/repositories/i_settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final IKennelRepository _kennelRepository;
  final ISettingsRepository _settingsRepository;

  SettingsViewModel({
    required IKennelRepository kennelRepository,
    required ISettingsRepository settingsRepository,
  }) : _kennelRepository = kennelRepository,
       _settingsRepository = settingsRepository;

  OperationState _state = OperationState.idle;
  OperationState get state => _state;

  /// True while any load or mutation is in flight. Screens use this to disable
  /// interactive controls without branching on the exact [state].
  bool get isBusy =>
      _state == OperationState.loading ||
      _state == OperationState.refreshing ||
      _state == OperationState.mutating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Kennel? _kennel;
  Kennel? get kennel => _kennel;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> loadSettings() async {
    _state = OperationState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _kennel = await _kennelRepository.getKennel();
      _isPremium = await _settingsRepository.isPremium();
      final themeStr = await _settingsRepository.getThemeMode();
      _themeMode = _parseThemeMode(themeStr);
      _state = OperationState.success;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }

  ThemeMode _parseThemeMode(String themeStr) {
    switch (themeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Persists the theme choice. Local state is updated optimistically; on
  /// failure the change is kept (it is purely visual and reversible by the
  /// user) but an error message is surfaced.
  Future<void> updateThemeMode(ThemeMode mode) async {
    if (_state == OperationState.mutating) return;
    final previous = _themeMode;
    _themeMode = mode;
    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _settingsRepository.setThemeMode(mode.name);
      _state = OperationState.success;
    } catch (e) {
      _themeMode = previous;
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Updates the kennel. Local state is updated optimistically and rolled back
  /// to the prior value on failure, so a refused edit does not leave a divergent
  /// screen.
  Future<void> updateKennel(Kennel updatedKennel) async {
    if (_state == OperationState.mutating) return;
    final previousKennel = _kennel;
    _kennel = updatedKennel;
    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _kennelRepository.updateKennel(updatedKennel);
      _state = OperationState.success;
    } catch (e) {
      _kennel = previousKennel;
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> togglePremium(bool premium) async {
    if (_state == OperationState.mutating) return;
    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _settingsRepository.setPremium(premium);
      _isPremium = premium;
      _state = OperationState.success;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }
}
