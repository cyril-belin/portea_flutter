import 'package:flutter_test/flutter_test.dart';
import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/core/data/mock_database.dart';
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

    test('createPuppiesBatch adds puppies of that litter to DB', () async {
      final listBefore = await repository.getPuppies(1);
      expect(listBefore.length, equals(3));

      final batch = <Puppy>[
        Puppy(id: 10, litterId: 1, name: 'Nouveau Chiot 1', sex: 'female', birthWeight: 310, status: 'available'),
        Puppy(id: 11, litterId: 1, name: 'Nouveau Chiot 2', sex: 'male', birthWeight: 320, status: 'available'),
      ];

      await repository.createPuppiesBatch(batch);

      final listAfter = await repository.getPuppies(1);
      expect(listAfter.length, equals(5));
      expect(listAfter.any((p) => p.name == 'Nouveau Chiot 1'), isTrue);
    });

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
      final entry1 = WeighingEntry(puppyId: 1, weighedAt: DateTime.now(), weightGrams: 2100);
      final entry2 = WeighingEntry(puppyId: 2, weighedAt: DateTime.now(), weightGrams: 1500);

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
      expect(reminders.length, equals(1)); // Milbemax deworming has reminder in 7 days
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
    late PuppyBatchViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      puppyRepo = MockPuppyRepository();
      viewModel = PuppyBatchViewModel(puppyRepository: puppyRepo);
    });

    test('loadLitterPuppies pre-fills with existing puppies', () async {
      final existing = await puppyRepo.getPuppies(1);
      viewModel.loadLitterPuppies(existing);

      expect(viewModel.items.length, equals(3));
      expect(viewModel.items[0].name, equals('Chiot 1 (Orphée)'));
    });

    test('loadLitterPuppies pre-fills with defaults when litter is empty', () {
      viewModel.loadLitterPuppies([]);
      expect(viewModel.items.length, equals(3));
      expect(viewModel.items[0].name, equals('Chiot 1'));
    });

    test('addItem and removeItem modify items count', () {
      viewModel.loadLitterPuppies([]);
      expect(viewModel.items.length, equals(3));

      viewModel.addItem();
      expect(viewModel.items.length, equals(4));
      expect(viewModel.items.last.name, equals('Chiot 4'));

      viewModel.removeItem(3);
      expect(viewModel.items.length, equals(3));
    });

    test('updateSex modifies sex of item', () {
      viewModel.loadLitterPuppies([]);
      expect(viewModel.items[0].sex, equals('female'));

      viewModel.updateSex(0, 'male');
      expect(viewModel.items[0].sex, equals('male'));
    });

    test('saveBatch saves puppies to repository', () async {
      viewModel.loadLitterPuppies([]); // fills Chiot 1, 2, 3
      final result = await viewModel.saveBatch(1);
      expect(result, isTrue);

      final dbList = await puppyRepo.getPuppies(1);
      expect(dbList.length, equals(6)); // 3 original + 3 saved
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

    test('addSingleWeight appends weight entry and reloads weighings', () async {
      await viewModel.loadPuppyFile(1);
      expect(viewModel.weighings.length, equals(4));

      await viewModel.addSingleWeight(1950.0);
      expect(viewModel.weighings.length, equals(5));
      expect(viewModel.weighings.last.weightGrams, equals(1950.0));
    });
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
      expect(litterCare.length, equals(2)); // Milbemax Chiot (from DB init) + Milbemax

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
