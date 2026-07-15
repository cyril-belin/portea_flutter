abstract class ISettingsRepository {
  Future<bool> isPremium();
  Future<void> setPremium(bool premium);
  Future<String> getThemeMode();
  Future<void> setThemeMode(String themeMode);
}
