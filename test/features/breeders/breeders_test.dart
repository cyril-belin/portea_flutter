import 'package:flutter_test/flutter_test.dart';
import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/core/data/mock_database.dart';
import 'package:portea_flutter/features/breeders/data/repositories/mock_breeder_repository.dart';
import 'package:portea_flutter/features/breeders/presentation/view_models/breeder_list_view_model.dart';
import 'package:portea_flutter/features/breeders/presentation/view_models/breeder_profile_view_model.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('MockBreederRepository', () {
    late MockBreederRepository repository;

    setUp(() {
      resetMockDatabase();
      repository = MockBreederRepository();
    });

    test('getBreeders returns all breeders', () async {
      final breeders = await repository.getBreeders();
      expect(breeders.length, equals(2));
      expect(breeders[0].name, equals('Salsa'));
      expect(breeders[1].name, equals('Ramses'));
    });

    test('getBreeder returns breeder by ID', () async {
      final breeder = await repository.getBreeder(1);
      expect(breeder, isNotNull);
      expect(breeder!.name, equals('Salsa'));

      final nonExistent = await repository.getBreeder(999);
      expect(nonExistent, isNull);
    });

    test('createBreeder adds to DB and returns it with a new ID', () async {
      final newBreeder = Breeder(
        name: 'Tango',
        sex: 'male',
        breed: 'Golden Retriever',
        status: 'active',
        kennelId: 1,
      );

      final created = await repository.createBreeder(newBreeder);
      expect(created.id, isNotNull);
      expect(created.name, equals('Tango'));

      final list = await repository.getBreeders();
      expect(list.length, equals(3));
      expect(list.any((b) => b.name == 'Tango'), isTrue);
    });

    test('updateBreeder updates the values in DB', () async {
      final breeder = await repository.getBreeder(1);
      expect(breeder!.status, equals('active'));

      breeder.status = 'retired';
      await repository.updateBreeder(breeder);

      final updated = await repository.getBreeder(1);
      expect(updated!.status, equals('retired'));
    });
  });

  group('BreederListViewModel', () {
    late MockBreederRepository repository;
    late BreederListViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      repository = MockBreederRepository();
      viewModel = BreederListViewModel(breederRepository: repository);
    });

    test('initial states', () {
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.breeders, isEmpty);
    });

    test('loadBreeders loads breeders', () async {
      final future = viewModel.loadBreeders();
      expect(viewModel.isLoading, isTrue);

      await future;

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.breeders.length, equals(2));
    });
  });

  group('BreederProfileViewModel', () {
    late MockBreederRepository repository;
    late BreederProfileViewModel viewModel;

    setUp(() {
      resetMockDatabase();
      repository = MockBreederRepository();
      viewModel = BreederProfileViewModel(breederRepository: repository);
    });

    test('initial states', () {
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.breeder, isNull);
    });

    test('loadBreeder loads a breeder and sets state', () async {
      final future = viewModel.loadBreeder(1);
      expect(viewModel.isLoading, isTrue);

      await future;

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.breeder, isNotNull);
      expect(viewModel.breeder!.name, equals('Salsa'));
    });

    test('setupNewBreeder resets breeder to null', () async {
      await viewModel.loadBreeder(1);
      expect(viewModel.breeder, isNotNull);

      viewModel.setupNewBreeder();
      expect(viewModel.breeder, isNull);
    });

    test(
      'saveBreeder creates new breeder when state breeder is null',
      () async {
        viewModel.setupNewBreeder();

        final result = await viewModel.saveBreeder(
          name: 'Shadow',
          sex: 'male',
          breed: 'Border Collie',
          birthDate: DateTime(2025, 1, 1),
          chipNumber: '123456',
          tattooNumber: '',
          status: 'active',
        );

        expect(result, isTrue);

        final dbList = MockDatabase.instance.breeders;
        expect(dbList.length, equals(3));
        expect(dbList.last.name, equals('Shadow'));
        expect(dbList.last.chipNumber, equals('123456'));
        expect(dbList.last.tattooNumber, isNull);
      },
    );

    test('saveBreeder updates breeder when state breeder is loaded', () async {
      await viewModel.loadBreeder(1);
      expect(viewModel.breeder!.name, equals('Salsa'));

      final result = await viewModel.saveBreeder(
        name: 'Salsa Modifiée',
        sex: 'female',
        breed: 'Golden Retriever',
        birthDate: DateTime(2023, 5, 5),
        chipNumber: '',
        tattooNumber: 'TAT123',
        status: 'retired',
      );

      expect(result, isTrue);

      final dbList = MockDatabase.instance.breeders;
      expect(dbList.length, equals(2));
      final updated = dbList.firstWhere((b) => b.id == 1);
      expect(updated.name, equals('Salsa Modifiée'));
      expect(updated.chipNumber, isNull);
      expect(updated.tattooNumber, equals('TAT123'));
      expect(updated.status, equals('retired'));
    });
  });
}
