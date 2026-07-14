import '../../../../core/data/mock_database.dart';
import '../../domain/repositories/i_settings_repository.dart';

class MockSettingsRepository implements ISettingsRepository {
  final _db = MockDatabase.instance;

  @override
  Future<bool> isPremium() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _db.premiumUser;
  }

  @override
  Future<void> setPremium(bool premium) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _db.premiumUser = premium;
  }
}
