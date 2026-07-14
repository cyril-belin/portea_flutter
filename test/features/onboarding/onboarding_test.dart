import 'package:flutter_test/flutter_test.dart';
import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/features/onboarding/data/repositories/mock_kennel_repository.dart';
import 'package:portea_flutter/features/onboarding/presentation/view_models/onboarding_view_model.dart';

void main() {
  group('MockKennelRepository', () {
    late MockKennelRepository repository;

    setUp(() {
      repository = MockKennelRepository();
    });

    test('should start with null kennel and allow creation and retrieval', () async {
      var kennel = await repository.getKennel();
      expect(kennel, isNull);

      final newKennel = Kennel(
        name: 'Élevage Test',
        species: 'dog',
        createdAt: DateTime.now(),
      );

      final created = await repository.createKennel(newKennel);
      expect(created.name, equals('Élevage Test'));

      kennel = await repository.getKennel();
      expect(kennel, isNotNull);
      expect(kennel!.name, equals('Élevage Test'));
    });

    test('should allow updating kennel', () async {
      final newKennel = Kennel(
        name: 'Élevage Initial',
        species: 'dog',
        createdAt: DateTime.now(),
      );

      await repository.createKennel(newKennel);
      
      final updatedKennel = Kennel(
        name: 'Élevage Mis à Jour',
        species: 'cat',
        createdAt: DateTime.now(),
      );

      await repository.updateKennel(updatedKennel);
      final retrieved = await repository.getKennel();
      expect(retrieved!.name, equals('Élevage Mis à Jour'));
      expect(retrieved.species, equals('cat'));
    });
  });

  group('OnboardingViewModel', () {
    late MockKennelRepository repository;
    late OnboardingViewModel viewModel;

    setUp(() {
      repository = MockKennelRepository();
      viewModel = OnboardingViewModel(kennelRepository: repository);
    });

    test('initial states', () {
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.isOnboardingCompleted, isFalse);
      expect(viewModel.kennelName, isEmpty);
      expect(viewModel.species, equals('dog'));
      expect(viewModel.affix, isEmpty);
    });

    test('setting properties notifies listeners', () {
      var listenerCalled = false;
      viewModel.addListener(() {
        listenerCalled = true;
      });

      viewModel.kennelName = 'New Kennel';
      expect(listenerCalled, isTrue);
      expect(viewModel.kennelName, equals('New Kennel'));

      listenerCalled = false;
      viewModel.species = 'cat';
      expect(listenerCalled, isTrue);
      expect(viewModel.species, equals('cat'));

      listenerCalled = false;
      viewModel.affix = 'des Terres Dorées';
      expect(listenerCalled, isTrue);
      expect(viewModel.affix, equals('des Terres Dorées'));
    });

    test('completeOnboarding marks completion', () {
      expect(viewModel.isOnboardingCompleted, isFalse);
      viewModel.completeOnboarding();
      expect(viewModel.isOnboardingCompleted, isTrue);
    });

    test('createKennel fails with empty name', () async {
      viewModel.kennelName = '';
      final result = await viewModel.createKennel();
      expect(result, isFalse);
      expect(viewModel.isLoading, isFalse);
    });

    test('createKennel succeeds and calls repository', () async {
      viewModel.kennelName = 'My Kennel';
      viewModel.species = 'dog';
      viewModel.affix = 'Affix';

      final result = await viewModel.createKennel();
      expect(result, isTrue);
      expect(viewModel.isLoading, isFalse);

      final saved = await repository.getKennel();
      expect(saved, isNotNull);
      expect(saved!.name, equals('My Kennel'));
      expect(saved.species, equals('dog'));
      expect(saved.affix, equals('Affix'));
    });
  });
}
