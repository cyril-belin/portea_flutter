import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../../../core/notifications/inotification_service.dart';
import '../../../onboarding/domain/repositories/i_kennel_repository.dart';
import '../../domain/repositories/i_account_repository.dart';
import '../../domain/repositories/i_settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final IKennelRepository _kennelRepository;
  final ISettingsRepository _settingsRepository;
  final IAccountRepository _accountRepository;
  final INotificationService _notificationService;

  /// Clears the local on-device state after an account deletion:
  /// `SharedPreferences.clear()` in production (wipes the onboarding flag,
  /// theme, anything cached). Injected as a closure so the ViewModel stays
  /// testable without depending on the `shared_preferences` plugin.
  final Future<void> Function() _clearLocalState;

  SettingsViewModel({
    required IKennelRepository kennelRepository,
    required ISettingsRepository settingsRepository,
    required IAccountRepository accountRepository,
    required INotificationService notificationService,
    required Future<void> Function() clearLocalState,
  }) : _kennelRepository = kennelRepository,
       _settingsRepository = settingsRepository,
       _accountRepository = accountRepository,
       _notificationService = notificationService,
       _clearLocalState = clearLocalState;

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

  /// Updates the breeder (owner) info of the kennel through the dedicated
  /// endpoint (F09 prerequisite): `ownerName`, `ownerAddress`, `ownerPhone`,
  /// `ownerEmail` and `siret`. All params are optional and REPLACEMENT in
  /// semantics — a field left empty is erased on the row, not preserved (the
  /// form resubmits the whole dossier). The server validates email shape and
  /// SIRET (14 digits); a refusal is surfaced via the central error mapper.
  ///
  /// Optimistic with rollback: the local kennel is updated from the fresh row
  /// returned by the server on success, restored to the previous value on
  /// failure. Returns `true` on success, `false` on failure (the screen shows
  /// [errorMessage] either way).
  Future<bool> updateKennelOwnerInfo({
    String? ownerName,
    String? ownerAddress,
    String? ownerPhone,
    String? ownerEmail,
    String? siret,
  }) async {
    if (_state == OperationState.mutating) return false;
    final previousKennel = _kennel;
    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      _kennel = await _kennelRepository.updateKennelOwnerInfo(
        ownerName: ownerName,
        ownerAddress: ownerAddress,
        ownerPhone: ownerPhone,
        ownerEmail: ownerEmail,
        siret: siret,
      );
      _state = OperationState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _kennel = previousKennel;
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
      notifyListeners();
      return false;
    }
  }

  /// Irreversibly deletes the authenticated user's account and cleans up the
  /// local device state.
  ///
  /// The order is what the RGPD spec requires — the server-side deletion is
  /// the SOURCE OF TRUTH, every local cleanup comes AFTER it succeeds:
  ///
  /// 1. `accountRepository.deleteAccount()` — the only call that can fail.
  ///    On failure: NO local cleanup runs (no cancelAll, no clearLocalState,
  ///    no signOut), `errorMessage` is populated, the user stays logged in
  ///    and can retry. This is the "no fake success" rule from verdict §2.2.
  /// 2. `notificationService.cancelAll()` — reminders for a deleted kennel
  ///    must never ring.
  /// 3. `clearLocalState()` — wipes SharedPreferences (onboarding flag,
  ///    theme, anything cached). Without this the next user on the device
  ///    would inherit the previous one's onboarding state (verdict §4.5).
  /// 4. `accountRepository.signOutDevice()` — clears the local auth state.
  ///    Best-effort: the server has already invalidated the session, so the
  ///    call may 401; the session manager's `finally` still wipes local
  ///    auth state.
  ///
  /// Returns `true` on success, `false` on failure. The screen does NOT
  /// navigate away on failure — there is nothing to navigate to (the user
  /// is still signed in).
  Future<bool> deleteAccount() async {
    if (_state == OperationState.mutating) return false;
    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1 — the only call that can fail. Every local cleanup is gated
      // by this success.
      await _accountRepository.deleteAccount();

      // Step 2 — cancel pending reminders. Best-effort: a failure here does
      // NOT undo the server deletion (the data is already gone). We swallow
      // because there is no recovery action — the account is dead, an
      // orphan notification is the user's problem the OS will eventually
      // clear on app reinstall.
      try {
        await _notificationService.cancelAll();
      } catch (_) {
        // Already logged by the plugin if it can; nothing actionable here.
      }

      // Step 3 — wipe local preferences. Same best-effort posture: a failure
      // leaves a stale flag, but the server data is gone and that is what
      // RGPD cares about.
      try {
        await _clearLocalState();
      } catch (_) {
        // Swallow — see rationale above.
      }

      // Step 4 — sign out. The session manager's `finally` clears the local
      // auth state even if the server call fails (which it will — the user
      // is already deleted). We do NOT throw on its return value.
      try {
        await _accountRepository.signOutDevice();
      } catch (_) {
        // The local auth state is cleared by the session manager regardless.
      }

      _state = OperationState.success;
      _kennel = null;
      notifyListeners();
      return true;
    } catch (e) {
      // FAILURE: NO local cleanup has run. The user is still signed in,
      // the data is still on the server, the reminders still stand.
      // errorMessage is surfaced so the screen can show what went wrong.
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
      notifyListeners();
      return false;
    }
  }

  /// Exports every structured row owned by the session's kennel as a single
  /// [KennelDataExport] payload (article 20 RGPD — portability).
  ///
  /// Returns `null` on failure (with `errorMessage` populated). The screen
  /// must NOT show a success UI until it has the payload in hand and has
  /// handed it to the share sheet — see `SettingsScreen` flow.
  Future<KennelDataExport?> exportMyData() async {
    if (_state == OperationState.mutating) return null;
    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      final export = await _accountRepository.exportMyData();
      _state = OperationState.success;
      notifyListeners();
      return export;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
      notifyListeners();
      return null;
    }
  }
}
