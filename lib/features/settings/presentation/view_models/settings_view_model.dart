import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Kennel? _kennel;
  Kennel? get kennel => _kennel;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _kennel = await _kennelRepository.getKennel();
      _isPremium = await _settingsRepository.isPremium();
      final themeStr = await _settingsRepository.getThemeMode();
      _themeMode = _parseThemeMode(themeStr);
    } catch (_) {
      // Ignore
    } finally {
      _isLoading = false;
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

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      await _settingsRepository.setThemeMode(mode.name);
    } catch (_) {
      // Ignore
    }
  }

  Future<void> updateKennel(Kennel updatedKennel) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _kennelRepository.updateKennel(updatedKennel);
      _kennel = updatedKennel;
    } catch (_) {
      // Ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePremium(bool premium) async {
    await _settingsRepository.setPremium(premium);
    _isPremium = premium;
    notifyListeners();
  }
}
