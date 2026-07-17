import 'package:flutter/foundation.dart';
import 'package:portea_client/portea_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../../../core/notifications/inotification_service.dart';
import '../../../puppies/domain/repositories/i_care_repository.dart';
import '../../domain/repositories/i_kennel_repository.dart';

/// Drives the onboarding flow and its routing.
///
/// Two distinct concepts:
/// - [hasKennel]: a kennel exists on the server (drives setup vs notifications).
/// - [isOnboardingCompleted]: the user has gone through the full flow,
///   including the notifications screen. Persisted via SharedPreferences so a
///   cold start after onboarding goes straight to the dashboard.
///
/// The auth state is injected as a [ValueListenable] to keep the view model
/// testable without a real client.
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required IKennelRepository kennelRepository,
    ICareRepository? careRepository,
    INotificationService? notificationService,
    ValueListenable<bool>? authListenable,
  }) : _kennelRepository = kennelRepository,
       _careRepository = careRepository,
       _notificationService = notificationService,
       _authListenable = authListenable {
    _authListenable?.addListener(_onAuthChanged);
    if (_authListenable?.value ?? false) {
      _onAuthChanged();
    }
  }

  final IKennelRepository _kennelRepository;
  final ICareRepository? _careRepository;
  final INotificationService? _notificationService;
  final ValueListenable<bool>? _authListenable;

  static const _onboardingCompletedKey = 'onboarding_completed';

  OperationState _state = OperationState.idle;
  OperationState get state => _state;

  bool get isBusy =>
      _state == OperationState.loading ||
      _state == OperationState.refreshing ||
      _state == OperationState.mutating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => _authListenable?.value ?? false;

  /// A kennel exists on the server for this user.
  bool _hasKennel = false;
  bool get hasKennel => _hasKennel;

  /// True only once the full onboarding flow is done (kennel created AND
  /// notifications screen passed). Persisted across cold starts.
  bool _isOnboardingCompleted = false;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  /// Authenticated, no kennel yet -> redirect to Kennel Setup.
  bool get needsKennelSetup => isAuthenticated && !_hasKennel;

  Kennel? _kennel;
  Kennel? get kennel => _kennel;

  String _kennelName = '';
  String get kennelName => _kennelName;
  set kennelName(String value) {
    _kennelName = value;
    notifyListeners();
  }

  String _species = 'dog';
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

  /// Called when the auth state changes. Resolves the kennel from the server
  /// and reads the persisted onboarding-completed flag.
  ///
  /// On a server/network failure, [hasKennel] and [isOnboardingCompleted] are
  /// left untouched and [errorMessage] is populated — this keeps the
  /// legitimate "no kennel yet" state (getKennel returns null without throwing)
  /// distinct from "the server is unreachable" (claim 4.5 connexe).
  void _onAuthChanged() async {
    if (!isAuthenticated) {
      _hasKennel = false;
      _isOnboardingCompleted = false;
      _kennel = null;
      _errorMessage = null;
      _state = OperationState.idle;
      notifyListeners();
      return;
    }

    _state = OperationState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _kennel = await _kennelRepository.getKennel();
      _hasKennel = _kennel != null;
      final prefs = await SharedPreferences.getInstance();
      _isOnboardingCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;
      _state = OperationState.success;
      // F07: re-schedule every future reminder after login so they survive a
      // device reboot. Hooked here (where the kennel resolves), not a new
      // mechanism. Idempotent. Best-effort: a failure here must not break the
      // auth flow.
      if (_hasKennel && _isOnboardingCompleted) {
        await _rescheduleReminders();
      }
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
      // NOTE: _hasKennel / _isOnboardingCompleted are deliberately NOT reset
      // here — a transient network failure must not be mistaken for "the user
      // has no kennel". The legitimate "no kennel" case is getKennel returning
      // null without throwing, handled above.
    } finally {
      notifyListeners();
    }
  }

  /// F07: fetches the next upcoming reminders and asks the notification service
  /// to re-schedule them. Best-effort and isolated from the auth flow — a
  /// repository or OS failure here is swallowed (the app still works; reminders
  /// may just be silent until next restart). Idempotent.
  Future<void> _rescheduleReminders() async {
    final careRepo = _careRepository;
    final service = _notificationService;
    if (careRepo == null || service == null) return;
    try {
      final upcoming = await careRepo.getUpcomingReminders(50);
      await service.rescheduleAll(upcoming);
    } catch (_) {
      // Silently degrade: re-scheduling is an enhancement, not a requirement
      // for the auth flow to succeed.
    }
  }

  /// Marks onboarding as fully complete (called from the notifications screen).
  /// Persisted so a cold start after onboarding goes straight to the dashboard.
  Future<void> completeOnboarding() async {
    _isOnboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
    notifyListeners();
  }

  Future<bool> createKennel() async {
    if (_kennelName.trim().isEmpty) return false;
    if (_state == OperationState.mutating) return false;

    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      final kennel = Kennel(
        name: _kennelName.trim(),
        species: _species,
        affix: _affix.trim().isEmpty ? null : _affix.trim(),
        createdAt: DateTime.now(),
      );
      _kennel = await _kennelRepository.createKennel(kennel);
      _hasKennel = _kennel != null;
      // NOTE: onboarding is NOT complete here — the user must still pass the
      // notifications screen, which calls completeOnboarding().
      _state = OperationState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authListenable?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
