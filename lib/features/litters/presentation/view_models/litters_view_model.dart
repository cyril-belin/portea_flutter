import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_litter_repository.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';

class LittersViewModel extends ChangeNotifier {
  final ILitterRepository _litterRepository;
  final ISettingsRepository _settingsRepository;

  LittersViewModel({
    required ILitterRepository litterRepository,
    required ISettingsRepository settingsRepository,
  }) : _litterRepository = litterRepository,
       _settingsRepository = settingsRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Litter? _activeLitter;
  Litter? get activeLitter => _activeLitter;

  List<Litter> _pastLitters = [];
  List<Litter> get pastLitters => _pastLitters;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> loadLitters() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isPremium = await _settingsRepository.isPremium();
      final all = await _litterRepository.getLitters();

      final activeIndex = all.indexWhere((l) => l.isActive);
      if (activeIndex != -1) {
        _activeLitter = all[activeIndex];
        _pastLitters = all.where((l) => !l.isActive).toList();
      } else {
        _activeLitter = null;
        _pastLitters = all;
      }
    } catch (_) {
      // Quietly ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
