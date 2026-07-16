import 'package:flutter_test/flutter_test.dart';
import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/core/data/mock_database.dart';
import 'package:portea_flutter/features/litters/data/repositories/mock_litter_repository.dart';
import 'package:portea_flutter/features/litters/presentation/view_models/litters_view_model.dart';
import 'package:portea_flutter/features/litters/presentation/view_models/litter_detail_view_model.dart';
import 'package:portea_flutter/features/litters/presentation/view_models/litter_declaration_view_model.dart';
import 'package:portea_flutter/features/breeders/data/repositories/mock_breeder_repository.dart';
import 'package:portea_flutter/features/puppies/data/repositories/mock_puppy_repository.dart';
import 'package:portea_flutter/features/settings/data/repositories/mock_settings_repository.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('MockLitterRepository', () {
    late MockLitterRepository repository;

    setUp(() {
      resetMockDatabase();
      repository = MockLitterRepository();
    });

    test('getLitters returns all litters', () async {
      final litters = await repository.getLitters();
      expect(litters.length, equals(1));
      expect(litters[0].id, equals(1));
    });

    test('getActiveLitter returns first active litter', () async {
      final active = await repository.getActiveLitter();
      expect(active, isNotNull);
      expect(active!.isActive, isTrue);

      MockDatabase.instance.litters[0].isActive = false;
      final none = await repository.getActiveLitter();
      expect(none, isNull);
    });

    test('getLitter returns litter by ID', () async {
      final litter = await repository.getLitter(1);
      expect(litter, isNotNull);
      expect(litter!.id, equals(1));

      final nonExistent = await repository.getLitter(999);
      expect(nonExistent, isNull);
    });

    test('createLitter adds new litter with auto-incremented ID', () async {
      final newLitter = Litter(
        motherId: 1,
        fatherId: 2,
        birthDate: DateTime.now(),
        kennelId: 1,
        isActive: true,
      );

      final created = await repository.createLitter(newLitter);
      expect(created.id, equals(2));
      expect(created.motherId, equals(1));

      final list = await repository.getLitters();
      expect(list.length, equals(2));
    });

    test('updateLitter updates fields', () async {
      final litter = await repository.getLitter(1);
      expect(litter!.isActive, isTrue);

      litter.isActive = false;
      await repository.updateLitter(litter);

      final updated = await repository.getLitter(1);
      expect(updated!.isActive, isFalse);
    });
  });

  group('LittersViewModel', () {
    late MockLitterRepository litterRepo;
    late MockSettingsRepository settingsRepo;
    late LittersViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      litterRepo = MockLitterRepository();
      settingsRepo = MockSettingsRepository();
      viewModel = LittersViewModel(
        litterRepository: litterRepo,
        settingsRepository: settingsRepo,
      );
    });

    test('initial states', () {
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.activeLitter, isNull);
      expect(viewModel.pastLitters, isEmpty);
      expect(viewModel.isPremium, isFalse);
    });

    test(
      'loadLitters populates properties when active litter exists',
      () async {
        final future = viewModel.loadLitters();
        expect(viewModel.isLoading, isTrue);

        await future;

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.activeLitter, isNotNull);
        expect(viewModel.activeLitter!.id, equals(1));
        expect(viewModel.pastLitters, isEmpty);
        expect(viewModel.isPremium, isFalse);
      },
    );

    test('loadLitters splits active and past litters correctly', () async {
      // Add a past (inactive) litter
      MockDatabase.instance.litters.add(
        Litter(
          id: 2,
          motherId: 1,
          fatherId: 2,
          birthDate: DateTime.now().subtract(const Duration(days: 300)),
          kennelId: 1,
          isActive: false,
        ),
      );

      await viewModel.loadLitters();

      expect(viewModel.activeLitter, isNotNull);
      expect(viewModel.activeLitter!.id, equals(1));
      expect(viewModel.pastLitters.length, equals(1));
      expect(viewModel.pastLitters[0].id, equals(2));
    });
  });

  group('LitterDetailViewModel', () {
    late MockLitterRepository litterRepo;
    late MockBreederRepository breederRepo;
    late MockPuppyRepository puppyRepo;
    late LitterDetailViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      litterRepo = MockLitterRepository();
      breederRepo = MockBreederRepository();
      puppyRepo = MockPuppyRepository();
      viewModel = LitterDetailViewModel(
        litterRepository: litterRepo,
        breederRepository: breederRepo,
        puppyRepository: puppyRepo,
      );
    });

    test('loadLitterDetail retrieves details of the litter', () async {
      await viewModel.loadLitterDetail(1);

      expect(viewModel.litter, isNotNull);
      expect(viewModel.litter!.id, equals(1));
      expect(viewModel.mother, isNotNull);
      expect(viewModel.mother!.name, equals('Salsa'));
      expect(viewModel.father, isNotNull);
      expect(viewModel.father!.name, equals('Ramses'));
      expect(viewModel.puppies.length, equals(3));
    });

    test('loadLitterDetail handles external sire (no fatherId)', () async {
      MockDatabase.instance.litters[0].fatherId = null;
      MockDatabase.instance.litters[0].externalSireName = 'Max';

      await viewModel.loadLitterDetail(1);

      expect(viewModel.litter, isNotNull);
      expect(viewModel.father, isNull);
      expect(viewModel.litter!.externalSireName, equals('Max'));
    });
  });

  group('LitterDeclarationViewModel', () {
    late MockLitterRepository litterRepo;
    late MockBreederRepository breederRepo;
    late LitterDeclarationViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      litterRepo = MockLitterRepository();
      breederRepo = MockBreederRepository();
      viewModel = LitterDeclarationViewModel(
        litterRepository: litterRepo,
        breederRepository: breederRepo,
      );
    });

    test(
      'loadBreedersForDeclaration loads active male and female breeders',
      () async {
        await viewModel.loadBreedersForDeclaration();

        expect(viewModel.mothers.length, equals(1));
        expect(viewModel.mothers[0].name, equals('Salsa'));

        expect(viewModel.fathers.length, equals(1));
        expect(viewModel.fathers[0].name, equals('Ramses'));
      },
    );

    test(
      'declareLitter deactivates current active litter and creates a new one',
      () async {
        // Current active litter has ID 1
        final activeBefore = await litterRepo.getActiveLitter();
        expect(activeBefore!.id, equals(1));
        expect(activeBefore.isActive, isTrue);

        final birthDate = DateTime.now();
        final newLitter = await viewModel.declareLitter(
          motherId: 1,
          fatherId: 2,
          birthDate: birthDate,
        );

        expect(newLitter, isNotNull);
        expect(newLitter!.id, equals(2));
        expect(newLitter.isActive, isTrue);

        // Verify old active litter is now inactive
        final oldLitter = await litterRepo.getLitter(1);
        expect(oldLitter!.isActive, isFalse);

        final activeAfter = await litterRepo.getActiveLitter();
        expect(activeAfter!.id, equals(2));
      },
    );
  });
}
