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

    // ---- F09 prerequisite: breeder (owner) info ----

    test(
      'updateKennelOwnerInfo persists all five fields (trimmed) and returns '
      'true',
      () async {
        final db = MockDatabase.instance;
        await kennelRepo.createKennel(db.kennel!);
        await viewModel.loadSettings();

        final ok = await viewModel.updateKennelOwnerInfo(
          ownerName: '  Marie Dupont  ',
          ownerAddress: '12 rue des Chiens',
          ownerPhone: '0612345678',
          ownerEmail: '  marie@elevage.fr  ',
          siret: '12345678900012',
        );

        expect(ok, isTrue);
        expect(viewModel.state, OperationState.success);
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.kennel!.ownerName, 'Marie Dupont');
        expect(viewModel.kennel!.ownerAddress, '12 rue des Chiens');
        expect(viewModel.kennel!.ownerPhone, '0612345678');
        expect(viewModel.kennel!.ownerEmail, 'marie@elevage.fr');
        expect(viewModel.kennel!.siret, '12345678900012');

        // Persisted in the repository.
        final saved = await kennelRepo.getKennel();
        expect(saved!.ownerName, 'Marie Dupont');
        expect(saved.siret, '12345678900012');
      },
    );

    test(
      'updateKennelOwnerInfo: an emptied field becomes null (erasable, '
      'replacement semantics)',
      () async {
        final db = MockDatabase.instance;
        await kennelRepo.createKennel(db.kennel!);
        await viewModel.loadSettings();
        // Seed a full dossier.
        await viewModel.updateKennelOwnerInfo(
          ownerName: 'Marie',
          ownerAddress: '12 rue',
          ownerPhone: '0612345678',
          ownerEmail: 'marie@elevage.fr',
          siret: '12345678900012',
        );

        // Resubmit with everything emptied.
        final ok = await viewModel.updateKennelOwnerInfo(
          ownerName: '   ',
          ownerAddress: '',
          ownerPhone: null,
          ownerEmail: '   ',
          siret: '',
        );

        expect(ok, isTrue);
        expect(viewModel.kennel!.ownerName, isNull);
        expect(viewModel.kennel!.ownerAddress, isNull);
        expect(viewModel.kennel!.ownerPhone, isNull);
        expect(viewModel.kennel!.ownerEmail, isNull);
        expect(viewModel.kennel!.siret, isNull);
      },
    );

    test(
      'updateKennelOwnerInfo: an invalid email is refused and surfaces a '
      'French message',
      () async {
        final db = MockDatabase.instance;
        await kennelRepo.createKennel(db.kennel!);
        await viewModel.loadSettings();

        final ok = await viewModel.updateKennelOwnerInfo(
          ownerEmail: 'pas-un-email',
        );

        expect(ok, isFalse);
        expect(viewModel.state, OperationState.error);
        expect(viewModel.errorMessage, isNotNull);
        // Nothing persisted.
        final saved = await kennelRepo.getKennel();
        expect(saved!.ownerEmail, isNull);
      },
    );

    test(
      'updateKennelOwnerInfo: a SIRET that is not 14 digits is refused',
      () async {
        final db = MockDatabase.instance;
        await kennelRepo.createKennel(db.kennel!);
        await viewModel.loadSettings();
        // Capture the pre-existing siret so we can assert it is preserved on
        // refusal (rollback), rather than asserting null — the seed may carry
        // a siret.
        final previousSiret = viewModel.kennel!.siret;

        final ok = await viewModel.updateKennelOwnerInfo(siret: '12345');

        expect(ok, isFalse);
        expect(viewModel.state, OperationState.error);
        expect(viewModel.errorMessage, isNotNull);
        // The refused edit rolls back: the row keeps its prior siret.
        expect(viewModel.kennel!.siret, equals(previousSiret));
      },
    );

    test(
      'updateKennelOwnerInfo: a transport failure rolls back the local kennel',
      () async {
        final db = MockDatabase.instance;
        await kennelRepo.createKennel(db.kennel!);
        await viewModel.loadSettings();
        final originalOwner = viewModel.kennel!.ownerName;

        kennelRepo.throwOnNext = const ServerpodClientException('boom', -1);
        final ok = await viewModel.updateKennelOwnerInfo(ownerName: 'Rejeté');

        expect(ok, isFalse);
        expect(viewModel.state, OperationState.error);
        expect(viewModel.errorMessage, isNotNull);
        expect(
          viewModel.kennel!.ownerName,
          equals(originalOwner),
          reason: 'optimistic mutation must roll back on failure',
        );
      },
    );
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
