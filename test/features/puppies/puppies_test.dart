import 'package:flutter_test/flutter_test.dart';
import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/features/onboarding/data/repositories/mock_kennel_repository.dart';
import 'package:portea_flutter/features/puppies/data/repositories/mock_puppy_repository.dart';
import 'package:portea_flutter/features/puppies/data/repositories/mock_weighing_repository.dart';
import 'package:portea_flutter/features/puppies/data/repositories/mock_care_repository.dart';
import 'package:portea_flutter/features/puppies/presentation/view_models/puppy_batch_view_model.dart';
import 'package:portea_flutter/features/puppies/presentation/view_models/group_weighing_view_model.dart';
import 'package:portea_flutter/features/puppies/presentation/view_models/puppy_file_view_model.dart';
import 'package:portea_flutter/features/puppies/presentation/view_models/add_care_view_model.dart';
import 'package:portea_flutter/features/settings/data/repositories/mock_settings_repository.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('MockPuppyRepository', () {
    late MockPuppyRepository repository;

    setUp(() {
      resetMockDatabase();
      repository = MockPuppyRepository();
    });

    test('getPuppies returns puppies in litter', () async {
      final list = await repository.getPuppies(1);
      expect(list.length, equals(3));
      expect(list[0].id, equals(1));
    });

    test('getPuppy returns puppy by ID', () async {
      final puppy = await repository.getPuppy(1);
      expect(puppy, isNotNull);
      expect(puppy!.name, equals('Chiot 1 (Orphée)'));

      final nonExistent = await repository.getPuppy(999);
      expect(nonExistent, isNull);
    });

    test(
      'savePuppiesBatch inserts new puppies (id null) and assigns ids',
      () async {
        // Start from an empty litter to assert pure inserts.
        final fresh = await repository.savePuppiesBatch(
          2, // no seeded puppy for litter 2
          [
            Puppy(
              litterId: 2,
              name: 'Nouveau 1',
              sex: 'female',
              birthWeight: 310,
              status: 'available',
            ),
            Puppy(
              litterId: 2,
              name: 'Nouveau 2',
              sex: 'male',
              birthWeight: 320,
              status: 'available',
            ),
          ],
        );

        expect(fresh.length, equals(2));
        expect(fresh.every((p) => p.id != null), isTrue);
        expect(fresh.every((p) => p.litterId == 2), isTrue);
      },
    );

    test(
      'savePuppiesBatch updates existing puppies (id present), no duplication',
      () async {
        final seeded = await repository.getPuppies(1);
        expect(seeded.length, equals(3));
        final original = seeded.firstWhere((p) => p.name.startsWith('Chiot 1'));

        final after = await repository.savePuppiesBatch(
          1,
          [
            Puppy(
              id: original.id,
              litterId: 1,
              name: 'Nouveau nom',
              sex: original.sex,
              status: original.status,
            ),
            // Drop the other two: they should be deleted.
          ],
        );

        expect(after.length, equals(1)); // no duplication, the others removed
        expect(after.first.id, equals(original.id));
        expect(after.first.name, equals('Nouveau nom'));
      },
    );

    test(
      'savePuppiesBatch is idempotent: replaying the same payload is a no-op',
      () async {
        final first = await repository.savePuppiesBatch(
          3,
          [
            Puppy(
              litterId: 3,
              name: 'A',
              sex: 'female',
              status: 'available',
            ),
            Puppy(
              litterId: 3,
              name: 'B',
              sex: 'male',
              status: 'available',
            ),
          ],
        );

        // Replay with the ids now assigned.
        final second = await repository.savePuppiesBatch(
          3,
          first
              .map(
                (p) => Puppy(
                  id: p.id,
                  litterId: 3,
                  name: p.name,
                  sex: p.sex,
                  status: p.status,
                ),
              )
              .toList(),
        );

        expect(second.length, equals(first.length));
        expect(
          second.map((p) => p.id).toSet(),
          equals(first.map((p) => p.id).toSet()),
        );
      },
    );

    test('updatePuppy updates details', () async {
      final puppy = await repository.getPuppy(1);
      expect(puppy!.name, equals('Chiot 1 (Orphée)'));

      puppy.name = 'Orphée Modifiée';
      await repository.updatePuppy(puppy);

      final updated = await repository.getPuppy(1);
      expect(updated!.name, equals('Orphée Modifiée'));
    });
  });

  group('MockWeighingRepository', () {
    late MockWeighingRepository repository;

    setUp(() {
      resetMockDatabase();
      repository = MockWeighingRepository();
    });

    test('getWeighings returns entries sorted by date', () async {
      final list = await repository.getWeighings(1);
      expect(list.length, equals(4)); // Puppy 1 has 4 weighings
    });

    test('addWeighing adds entry to DB', () async {
      final listBefore = await repository.getWeighings(1);
      final initialCount = listBefore.length;

      final entry = WeighingEntry(
        puppyId: 1,
        weighedAt: DateTime.now(),
        weightGrams: 2000,
      );

      await repository.addWeighing(entry);

      final listAfter = await repository.getWeighings(1);
      expect(listAfter.length, equals(initialCount + 1));
      expect(listAfter.last.weightGrams, equals(2000));
    });

    test('addWeighings adds multiple entries', () async {
      final entry1 = WeighingEntry(
        puppyId: 1,
        weighedAt: DateTime.now(),
        weightGrams: 2100,
      );
      final entry2 = WeighingEntry(
        puppyId: 2,
        weighedAt: DateTime.now(),
        weightGrams: 1500,
      );

      await repository.addWeighings([entry1, entry2]);

      final weighings1 = await repository.getWeighings(1);
      final weighings2 = await repository.getWeighings(2);

      expect(weighings1.last.weightGrams, equals(2100));
      expect(weighings2.last.weightGrams, equals(1500));
    });
  });

  group('MockCareRepository', () {
    late MockCareRepository repository;

    setUp(() {
      resetMockDatabase();
      repository = MockCareRepository();
    });

    test('getCareEntries returns entries for puppy or litter', () async {
      final puppy1Care = await repository.getCareEntries(puppyId: 1);
      expect(puppy1Care.length, equals(1)); // Has 1 vaccine entry

      final litter1Care = await repository.getCareEntries(litterId: 1);
      expect(litter1Care.length, equals(1)); // Has 1 deworming entry
    });

    test('getUpcomingReminders returns reminders in future', () async {
      final reminders = await repository.getUpcomingReminders(5);
      expect(
        reminders.length,
        equals(1),
      ); // Milbemax deworming has reminder in 7 days
    });

    test('addCareEntry adds care entry to DB', () async {
      final entry = CareEntry(
        type: 'deworming',
        product: 'Stronghold',
        appliedAt: DateTime.now(),
        puppyId: 1,
      );

      await repository.addCareEntry(entry);
      final list = await repository.getCareEntries(puppyId: 1);
      expect(list.length, equals(2));
      expect(list.any((c) => c.product == 'Stronghold'), isTrue);
    });
  });

  group('PuppyBatchViewModel', () {
    late MockPuppyRepository puppyRepo;
    late MockKennelRepository kennelRepo;
    late PuppyBatchViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      puppyRepo = MockPuppyRepository();
      kennelRepo = MockKennelRepository();
      // The mock kennel starts null; create it so species resolves to 'dog'.
      // Individual tests can re-create with species 'cat' to assert the label.
      kennelRepo.createKennel(
        Kennel(
          name: 'Élevage test',
          species: 'dog',
          createdAt: DateTime.now(),
        ),
      );
      viewModel = PuppyBatchViewModel(
        kennelRepository: kennelRepo,
        puppyRepository: puppyRepo,
      );
    });

    test(
      'loadLitterPuppies loads the real puppies (no mock pre-fill)',
      () async {
        // Litter 1 is seeded with 3 puppies in the mock DB.
        await viewModel.loadLitterPuppies(1);

        expect(viewModel.items.length, equals(3));
        expect(viewModel.items[0].name, equals('Chiot 1 (Orphée)'));
        // Real ids are carried — that is what makes the save idempotent.
        expect(viewModel.items.every((i) => i.id != null), isTrue);
      },
    );

    test('loadLitterPuppies on an empty litter yields an empty form', () async {
      // Litter 999 has no puppies — the form must be empty (not pre-filled).
      await viewModel.loadLitterPuppies(999);

      expect(viewModel.items, isEmpty);
    });

    test('addItem appends a species-specific default name', () async {
      await viewModel.loadLitterPuppies(999); // empty
      expect(viewModel.items, isEmpty);

      viewModel.addItem();
      expect(viewModel.items.length, equals(1));
      expect(viewModel.items.first.name, equals('Chiot 1'));
    });

    test('addItem uses "Chaton" when the kennel species is cat', () async {
      await kennelRepo.createKennel(
        Kennel(name: 'Chatterie', species: 'cat', createdAt: DateTime.now()),
      );
      await viewModel.loadLitterPuppies(999);

      viewModel.addItem();
      expect(viewModel.items.first.name, equals('Chaton 1'));
      expect(viewModel.youngNoun, equals('chaton'));
    });

    test('removeItem drops a row even when it is the last one', () async {
      await viewModel.loadLitterPuppies(999);
      viewModel.addItem();
      expect(viewModel.items.length, equals(1));

      viewModel.removeItem(0);
      expect(viewModel.items, isEmpty);
    });

    test('updateSex modifies the sex of an item', () async {
      await viewModel.loadLitterPuppies(999);
      viewModel.addItem();
      expect(viewModel.items.first.sex, equals('female'));

      viewModel.updateSex(0, 'male');
      expect(viewModel.items.first.sex, equals('male'));
    });

    test(
      'saveBatch inserts new puppies and reloads with assigned ids',
      () async {
        await viewModel.loadLitterPuppies(999); // empty
        viewModel.addItem();
        viewModel.addItem();
        viewModel.items.first.name = 'Rex';

        final result = await viewModel.saveBatch(999);
        expect(result, isTrue);

        // After the save+reload, the items carry their server-assigned ids.
        expect(viewModel.items.length, equals(2));
        expect(viewModel.items.every((i) => i.id != null), isTrue);
        expect(viewModel.items.any((i) => i.name == 'Rex'), isTrue);

        // Persisted to the repository.
        final dbList = await puppyRepo.getPuppies(999);
        expect(dbList.length, equals(2));
      },
    );

    test('saveBatch edits an existing puppy without duplicating it', () async {
      await viewModel.loadLitterPuppies(1); // 3 seeded puppies
      final originalCount = viewModel.items.length;
      viewModel.items.first.name = 'Nouveau nom';

      final result = await viewModel.saveBatch(1);
      expect(result, isTrue);

      // Same count (no duplication), edited name reflected.
      expect(viewModel.items.length, equals(originalCount));
      expect(viewModel.items.first.name, equals('Nouveau nom'));

      final dbList = await puppyRepo.getPuppies(1);
      expect(dbList.length, equals(originalCount));
      expect(dbList.any((p) => p.name == 'Nouveau nom'), isTrue);
    });

    test('saveBatch dropping a row deletes that puppy', () async {
      await viewModel.loadLitterPuppies(1); // 3 seeded puppies
      viewModel.removeItem(0);

      final result = await viewModel.saveBatch(1);
      expect(result, isTrue);

      expect(viewModel.items.length, equals(2));
      final dbList = await puppyRepo.getPuppies(1);
      expect(dbList.length, equals(2));
    });

    test('saveBatch twice with no change is idempotent (same ids)', () async {
      await viewModel.loadLitterPuppies(999);
      viewModel.addItem();
      viewModel.addItem();

      await viewModel.saveBatch(999);
      final idsAfterFirst = viewModel.items.map((i) => i.id).toList()..sort();

      await viewModel.saveBatch(999);
      final idsAfterSecond = viewModel.items.map((i) => i.id).toList()..sort();

      expect(viewModel.items.length, equals(2));
      expect(idsAfterSecond, equals(idsAfterFirst));
    });

    test('youngNounPlural and capitalized reflect the species', () async {
      await viewModel.loadLitterPuppies(999);
      expect(viewModel.youngNoun, equals('chiot'));
      expect(viewModel.youngNounPlural, equals('chiots'));
      expect(viewModel.youngNounCapitalized, equals('Chiot'));

      await kennelRepo.createKennel(
        Kennel(name: 'Chatterie', species: 'cat', createdAt: DateTime.now()),
      );
      await viewModel.loadLitterPuppies(999);
      expect(viewModel.youngNoun, equals('chaton'));
      expect(viewModel.youngNounPlural, equals('chatons'));
    });
  });

  group('GroupWeighingViewModel', () {
    late MockPuppyRepository puppyRepo;
    late MockWeighingRepository weighingRepo;
    late GroupWeighingViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      puppyRepo = MockPuppyRepository();
      weighingRepo = MockWeighingRepository();
      viewModel = GroupWeighingViewModel(
        puppyRepository: puppyRepo,
        weighingRepository: weighingRepo,
      );
    });

    test('loadLitterPuppies populates items with last weights', () async {
      await viewModel.loadLitterPuppies(1);

      expect(viewModel.items.length, equals(3));
      expect(viewModel.items[0].name, equals('Chiot 1 (Orphée)'));
      // Puppy 1 last weight in db is 1800.0
      expect(viewModel.items[0].lastWeight, equals(1800.0));
      // Puppy 3 last weight in db is 690.0
      expect(viewModel.items[2].lastWeight, equals(690.0));
    });

    test('saveWeighingSession records new weights', () async {
      await viewModel.loadLitterPuppies(1);

      viewModel.updateWeight(0, 1900.0);
      viewModel.updateWeight(1, 1400.0);
      // Leave Puppy 3 unchanged

      final result = await viewModel.saveWeighingSession();
      expect(result, isTrue);

      // Verify Puppy 1 weights
      final weighings1 = await weighingRepo.getWeighings(1);
      expect(weighings1.last.weightGrams, equals(1900.0));

      // Verify Puppy 2 weights
      final weighings2 = await weighingRepo.getWeighings(2);
      expect(weighings2.last.weightGrams, equals(1400.0));
    });
  });

  group('PuppyFileViewModel', () {
    late MockPuppyRepository puppyRepo;
    late MockWeighingRepository weighingRepo;
    late MockCareRepository careRepo;
    late MockSettingsRepository settingsRepo;
    late PuppyFileViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      puppyRepo = MockPuppyRepository();
      weighingRepo = MockWeighingRepository();
      careRepo = MockCareRepository();
      settingsRepo = MockSettingsRepository();
      viewModel = PuppyFileViewModel(
        puppyRepository: puppyRepo,
        weighingRepository: weighingRepo,
        careRepository: careRepo,
        settingsRepository: settingsRepo,
      );
    });

    test('loadPuppyFile loads puppy, weighings, and care history', () async {
      await viewModel.loadPuppyFile(1);

      expect(viewModel.puppy, isNotNull);
      expect(viewModel.puppy!.id, equals(1));
      expect(viewModel.weighings.length, equals(4));
      expect(viewModel.careTimeline.length, equals(1));
    });

    test('updateStatus changes status in repository', () async {
      await viewModel.loadPuppyFile(1);
      expect(viewModel.puppy!.status, equals('available'));

      await viewModel.updateStatus('reserved');
      expect(viewModel.puppy!.status, equals('reserved'));

      final updated = await puppyRepo.getPuppy(1);
      expect(updated!.status, equals('reserved'));
    });

    test('saveBuyerInfo updates buyer details', () async {
      await viewModel.loadPuppyFile(1);

      await viewModel.saveBuyerInfo(
        name: 'Alice',
        phone: '123456',
        email: 'alice@email.com',
        address: 'Lyon',
      );

      final updated = await puppyRepo.getPuppy(1);
      expect(updated!.buyerName, equals('Alice'));
      expect(updated.buyerPhone, equals('123456'));
      expect(updated.buyerEmail, equals('alice@email.com'));
      expect(updated.buyerAddress, equals('Lyon'));
    });

    test(
      'addSingleWeight appends weight entry and reloads weighings',
      () async {
        await viewModel.loadPuppyFile(1);
        expect(viewModel.weighings.length, equals(4));

        await viewModel.addSingleWeight(1950.0);
        expect(viewModel.weighings.length, equals(5));
        expect(viewModel.weighings.last.weightGrams, equals(1950.0));
      },
    );
  });

  group('AddCareViewModel', () {
    late MockPuppyRepository puppyRepo;
    late MockCareRepository careRepo;
    late AddCareViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      puppyRepo = MockPuppyRepository();
      careRepo = MockCareRepository();
      viewModel = AddCareViewModel(
        puppyRepository: puppyRepo,
        careRepository: careRepo,
      );
    });

    test('saveCareEntry saves care for individual puppy', () async {
      final result = await viewModel.saveCareEntry(
        type: 'vaccine',
        product: 'Rabigen',
        date: DateTime.now(),
        puppyId: 1,
      );

      expect(result, isTrue);

      final care = await careRepo.getCareEntries(puppyId: 1);
      expect(care.length, equals(2));
      expect(care.any((c) => c.product == 'Rabigen'), isTrue);
    });

    test('saveCareEntry saves care for all puppies in litter', () async {
      final result = await viewModel.saveCareEntry(
        type: 'deworming',
        product: 'Milbemax',
        date: DateTime.now(),
        litterId: 1,
        targetAllLitter: true,
      );

      expect(result, isTrue);

      // Verify litter care entry is created
      final litterCare = await careRepo.getCareEntries(litterId: 1);
      expect(
        litterCare.length,
        equals(2),
      ); // Milbemax Chiot (from DB init) + Milbemax

      // Verify puppy care entry is created for Puppy 1, 2, and 3
      final puppy1Care = await careRepo.getCareEntries(puppyId: 1);
      final puppy2Care = await careRepo.getCareEntries(puppyId: 2);
      final puppy3Care = await careRepo.getCareEntries(puppyId: 3);

      expect(puppy1Care.any((c) => c.product == 'Milbemax'), isTrue);
      expect(puppy2Care.any((c) => c.product == 'Milbemax'), isTrue);
      expect(puppy3Care.any((c) => c.product == 'Milbemax'), isTrue);
    });
  });
}
