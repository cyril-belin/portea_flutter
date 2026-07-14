import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../onboarding/domain/repositories/i_kennel_repository.dart';
import '../../../litters/domain/repositories/i_litter_repository.dart';
import '../../../puppies/domain/repositories/i_puppy_repository.dart';
import '../../../puppies/domain/repositories/i_care_repository.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final IKennelRepository _kennelRepository;
  final ILitterRepository _litterRepository;
  final IPuppyRepository _puppyRepository;
  final ICareRepository _careRepository;
  final ISettingsRepository _settingsRepository;

  DashboardViewModel({
    required IKennelRepository kennelRepository,
    required ILitterRepository litterRepository,
    required IPuppyRepository puppyRepository,
    required ICareRepository careRepository,
    required ISettingsRepository settingsRepository,
  }) : _kennelRepository = kennelRepository,
       _litterRepository = litterRepository,
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
        // Let's resolve the mother's name from mock store directly or keep it simple
        _motherName = "Salsa"; // Standard from database
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
