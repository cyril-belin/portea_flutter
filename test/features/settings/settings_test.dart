import 'package:flutter_test/flutter_test.dart';
import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/core/data/mock_database.dart';
import 'package:portea_flutter/core/errors/operation_state.dart';
import 'package:portea_flutter/features/settings/data/repositories/mock_settings_repository.dart';
import 'package:portea_flutter/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:portea_flutter/features/onboarding/data/repositories/mock_kennel_repository.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('MockSettingsRepository', () {
    late MockSettingsRepository repository;

    setUp(() {
      resetMockDatabase();
      repository = MockSettingsRepository();
    });

    test('isPremium returns correct value from DB', () async {
      expect(await repository.isPremium(), isFalse);
      MockDatabase.instance.premiumUser = true;
      expect(await repository.isPremium(), isTrue);
    });

    test('setPremium updates value in DB', () async {
      await repository.setPremium(true);
      expect(MockDatabase.instance.premiumUser, isTrue);
      expect(await repository.isPremium(), isTrue);
    });
  });

  group('SettingsViewModel', () {
    late MockKennelRepository kennelRepo;
    late MockSettingsRepository settingsRepo;
    late SettingsViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      kennelRepo = MockKennelRepository();
      settingsRepo = MockSettingsRepository();
      viewModel = SettingsViewModel(
        kennelRepository: kennelRepo,
        settingsRepository: settingsRepo,
      );
    });

    test('initial state is idle and not busy', () {
      expect(viewModel.state, OperationState.idle);
      expect(viewModel.isBusy, isFalse);
      expect(viewModel.kennel, isNull);
      expect(viewModel.isPremium, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('loadSettings loads kennel and premium status', () async {
      final db = MockDatabase.instance;
      await kennelRepo.createKennel(db.kennel!);
      db.premiumUser = true;

      await viewModel.loadSettings();

      expect(viewModel.kennel, isNotNull);
      expect(viewModel.kennel!.name, equals("L'Élevage des Terres Dorées"));
      expect(viewModel.isPremium, isTrue);
      expect(viewModel.state, OperationState.success);
      expect(viewModel.errorMessage, isNull);
    });

    test('updateKennel calls repository and updates local kennel', () async {
      final db = MockDatabase.instance;
      await kennelRepo.createKennel(db.kennel!);
      await viewModel.loadSettings();

      final updated = Kennel(
        name: 'Nouveau Nom',
        species: 'cat',
        affix: 'Nouveau',
        createdAt: DateTime.now(),
      );

      await viewModel.updateKennel(updated);

      expect(viewModel.kennel!.name, equals('Nouveau Nom'));
      expect(viewModel.kennel!.species, equals('cat'));

      final saved = await kennelRepo.getKennel();
      expect(saved!.name, equals('Nouveau Nom'));
    });

    test('togglePremium updates settings repository and local state', () async {
      expect(viewModel.isPremium, isFalse);

      await viewModel.togglePremium(true);
      expect(viewModel.isPremium, isTrue);

      final dbPremium = await settingsRepo.isPremium();
      expect(dbPremium, isTrue);
    });
  });

  group('SettingsViewModel — error handling', () {
    late MockKennelRepository kennelRepo;
    late MockSettingsRepository settingsRepo;
    late SettingsViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      kennelRepo = MockKennelRepository();
      settingsRepo = MockSettingsRepository();
      viewModel = SettingsViewModel(
        kennelRepository: kennelRepo,
        settingsRepository: settingsRepo,
      );
    });

    test('loadSettings failure sets errorMessage and error state', () async {
      kennelRepo.throwOnNext = Exception('network down');

      await viewModel.loadSettings();

      expect(viewModel.state, OperationState.error);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.kennel, isNull);
    });

    test(
      'updateKennel failure rolls back local kennel and surfaces error',
      () async {
        // Seed an initial kennel via a successful load.
        final db = MockDatabase.instance;
        await kennelRepo.createKennel(db.kennel!);
        await viewModel.loadSettings();
        final originalName = viewModel.kennel!.name;
        expect(originalName, isNotEmpty);

        // The update fails: optimistic change must be reverted.
        kennelRepo.throwOnNext = const ServerpodClientException(
          'boom',
          -1,
        );
        final updated = Kennel(
          name: 'Devrait être rejeté',
          species: 'cat',
          affix: 'X',
          createdAt: DateTime.now(),
        );
        await viewModel.updateKennel(updated);

        expect(viewModel.state, OperationState.error);
        expect(viewModel.errorMessage, isNotNull);
        expect(
          viewModel.kennel!.name,
          equals(originalName),
          reason: 'optimistic mutation must be rolled back on failure',
        );
      },
    );
  });
}
