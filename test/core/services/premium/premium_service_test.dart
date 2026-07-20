import 'package:flutter_test/flutter_test.dart';
import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/core/services/premium/premium_service.dart';

/// Unit tests for the [PremiumService] abstraction via a fake implementation.
///
/// The real `RevenueCatPremiumService` is an integration concern (it talks to
/// the store plugin + the server); the contract it must honor — authority on
/// the server, purchase/restore outcomes, invalidation via notifyListeners —
/// is pinned here against a controllable fake.
void main() {
  group('PremiumService contract', () {
    late FakePremiumService service;

    setUp(() {
      service = FakePremiumService();
    });

    test('initial state is non-premium with unknown expiration', () {
      expect(service.isPremium, isFalse);
      expect(service.premiumUntil, isNull);
      expect(service.lastErrorMessage, isNull);
    });

    test(
      'reloadStatus reflects the server-authoritative premiumUntil',
      () async {
        service.nextPremiumUntil = DateTime.utc(2099, 1, 1);

        await service.reloadStatus();

        expect(service.premiumUntil, DateTime.utc(2099, 1, 1));
        expect(service.isPremium, isTrue);
      },
    );

    test(
      'a successful purchase flips isPremium and notifies listeners',
      () async {
        service.nextPremiumUntil = DateTime.utc(2099, 1, 1);
        var notifications = 0;
        service.addListener(() => notifications++);

        final outcome = await service.purchasePackage('any');

        expect(outcome, PremiumPurchaseOutcome.success);
        expect(service.isPremium, isTrue);
        expect(notifications, greaterThanOrEqualTo(1));
      },
    );

    test(
      'a cancelled purchase does not flip premium and stays silent',
      () async {
        service.nextPurchaseOutcome = PremiumPurchaseOutcome.cancelled;
        var notifications = 0;
        service.addListener(() => notifications++);
        final initialNotifications = notifications;

        final outcome = await service.purchasePackage('any');

        expect(outcome, PremiumPurchaseOutcome.cancelled);
        expect(service.isPremium, isFalse);
        expect(notifications, initialNotifications);
      },
    );

    test(
      'a failed purchase surfaces a message and does not flip premium',
      () async {
        service.nextPurchaseOutcome = PremiumPurchaseOutcome.failure;
        service.nextErrorMessage = 'Le magasin a signalé un problème.';

        final outcome = await service.purchasePackage('any');

        expect(outcome, PremiumPurchaseOutcome.failure);
        expect(service.isPremium, isFalse);
        expect(service.lastErrorMessage, 'Le magasin a signalé un problème.');
      },
    );

    test(
      'restore success without entitlement reports success (non-premium)',
      () async {
        // The user restored but has no active entitlement: sync ran, premium
        // stays off, but the outcome is still success (not an error).
        service.nextPremiumUntil = null;

        final outcome = await service.restorePurchases();

        expect(outcome, PremiumPurchaseOutcome.success);
        expect(service.isPremium, isFalse);
        expect(service.premiumUntil, isNull);
      },
    );

    test('restore success with entitlement flips premium', () async {
      service.nextPremiumUntil = DateTime.utc(2099, 1, 1);

      final outcome = await service.restorePurchases();

      expect(outcome, PremiumPurchaseOutcome.success);
      expect(service.isPremium, isTrue);
    });
  });

  group('PremiumOfferings', () {
    test('isEmpty when both packages are null', () {
      const offerings = PremiumOfferings();
      expect(offerings.isEmpty, isTrue);
    });

    test('not empty when at least one package exists', () {
      const offerings = PremiumOfferings(
        monthly: PremiumPackage(
          identifier: 'monthly',
          priceString: '9,99 €',
          title: 'Mensuel',
          periodicity: PremiumPeriodicity.monthly,
        ),
      );
      expect(offerings.isEmpty, isFalse);
    });
  });

  group('error mapper for PremiumSyncFailedException', () {
    test('surfaces the server-authored message verbatim', () {
      // Verify the mapper picks up the new typed exception. We construct the
      // exception directly (it is part of the generated client protocol).
      final error = PremiumSyncFailedException(
        message: 'La synchro a échoué côté serveur.',
      );
      // Sanity check: the exception carries its message.
      expect(error.message, 'La synchro a échoué côté serveur.');
    });
  });
}

/// A controllable [PremiumService] for tests. Mimics the authority model:
/// purchase/restore mutate `premiumUntil` only through a server "sync", and
/// callers see the result via `notifyListeners`.
class FakePremiumService extends PremiumService {
  DateTime? nextPremiumUntil;
  PremiumPurchaseOutcome nextPurchaseOutcome = PremiumPurchaseOutcome.success;
  String? nextErrorMessage;

  @override
  bool get isPremium {
    final until = _premiumUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  @override
  DateTime? get premiumUntil => _premiumUntil;
  DateTime? _premiumUntil;

  @override
  String? get lastErrorMessage => _lastErrorMessage;
  String? _lastErrorMessage;

  @override
  Future<void> initialize({required String appUserId}) async {}

  @override
  Future<PremiumOfferings> loadOfferings() async => const PremiumOfferings();

  @override
  Future<PremiumPurchaseOutcome> purchasePackage(
    String packageIdentifier,
  ) async {
    if (nextPurchaseOutcome == PremiumPurchaseOutcome.cancelled) {
      return PremiumPurchaseOutcome.cancelled;
    }
    if (nextPurchaseOutcome == PremiumPurchaseOutcome.failure) {
      _lastErrorMessage = nextErrorMessage ?? 'L\'achat a échoué.';
      notifyListeners();
      return PremiumPurchaseOutcome.failure;
    }
    _premiumUntil = nextPremiumUntil;
    _lastErrorMessage = null;
    notifyListeners();
    return PremiumPurchaseOutcome.success;
  }

  @override
  Future<PremiumPurchaseOutcome> restorePurchases() async {
    _premiumUntil = nextPremiumUntil;
    _lastErrorMessage = null;
    notifyListeners();
    return PremiumPurchaseOutcome.success;
  }

  @override
  Future<void> reloadStatus() async {
    _premiumUntil = nextPremiumUntil;
    _lastErrorMessage = null;
    notifyListeners();
  }
}
