import 'package:flutter_test/flutter_test.dart';
import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/core/data/mock_database.dart';
import 'package:portea_flutter/core/errors/operation_state.dart';
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
    late MockBreederRepository breederRepo;
    late MockSettingsRepository settingsRepo;
    late LittersViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      litterRepo = MockLitterRepository();
      breederRepo = MockBreederRepository();
      settingsRepo = MockSettingsRepository();
      viewModel = LittersViewModel(
        litterRepository: litterRepo,
        breederRepository: breederRepo,
        settingsRepository: settingsRepo,
      );
    });

    test('initial state is idle and not busy', () {
      expect(viewModel.state, OperationState.idle);
      expect(viewModel.isBusy, isFalse);
      expect(viewModel.activeLitter, isNull);
      expect(viewModel.pastLitters, isEmpty);
      expect(viewModel.isPremium, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test(
      'loadLitters populates properties when active litter exists',
      () async {
        final future = viewModel.loadLitters();
        expect(viewModel.isBusy, isTrue);
        expect(viewModel.state, OperationState.loading);

        await future;

        expect(viewModel.isBusy, isFalse);
        expect(viewModel.state, OperationState.success);
        expect(viewModel.activeLitter, isNotNull);
        expect(viewModel.activeLitter!.id, equals(1));
        expect(viewModel.pastLitters, isEmpty);
        expect(viewModel.isPremium, isFalse);
      },
    );

    test('loadLitters failure sets errorMessage and error state', () async {
      litterRepo.throwOnNext = Exception('boom');

      await viewModel.loadLitters();

      expect(viewModel.state, OperationState.error);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.activeLitter, isNull);
      expect(viewModel.pastLitters, isEmpty);
    });

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

    test(
      'loadLitterDetail failure sets errorMessage and error state',
      () async {
        litterRepo.throwOnNext = Exception('boom');

        await viewModel.loadLitterDetail(1);

        expect(viewModel.state, OperationState.error);
        expect(viewModel.errorMessage, isNotNull);
        expect(viewModel.litter, isNull);
      },
    );
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
      'declareLitter creates a new litter without touching the existing active one',
      () async {
        // Current active litter has ID 1
        final activeBefore = await litterRepo.getActiveLitter();
        expect(activeBefore!.id, equals(1));
        expect(activeBefore.isActive, isTrue);

        final birthDate = DateTime.now();
        final result = await viewModel.declareLitter(
          motherId: 1,
          fatherId: 2,
          birthDate: birthDate,
        );

        // Declaration succeeded.
        expect(result.outcome, LitterDeclarationOutcome.success);
        expect(result.litter, isNotNull);
        expect(result.litter!.id, equals(2));
        expect(result.litter!.isActive, isTrue);

        // The previous active litter is left untouched — NO silent
        // deactivation. Closure is a manual action.
        final oldLitter = await litterRepo.getLitter(1);
        expect(oldLitter!.isActive, isTrue);
      },
    );
  });
}
