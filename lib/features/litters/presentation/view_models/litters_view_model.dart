import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Litter? _activeLitter;
  Litter? get activeLitter => _activeLitter;

  String? _activeMotherName;
  String? get activeMotherName => _activeMotherName;

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
    } catch (_) {
      // Quietly ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
