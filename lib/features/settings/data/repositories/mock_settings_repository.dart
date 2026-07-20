import '../../../../core/data/mock_database.dart';
import '../../domain/repositories/i_settings_repository.dart';

/// Mock settings repository for tests. The premium status reflects
/// [MockDatabase.premiumUser] — tests set that field directly (the client no
/// longer writes premium status via a `setPremium` method; the production
/// repository reads it from the server).
class MockSettingsRepository implements ISettingsRepository {
  final _db = MockDatabase.instance;

  /// When non-null, the next repository call throws this. Consumed on first
  /// call, then reset to null.
  Object? throwOnNext;

  Future<void> _maybeThrow() async {
    final pending = throwOnNext;
    if (pending != null) {
      throwOnNext = null;
      throw pending;
    }
  }

  @override
  Future<bool> isPremium() async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 50));
    return _db.premiumUser;
  }

  @override
  Future<String> getThemeMode() async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 50));
    return _db.themeMode;
  }

  @override
  Future<void> setThemeMode(String themeMode) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 50));
    _db.themeMode = themeMode;
  }
}
