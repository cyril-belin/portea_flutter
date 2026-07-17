import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
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

  OperationState _state = OperationState.idle;
  OperationState get state => _state;

  bool get isBusy =>
      _state == OperationState.loading ||
      _state == OperationState.refreshing ||
      _state == OperationState.mutating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Kennel? _kennel;
  Kennel? get kennel => _kennel;

  Litter? _activeLitter;
  Litter? get activeLitter => _activeLitter;

  List<Puppy> _activeLitterPuppies = [];
  // Claim 2.6: never expose the mutable backing list.
  List<Puppy> get activeLitterPuppies =>
      List.unmodifiable(_activeLitterPuppies);

  List<CareEntry> _upcomingReminders = [];
  // Claim 2.6: never expose the mutable backing list.
  List<CareEntry> get upcomingReminders =>
      List.unmodifiable(_upcomingReminders);

  String? _motherName;
  String? get motherName => _motherName;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> loadDashboard() async {
    // Refresh vs first load: existing dashboard data stays visible during a
    // reload (pulled-to-refresh, post-mutation refresh).
    final hasData = _kennel != null;
    _state = hasData ? OperationState.refreshing : OperationState.loading;
    _errorMessage = null;
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
      _state = OperationState.success;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }
}
