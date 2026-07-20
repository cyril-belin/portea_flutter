import 'dart:io';

import 'package:flutter/services.dart';
import 'package:portea_client/portea_client.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'premium_service.dart';

/// RevenueCat-backed [PremiumService].
///
/// The public API key is platform-specific (iOS / Android) and is read from
/// `assets/config.json` by [PremiumConfig]. The secret server-side key lives
/// only on the server (`passwords.yaml`) — never here.
///
/// After every successful RevenueCat operation (purchase, restore) the server
/// is asked to recompute `Kennel.premiumUntil` via `kennel.syncPremiumStatus`;
/// the returned kennel drives [premiumUntil] and the [notifyListeners] call
/// that refreshes the dependent view models.
class RevenueCatPremiumService extends PremiumService {
  RevenueCatPremiumService({
    required Client client,
    required PremiumConfig config,
    DateTime Function() now = DateTime.now,
  }) : _client = client,
       _config = config,
       _now = now;

  final Client _client;
  final PremiumConfig _config;
  final DateTime Function() _now;

  DateTime? _premiumUntil;
  String? _lastErrorMessage;
  bool _initialized = false;

  @override
  DateTime? get premiumUntil => _premiumUntil;

  @override
  bool get isPremium {
    final until = _premiumUntil;
    return until != null && until.isAfter(_now());
  }

  @override
  String? get lastErrorMessage => _lastErrorMessage;

  @override
  Future<void> initialize({required String appUserId}) async {
    if (_initialized) return;
    final apiKey = _config.resolveApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      // SDK not configured (no store products yet). The service still works:
      // isPremium stays false, loadOfferings returns empty. No crash.
      _initialized = true;
      await reloadStatus();
      return;
    }
    try {
      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = appUserId,
      );
    } catch (_) {
      // A configure failure must not crash the app — premium simply stays
      // unavailable. The screen will show "offres indisponibles".
    }
    _initialized = true;
    await reloadStatus();
  }

  @override
  Future<PremiumOfferings> loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return _mapOfferings(offerings);
    } catch (_) {
      return const PremiumOfferings();
    }
  }

  @override
  Future<PremiumPurchaseOutcome> purchasePackage(
    String packageIdentifier,
  ) async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;
      if (offering == null) {
        _lastErrorMessage = _noOfferingsMessage;
        notifyListeners();
        return PremiumPurchaseOutcome.failure;
      }
      final package = offering.availablePackages.firstWhere(
        (p) => p.identifier == packageIdentifier,
      );
      await Purchases.purchasePackage(package);
      return await _syncAndNotify();
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return PremiumPurchaseOutcome.cancelled;
      }
      _lastErrorMessage = _purchaseErrorMessage(e);
      notifyListeners();
      return PremiumPurchaseOutcome.failure;
    } catch (e) {
      _lastErrorMessage = _syncErrorMessage;
      notifyListeners();
      return PremiumPurchaseOutcome.failure;
    }
  }

  @override
  Future<PremiumPurchaseOutcome> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
      return await _syncAndNotify();
    } catch (e) {
      _lastErrorMessage = _syncErrorMessage;
      notifyListeners();
      return PremiumPurchaseOutcome.failure;
    }
  }

  @override
  Future<void> reloadStatus() async {
    try {
      final kennel = await _client.kennel.syncPremiumStatus();
      _premiumUntil = kennel.premiumUntil;
      _lastErrorMessage = null;
    } catch (e) {
      // Reload failures are non-fatal: keep the previous status. The screen
      // shows the last known state rather than crashing.
      _lastErrorMessage = _syncErrorMessage;
    }
    notifyListeners();
  }

  /// Runs the post-purchase server sync. On [PremiumSyncFailedException] the
  /// failure is surfaced but the purchase itself did succeed — outcome is
  /// still failure because the user-facing state did not update.
  Future<PremiumPurchaseOutcome> _syncAndNotify() async {
    try {
      final kennel = await _client.kennel.syncPremiumStatus();
      _premiumUntil = kennel.premiumUntil;
      _lastErrorMessage = null;
      notifyListeners();
      return PremiumPurchaseOutcome.success;
    } on PremiumSyncFailedException catch (e) {
      // The server could not reach RevenueCat — the purchase went through the
      // store but the premium state is not confirmed. Surface the message.
      _lastErrorMessage = e.message;
      notifyListeners();
      return PremiumPurchaseOutcome.failure;
    } catch (_) {
      _lastErrorMessage = _syncErrorMessage;
      notifyListeners();
      return PremiumPurchaseOutcome.failure;
    }
  }

  PremiumOfferings _mapOfferings(Offerings offerings) {
    PremiumPackage? mapPackage(Package? pkg, PremiumPeriodicity periodicity) {
      if (pkg == null) return null;
      return PremiumPackage(
        identifier: pkg.identifier,
        priceString: pkg.storeProduct.priceString,
        title: pkg.storeProduct.title,
        periodicity: periodicity,
      );
    }

    final current = offerings.current;
    if (current == null) return const PremiumOfferings();
    return PremiumOfferings(
      annual: mapPackage(current.annual, PremiumPeriodicity.annual),
      monthly: mapPackage(current.monthly, PremiumPeriodicity.monthly),
    );
  }

  String _purchaseErrorMessage(PlatformException e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    if (code == PurchasesErrorCode.storeProblemError) {
      return 'Le magasin d\'applications a signalé un problème. Réessayez plus tard.';
    }
    if (code == PurchasesErrorCode.purchaseNotAllowedError ||
        code == PurchasesErrorCode.purchaseInvalidError) {
      return 'Cet achat n\'est pas autorisé sur cet appareil.';
    }
    if (code == PurchasesErrorCode.productNotAvailableForPurchaseError) {
      return 'Ce produit n\'est plus disponible à l\'achat.';
    }
    return 'L\'achat n\'a pas pu aboutir. Réessayez plus tard.';
  }
}

const String _syncErrorMessage =
    'Nous n\'avons pas pu confirmer votre abonnement. '
    'Réessayez depuis l\'écran Premium.';

const String _noOfferingsMessage =
    'Les offres Premium ne sont pas encore disponibles. '
    'Réessayez plus tard.';

/// Platform-specific RevenueCat public API keys, read from `assets/config.json`.
class PremiumConfig {
  const PremiumConfig({
    this.revenueCatApiKeyIos,
    this.revenueCatApiKeyAndroid,
  });

  final String? revenueCatApiKeyIos;
  final String? revenueCatApiKeyAndroid;

  /// Returns the key matching the current platform, or null if unset. The
  /// secret server key is NEVER part of this config — only public keys live
  /// in the app bundle.
  String? resolveApiKey() {
    if (Platform.isIOS) return revenueCatApiKeyIos;
    if (Platform.isAndroid) return revenueCatApiKeyAndroid;
    return null;
  }
}
