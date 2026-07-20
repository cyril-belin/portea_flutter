import 'package:portea_client/portea_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/i_settings_repository.dart';

/// Settings repository backed by Serverpod (premium) and SharedPreferences
/// (theme).
///
/// - `isPremium()` calls `client.kennel.isPremium()`: the server is the
///   authority. The status is NEVER written from the client (the F10-A stub
///   `setPremium` is gone). Purchase/restore flow lives in `PremiumService`,
///   which triggers a server sync; this read picks up the resulting value.
/// - Theme is a local, user-only preference → SharedPreferences, no server.
class ServerpodSettingsRepository implements ISettingsRepository {
  ServerpodSettingsRepository(this._client);

  final Client _client;

  static const _themeModeKey = 'theme_mode';

  @override
  Future<bool> isPremium() => _client.kennel.isPremium();

  @override
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  @override
  Future<void> setThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode);
  }
}
