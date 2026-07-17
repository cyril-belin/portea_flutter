import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portea_client/portea_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:portea_flutter/core/errors/operation_state.dart';
import 'package:portea_flutter/features/breeders/data/repositories/mock_breeder_repository.dart';
import 'package:portea_flutter/features/litters/data/repositories/mock_litter_repository.dart';
import 'package:portea_flutter/features/onboarding/data/repositories/mock_kennel_repository.dart';
import 'package:portea_flutter/features/onboarding/presentation/view_models/onboarding_view_model.dart';
import 'package:portea_flutter/features/puppies/data/repositories/mock_care_repository.dart';
import 'package:portea_flutter/features/puppies/data/repositories/mock_puppy_repository.dart';

import '../../helpers/mock_notification_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });
  group('MockKennelRepository', () {
    late MockKennelRepository repository;

    setUp(() {
      repository = MockKennelRepository();
    });

    test(
      'should start with null kennel and allow creation and retrieval',
      () async {
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
      },
    );

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

    test('initial state is idle and not busy', () {
      expect(viewModel.state, OperationState.idle);
      expect(viewModel.isBusy, isFalse);
      expect(viewModel.isOnboardingCompleted, isFalse);
      expect(viewModel.kennelName, isEmpty);
      expect(viewModel.species, equals('dog'));
      expect(viewModel.affix, isEmpty);
      expect(viewModel.errorMessage, isNull);
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

    test('completeOnboarding marks completion', () async {
      expect(viewModel.isOnboardingCompleted, isFalse);
      await viewModel.completeOnboarding();
      expect(viewModel.isOnboardingCompleted, isTrue);
    });

    test('createKennel fails with empty name', () async {
      viewModel.kennelName = '';
      final result = await viewModel.createKennel();
      expect(result, isFalse);
      expect(viewModel.isBusy, isFalse);
    });

    test('createKennel succeeds and calls repository', () async {
      viewModel.kennelName = 'My Kennel';
      viewModel.species = 'dog';
      viewModel.affix = 'Affix';

      final result = await viewModel.createKennel();
      expect(result, isTrue);
      expect(viewModel.isBusy, isFalse);
      expect(viewModel.state, OperationState.success);
      // Kennel created but onboarding NOT complete until notifications screen.
      expect(viewModel.hasKennel, isTrue);
      expect(viewModel.isOnboardingCompleted, isFalse);

      final saved = await repository.getKennel();
      expect(saved, isNotNull);
      expect(saved!.name, equals('My Kennel'));
      expect(saved.species, equals('dog'));
      expect(saved.affix, equals('Affix'));
    });

    test(
      'createKennel repository failure surfaces errorMessage and returns false',
      () async {
        viewModel.kennelName = 'My Kennel';
        repository.throwOnNext = const ServerpodClientException('boom', -1);

        final result = await viewModel.createKennel();

        expect(result, isFalse);
        expect(viewModel.state, OperationState.error);
        expect(viewModel.errorMessage, isNotNull);
      },
    );
  });

  group('OnboardingViewModel auth-driven completion', () {
    setUp(() {
      // Reset SharedPreferences before each test to avoid cross-test
      // contamination of the persisted onboarding-completed flag.
      SharedPreferences.setMockInitialValues({});
    });

    /// Simple bool listenable that mimics the AuthenticatedListenable adapter
    /// used in production, so the VM stays testable without a real client.
    ValueNotifier<bool> authListenable({bool initial = false}) =>
        ValueNotifier<bool>(initial);

    /// Pumps the event queue enough times for the VM's async `_onAuthChanged`
    /// chain (await getKennel + notifyListeners) to settle. The mock repository
    /// simulates a 200ms network delay, so we wait past that.
    Future<void> settle() async {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    test('is unauthenticated and incomplete when auth is false', () {
      final vm = OnboardingViewModel(
        kennelRepository: MockKennelRepository(),
        authListenable: authListenable(initial: false),
      );
      expect(vm.isAuthenticated, isFalse);
      expect(vm.isOnboardingCompleted, isFalse);
      expect(vm.needsKennelSetup, isFalse);
    });

    test('marks needsKennelSetup when authenticated but no kennel', () async {
      final vm = OnboardingViewModel(
        kennelRepository: MockKennelRepository(), // getKennel() -> null
        authListenable: authListenable(initial: true),
      );
      await settle();
      expect(vm.isAuthenticated, isTrue);
      expect(vm.isOnboardingCompleted, isFalse);
      expect(vm.needsKennelSetup, isTrue);
    });

    test(
      'cold start with kennel and completed flag -> dashboard ready',
      () async {
        // Simulate a returning user: kennel exists AND onboarding was completed.
        SharedPreferences.setMockInitialValues({'onboarding_completed': true});
        final repo = MockKennelRepository();
        await repo.createKennel(
          Kennel(name: 'Existing', species: 'dog', createdAt: DateTime.now()),
        );

        final vm = OnboardingViewModel(
          kennelRepository: repo,
          authListenable: authListenable(initial: true),
        );
        await settle();

        expect(vm.isAuthenticated, isTrue);
        expect(vm.hasKennel, isTrue);
        expect(vm.isOnboardingCompleted, isTrue);
        expect(vm.needsKennelSetup, isFalse);
      },
    );

    test(
      'kennel exists but onboarding not finished -> needs notifications',
      () async {
        // Mid-flow: kennel created but notifications screen not yet passed.
        SharedPreferences.setMockInitialValues({});
        final repo = MockKennelRepository();
        await repo.createKennel(
          Kennel(name: 'Existing', species: 'dog', createdAt: DateTime.now()),
        );

        final vm = OnboardingViewModel(
          kennelRepository: repo,
          authListenable: authListenable(initial: true),
        );
        await settle();

        expect(vm.isAuthenticated, isTrue);
        expect(vm.hasKennel, isTrue);
        expect(
          vm.isOnboardingCompleted,
          isFalse,
        ); // must still pass notifications
        expect(vm.needsKennelSetup, isFalse); // kennel already exists
      },
    );

    test('completeOnboarding persists and survives a new instance', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockKennelRepository();
      await repo.createKennel(
        Kennel(name: 'Existing', species: 'cat', createdAt: DateTime.now()),
      );

      final vm = OnboardingViewModel(
        kennelRepository: repo,
        authListenable: authListenable(initial: true),
      );
      await settle();
      expect(vm.isOnboardingCompleted, isFalse);

      await vm.completeOnboarding();
      expect(vm.isOnboardingCompleted, isTrue);

      // A fresh view model (simulating cold start) reads the persisted flag.
      final vm2 = OnboardingViewModel(
        kennelRepository: repo,
        authListenable: authListenable(initial: true),
      );
      await settle();
      expect(vm2.isOnboardingCompleted, isTrue);
    });

    test(
      'transitions to completed when auth flips on and onboarding was completed',
      () async {
        SharedPreferences.setMockInitialValues({'onboarding_completed': true});
        final repo = MockKennelRepository();
        await repo.createKennel(
          Kennel(
            name: 'Pre-existing',
            species: 'cat',
            createdAt: DateTime.now(),
          ),
        );
        final listenable = authListenable(initial: false);
        final vm = OnboardingViewModel(
          kennelRepository: repo,
          authListenable: listenable,
        );

        expect(vm.isOnboardingCompleted, isFalse);

        listenable.value = true;
        await settle();

        expect(vm.isOnboardingCompleted, isTrue);
      },
    );

    // ---- F07: re-schedule at startup with resolved target names ----

    test(
      'F07: on a cold start, re-schedules upcoming reminders with the '
      'resolved target name in the title (individual puppy + group litter)',
      () async {
        // Seed: litter 1 (mother Salsa id 1), puppies (id 1 "Chiot 1 (Orphée)"
        // etc.), and a group care entry (id 1, litterId=1, reminderAt future).
        resetMockDatabase();
        SharedPreferences.setMockInitialValues({'onboarding_completed': true});

        final kennelRepo = MockKennelRepository();
        await kennelRepo.createKennel(
          Kennel(name: 'Existing', species: 'dog', createdAt: DateTime.now()),
        );

        final careRepo = MockCareRepository();
        // Add an INDIVIDUAL future reminder (puppy 1) on top of the seeded
        // group reminder (litter 1). Both should be re-scheduled.
        await careRepo.addCareEntry(
          CareEntry(
            type: 'vaccine',
            product: 'Rabigen',
            appliedAt: DateTime.now(),
            puppyId: 1,
            reminderAt: DateTime.now().add(const Duration(days: 9)),
          ),
        );

        final notifications = MockNotificationService();
        final vm = OnboardingViewModel(
          kennelRepository: kennelRepo,
          careRepository: careRepo,
          puppyRepository: MockPuppyRepository(),
          litterRepository: MockLitterRepository(),
          breederRepository: MockBreederRepository(),
          notificationService: notifications,
          authListenable: authListenable(initial: true),
        );

        // Re-scheduling chains several async lookups (care + per-entry
        // puppy/litter/breeder), each with the mock's 100ms delay, so settle
        // longer than the default.
        await Future.delayed(const Duration(milliseconds: 1500));

        // Sanity: the auth+kennel+completed chain resolved, which is what gates
        // the re-scheduling. Without it, nothing would have been scheduled.
        expect(vm.isOnboardingCompleted, isTrue);
        expect(notifications.scheduled, isNotEmpty);

        // Both upcoming reminders are re-scheduled. The seeded group reminder
        // (litter 1, mother "Salsa") → "Portée de Salsa". The individual
        // reminder (puppy 1 "Chiot 1 (Orphée)") → its puppy name.
        final titles = notifications.scheduled.map((s) => s.title).toSet();
        expect(titles, contains('Rappel soin — Portée de Salsa'));
        expect(
          titles,
          contains('Rappel soin — Chiot 1 (Orphée)'),
        );
        // Payloads route correctly: group → /litters/1, individual → /puppies/1
        final payloads = notifications.scheduled.map((s) => s.payload).toSet();
        expect(payloads, containsAll(['/litters/1', '/puppies/1']));
        // Rule 4: re-scheduling never cancels.
        expect(notifications.cancelled, isEmpty);
      },
    );
  });
}
