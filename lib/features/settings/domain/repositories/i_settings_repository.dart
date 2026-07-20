abstract class ISettingsRepository {
  /// Premium status is read-only here: the server is the single authority
  /// (Kennel.premiumUntil), updated only through `KennelEndpoint.syncPremiumStatus`.
  /// The client never writes premium status — that path was a F10-A stub and
  /// is now gone.
  Future<bool> isPremium();

  Future<String> getThemeMode();
  Future<void> setThemeMode(String themeMode);
}
