import 'package:flutter/foundation.dart';
import 'package:portea_client/portea_client.dart';

import '../../domain/repositories/i_kennel_repository.dart';

/// Drives the onboarding flow and its routing.
///
/// Onboarding is considered complete only when the user is authenticated AND
/// owns a kennel on the server. The auth state is observed via the injected
/// [authListenable]; whenever it changes, the view model re-resolves the
/// kennel from the server and notifies its listeners (the go_router
/// `refreshListenable` reacts and redirects accordingly).
///
/// Depending on the global `client` directly would break unit testing, so the
/// auth state is injected as a [ValueListenable].
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required IKennelRepository kennelRepository,
    ValueListenable<bool>? authListenable,
  }) : _kennelRepository = kennelRepository,
       _authListenable = authListenable {
    _authListenable?.addListener(_onAuthChanged);
    // Resolve the initial state synchronously from the listenable's value.
    if (_authListenable?.value ?? false) {
      _onAuthChanged();
    }
  }

  final IKennelRepository _kennelRepository;
  final ValueListenable<bool>? _authListenable;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => _authListenable?.value ?? false;

  /// True only once the user is authenticated AND a kennel exists on the server.
  bool _isOnboardingCompleted = false;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  /// True when the user is authenticated but has not created a kennel yet.
  /// Drives the redirect to Kennel Setup.
  bool get needsKennelSetup => isAuthenticated && !_isOnboardingCompleted;

  /// The resolved kennel (null until fetched from the server).
  Kennel? _kennel;
  Kennel? get kennel => _kennel;

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

  /// Called when the auth state (or the view model itself) changes. Resolves
  /// the kennel from the server and derives [isOnboardingCompleted].
  void _onAuthChanged() async {
    if (!isAuthenticated) {
      _isOnboardingCompleted = false;
      _kennel = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _kennel = await _kennelRepository.getKennel();
      _isOnboardingCompleted = _kennel != null;
    } catch (_) {
      _kennel = null;
      _isOnboardingCompleted = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      _kennel = await _kennelRepository.createKennel(kennel);
      _isOnboardingCompleted = _kennel != null;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authListenable?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
