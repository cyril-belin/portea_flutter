import 'package:flutter/foundation.dart';
import 'package:portea_client/portea_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../../../core/notifications/inotification_service.dart';
import '../../../breeders/domain/repositories/i_breeder_repository.dart';
import '../../../litters/domain/repositories/i_litter_repository.dart';
import '../../../puppies/domain/repositories/i_care_repository.dart';
import '../../../puppies/domain/repositories/i_puppy_repository.dart';
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
    IPuppyRepository? puppyRepository,
    ILitterRepository? litterRepository,
    IBreederRepository? breederRepository,
    INotificationService? notificationService,
    ValueListenable<bool>? authListenable,
  }) : _kennelRepository = kennelRepository,
       _careRepository = careRepository,
       _puppyRepository = puppyRepository,
       _litterRepository = litterRepository,
       _breederRepository = breederRepository,
       _notificationService = notificationService,
       _authListenable = authListenable {
    _authListenable?.addListener(_onAuthChanged);
    if (_authListenable?.value ?? false) {
      _onAuthChanged();
    }
  }

  final IKennelRepository _kennelRepository;
  final ICareRepository? _careRepository;
  final IPuppyRepository? _puppyRepository;
  final ILitterRepository? _litterRepository;
  final IBreederRepository? _breederRepository;
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

  /// F07: fetches the next upcoming reminders and re-schedules them via the
  /// notification service. Best-effort and isolated from the auth flow — any
  /// failure is swallowed (the app still works; reminders may just be silent
  /// until next restart). Idempotent (scheduling the same id replaces).
  ///
  /// Name resolution (F07 rule 7): getUpcomingReminders returns bare CareEntry
  /// rows (ids only). The target name for the title is resolved here client-side
  /// — puppy name for individual care, mother name for group care — with one
  /// lookup per entry. The notification service itself does no lookup.
  Future<void> _rescheduleReminders() async {
    final careRepo = _careRepository;
    final service = _notificationService;
    if (careRepo == null || service == null) return;
    try {
      final upcoming = await careRepo.getUpcomingReminders(50);
      for (final entry in upcoming) {
        await _scheduleOne(entry);
      }
    } catch (_) {
      // Silently degrade: re-scheduling is an enhancement, not a requirement
      // for the auth flow to succeed.
    }
  }

  /// Resolves the target name for [entry] and schedules a single reminder.
  /// Failures (lookup or OS) are swallowed per-entry so one bad entry doesn't
  /// abort the rest. Past-date entries are skipped by the service's guard.
  Future<void> _scheduleOne(CareEntry entry) async {
    final service = _notificationService;
    final id = entry.id;
    final reminderAt = entry.reminderAt;
    if (service == null || id == null || reminderAt == null) return;

    final isGroup = entry.puppyId == null && entry.litterId != null;
    String? targetName;
    try {
      targetName = await _resolveTargetName(entry, isGroup: isGroup);
    } catch (_) {
      // Name optional: title degrades to "Rappel soin" without it.
    }

    final payload = entry.puppyId != null
        ? '/puppies/${entry.puppyId}'
        : '/litters/${entry.litterId}';

    try {
      await service.scheduleReminder(
        notificationId: id,
        scheduledAt: reminderAt,
        title: isGroup
            ? reminderTitle(motherName: targetName)
            : reminderTitle(puppyName: targetName),
        body: reminderBody(type: entry.type, product: entry.product),
        payload: payload,
      );
    } catch (_) {
      // Best-effort: a scheduling failure for one entry is non-fatal.
    }
  }

  /// Resolves the reminder target name for [entry]. Individual care → puppy
  /// name; group care → mother name ("Portée de {mère}"). Returns null on any
  /// miss so the title degrades gracefully.
  Future<String?> _resolveTargetName(
    CareEntry entry, {
    required bool isGroup,
  }) async {
    if (!isGroup) {
      final puppyId = entry.puppyId;
      final puppyRepo = _puppyRepository;
      if (puppyId == null || puppyRepo == null) return null;
      return (await puppyRepo.getPuppy(puppyId))?.name;
    }
    // Group care: litter → motherId → mother name.
    final litterId = entry.litterId;
    final litterRepo = _litterRepository;
    final breederRepo = _breederRepository;
    if (litterId == null || litterRepo == null || breederRepo == null) {
      return null;
    }
    final litter = await litterRepo.getLitter(litterId);
    if (litter == null) return null;
    final mother = await breederRepo.getBreeder(litter.motherId);
    return mother?.name;
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
