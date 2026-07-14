import 'package:flutter_test/flutter_test.dart';
import 'package:portea_flutter/core/data/mock_database.dart';
import 'package:portea_flutter/features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'package:portea_flutter/features/onboarding/data/repositories/mock_kennel_repository.dart';
import 'package:portea_flutter/features/litters/data/repositories/mock_litter_repository.dart';
import 'package:portea_flutter/features/puppies/data/repositories/mock_puppy_repository.dart';
import 'package:portea_flutter/features/puppies/data/repositories/mock_care_repository.dart';
import 'package:portea_flutter/features/settings/data/repositories/mock_settings_repository.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('DashboardViewModel', () {
    late MockKennelRepository kennelRepository;
    late MockLitterRepository litterRepository;
    late MockPuppyRepository puppyRepository;
    late MockCareRepository careRepository;
    late MockSettingsRepository settingsRepository;
    late DashboardViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      kennelRepository = MockKennelRepository();
      litterRepository = MockLitterRepository();
      puppyRepository = MockPuppyRepository();
      careRepository = MockCareRepository();
      settingsRepository = MockSettingsRepository();

      viewModel = DashboardViewModel(
        kennelRepository: kennelRepository,
        litterRepository: litterRepository,
        puppyRepository: puppyRepository,
        careRepository: careRepository,
        settingsRepository: settingsRepository,
      );
    });

    test('initial states', () {
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.kennel, isNull);
      expect(viewModel.activeLitter, isNull);
      expect(viewModel.activeLitterPuppies, isEmpty);
      expect(viewModel.upcomingReminders, isEmpty);
      expect(viewModel.motherName, isNull);
      expect(viewModel.isPremium, isFalse);
    });

    test('loadDashboard loads all properties when there is an active litter', () async {
      // Setup default database state has 1 active litter, 3 puppies, 2 care entries
      // Setup mock kennel repository to have a kennel (default in resetMockDatabase is dog species)
      final db = MockDatabase.instance;
      await kennelRepository.createKennel(db.kennel!); // Initialize the kennel repo

      final future = viewModel.loadDashboard();
      expect(viewModel.isLoading, isTrue);

      await future;

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.isPremium, isFalse);
      expect(viewModel.kennel, isNotNull);
      expect(viewModel.kennel!.name, equals("L'Élevage des Terres Dorées"));
      expect(viewModel.activeLitter, isNotNull);
      expect(viewModel.activeLitter!.id, equals(1));
      expect(viewModel.activeLitterPuppies.length, equals(3));
      expect(viewModel.motherName, equals("Salsa"));
      expect(viewModel.upcomingReminders.length, equals(1)); // reminderAt is in future
    });

    test('loadDashboard handles no active litter', () async {
      // Arrange: clear litters from db
      MockDatabase.instance.litters.clear();

      await viewModel.loadDashboard();

      expect(viewModel.activeLitter, isNull);
      expect(viewModel.activeLitterPuppies, isEmpty);
      expect(viewModel.motherName, isNull);
    });

    test('loadDashboard reads premium status correctly', () async {
      MockDatabase.instance.premiumUser = true;

      await viewModel.loadDashboard();

      expect(viewModel.isPremium, isTrue);
    });
  });
}
