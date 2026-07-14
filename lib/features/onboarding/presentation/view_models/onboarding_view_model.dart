import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_kennel_repository.dart';

class OnboardingViewModel extends ChangeNotifier {
  final IKennelRepository _kennelRepository;

  OnboardingViewModel({required IKennelRepository kennelRepository})
    : _kennelRepository = kennelRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isOnboardingCompleted = false;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  String _kennelName = '';
  String get kennelName => _kennelName;
  set kennelName(String value) {
    _kennelName = value;
    notifyListeners();
  }

  String _species = 'dog'; // 'dog' | 'cat'
  String get species => _species;
  set species(String value) {
    _species = value;
    notifyListeners();
  }

  String _affix = '';
  String get affix => _affix;
  set affix(String value) {
    _affix = value;
    notifyListeners();
  }

  void completeOnboarding() {
    _isOnboardingCompleted = true;
    notifyListeners();
  }

  Future<bool> createKennel() async {
    if (_kennelName.trim().isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final kennel = Kennel(
        name: _kennelName.trim(),
        species: _species,
        affix: _affix.trim().isEmpty ? null : _affix.trim(),
        createdAt: DateTime.now(),
      );
      await _kennelRepository.createKennel(kennel);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
