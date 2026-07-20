import 'package:flutter/foundation.dart';

/// Outcome of a purchase or restore attempt.
///
/// The UI never reads the premium status from RevenueCat directly — the server
/// is the single authority. After a successful purchase/restore, the client
/// triggers a server sync and reloads the state from there. This enum only
/// describes the purchase flow itself.
enum PremiumPurchaseOutcome {
  /// Purchase/restore succeeded and the server confirmed the new premium state.
  success,

  /// The user dismissed the store sheet (iOS "Cancel", Android back). This is
  /// NOT an error — the UI returns silently.
  cancelled,

  /// Any other failure (network, store problem, sync refused...). The caller
  /// surfaces [PremiumService.lastErrorMessage].
  failure,
}

/// A store package presented to the user, with its localized price string and
/// a stable identifier the service can use to trigger the purchase.
class PremiumPackage {
  const PremiumPackage({
    required this.identifier,
    required this.priceString,
    required this.title,
    required this.periodicity,
  });

  /// RevenueCat package identifier (e.g. `$rc_annual`, `$rc_monthly`).
  final String identifier;

  /// Localized, currency-aware price label straight from the store
  /// (e.g. "89,99 €"). Never hardcoded client-side.
  final String priceString;

  /// Localized product title from the store.
  final String title;

  /// Billing periodicity, for the annual/monthly toggle.
  final PremiumPeriodicity periodicity;
}

enum PremiumPeriodicity { annual, monthly }

/// The offerings currently available (annual + monthly packages), or none.
class PremiumOfferings {
  const PremiumOfferings({this.annual, this.monthly});

  final PremiumPackage? annual;
  final PremiumPackage? monthly;

  bool get isEmpty => annual == null && monthly == null;
}

/// Wraps the RevenueCat SDK (client) and the server sync that follows a
/// purchase or restore.
///
/// Authority model: this service TRIGGERS premium changes, it never writes the
/// status. After any successful RevenueCat operation it calls
/// `client.kennel.syncPremiumStatus()`, and the server — and only the server —
/// recomputes `Kennel.premiumUntil` from the RevenueCat REST API.
///
/// Extends [ChangeNotifier] so the 5 view models that gate on premium can
/// refresh automatically after a successful purchase/restore (the invalidation
/// circuit — see `main.dart` wiring and the dedicated test).
abstract class PremiumService extends ChangeNotifier {
  /// `null` while the status is unknown (initial load in flight). A non-null
  /// value is the authoritative premium expiry from the server.
  DateTime? get premiumUntil;

  /// True iff [premiumUntil] is strictly in the future. Convenience for UI.
  bool get isPremium;

  /// Last user-facing error message from a purchase/restore attempt, or null.
  String? get lastErrorMessage;

  /// Initializes RevenueCat with [appUserId] (the authenticated Serverpod user
  /// id) and loads the current premium state from the server. Idempotent.
  ///
  /// Called once after authentication resolves (same hook point as the kennel
  /// and reminder rescheduling — see `OnboardingViewModel._onAuthChanged`).
  Future<void> initialize({required String appUserId});

  /// Returns the current RevenueCat offerings, or an empty result if none are
  /// available (SDK not configured, no store products yet). Never throws.
  Future<PremiumOfferings> loadOfferings();

  /// Purchases the package identified by [packageIdentifier], then asks the
  /// server to sync the new entitlement. Returns the outcome; on success the
  /// server-confirmed [premiumUntil] is up to date and listeners are notified.
  Future<PremiumPurchaseOutcome> purchasePackage(String packageIdentifier);

  /// Restores previous purchases, then asks the server to sync. Same contract
  /// as [purchasePackage]. A restore with no active entitlement still reports
  /// [PremiumPurchaseOutcome.success] (the sync ran; the user simply has no
  /// active subscription).
  Future<PremiumPurchaseOutcome> restorePurchases();

  /// Reloads the premium status from the server (no RevenueCat call). Used
  /// after sign-out / re-login and by callers that only want a fresh read.
  Future<void> reloadStatus();
}
