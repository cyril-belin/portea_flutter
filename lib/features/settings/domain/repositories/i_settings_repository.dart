abstract class ISettingsRepository {
  Future<bool> isPremium();
  Future<void> setPremium(bool premium);
}
