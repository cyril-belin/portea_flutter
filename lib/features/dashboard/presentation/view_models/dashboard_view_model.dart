import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../onboarding/domain/repositories/i_kennel_repository.dart';
import '../../../litters/domain/repositories/i_litter_repository.dart';
import '../../../breeders/domain/repositories/i_breeder_repository.dart';
import '../../../puppies/domain/repositories/i_puppy_repository.dart';
import '../../../puppies/domain/repositories/i_care_repository.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final IKennelRepository _kennelRepository;
  final ILitterRepository _litterRepository;
  final IBreederRepository _breederRepository;
  final IPuppyRepository _puppyRepository;
  final ICareRepository _careRepository;
  final ISettingsRepository _settingsRepository;

  DashboardViewModel({
    required IKennelRepository kennelRepository,
    required ILitterRepository litterRepository,
    required IBreederRepository breederRepository,
    required IPuppyRepository puppyRepository,
    required ICareRepository careRepository,
    required ISettingsRepository settingsRepository,
  }) : _kennelRepository = kennelRepository,
       _litterRepository = litterRepository,
       _breederRepository = breederRepository,
       _puppyRepository = puppyRepository,
       _careRepository = careRepository,
       _settingsRepository = settingsRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Kennel? _kennel;
  Kennel? get kennel => _kennel;

  Litter? _activeLitter;
  Litter? get activeLitter => _activeLitter;

  List<Puppy> _activeLitterPuppies = [];
  List<Puppy> get activeLitterPuppies => _activeLitterPuppies;

  List<CareEntry> _upcomingReminders = [];
  List<CareEntry> get upcomingReminders => _upcomingReminders;

  String? _motherName;
  String? get motherName => _motherName;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isPremium = await _settingsRepository.isPremium();
      _kennel = await _kennelRepository.getKennel();
      _activeLitter = await _litterRepository.getActiveLitter();

      if (_activeLitter != null) {
        _activeLitterPuppies = await _puppyRepository.getPuppies(
          _activeLitter!.id!,
        );
        // Resolve the mother's name from the breeder repository (real data,
        // no more hardcoded mock value).
        final mother = await _breederRepository.getBreeder(
          _activeLitter!.motherId,
        );
        _motherName = mother?.name;
      } else {
        _activeLitterPuppies = [];
        _motherName = null;
      }

      _upcomingReminders = await _careRepository.getUpcomingReminders(3);
    } catch (_) {
      // Handle error quietly in mock mode
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
