import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/premium/premium_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/settings_view_model.dart';
import '../../../dashboard/presentation/view_models/dashboard_view_model.dart';
import '../../../litters/presentation/view_models/litters_view_model.dart';
import '../../../puppies/presentation/view_models/puppy_file_view_model.dart';

/// Premium paywall.
///
/// Pricing comes from RevenueCat offerings (never hardcoded). A purchase or
/// restore triggers a server sync — the server is the single authority for
/// `Kennel.premiumUntil`. The success message ("Félicitations") shows ONLY
/// after the server confirms the new state, never on the client's say-so.
///
/// The screen survives a non-configured store (no offerings yet): it shows a
/// clean "offres indisponibles" message instead of crashing.
class PorteaPremiumScreen extends StatefulWidget {
  const PorteaPremiumScreen({super.key});

  @override
  State<PorteaPremiumScreen> createState() => _PorteaPremiumScreenState();
}

class _PorteaPremiumScreenState extends State<PorteaPremiumScreen> {
  PremiumPeriodicity _selectedPeriodicity = PremiumPeriodicity.annual;
  PremiumOfferings? _offerings;
  bool _loadingOfferings = true;
  bool _purchaseInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final service = context.read<PremiumService>();
    setState(() => _loadingOfferings = true);
    final offerings = await service.loadOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        // If the annual package is missing but monthly exists, switch the
        // selection so the user lands on an available option.
        if (offerings.annual == null && offerings.monthly != null) {
          _selectedPeriodicity = PremiumPeriodicity.monthly;
        }
        _loadingOfferings = false;
      });
    }
  }

  PremiumPackage? get _selectedPackage {
    final offerings = _offerings;
    if (offerings == null) return null;
    return _selectedPeriodicity == PremiumPeriodicity.annual
        ? offerings.annual
        : offerings.monthly;
  }

  /// Triggers a purchase, then reloads every view model that gates on premium
  /// so they reflect the new server-authoritative state (the invalidation
  /// circuit — tested in the settings test suite).
  Future<void> _onPurchaseOrManagePressed() async {
    if (_purchaseInProgress) return;

    // If already premium, no purchase button makes sense — redirect to the
    // store management page (V1: simply close; store management is out of
    // scope here).
    final settingsVm = context.read<SettingsViewModel>();
    if (settingsVm.isPremium) {
      context.pop();
      return;
    }

    final package = _selectedPackage;
    if (package == null) {
      _showMessage('Aucune offre sélectionnée pour le moment.');
      return;
    }

    setState(() => _purchaseInProgress = true);
    final service = context.read<PremiumService>();
    final outcome = await service.purchasePackage(package.identifier);
    if (!mounted) return;
    setState(() => _purchaseInProgress = false);

    switch (outcome) {
      case PremiumPurchaseOutcome.cancelled:
        // Silent: user dismissed the store sheet. No message.
        return;
      case PremiumPurchaseOutcome.failure:
        _showMessage(service.lastErrorMessage ?? 'L\'achat a échoué.');
        return;
      case PremiumPurchaseOutcome.success:
        await _refreshPremiumDependents();
        if (!mounted) return;
        _showMessage('Félicitations ! Vous êtes Premium.', success: true);
        context.pop();
    }
  }

  Future<void> _onRestorePressed() async {
    if (_purchaseInProgress) return;
    setState(() => _purchaseInProgress = true);
    final service = context.read<PremiumService>();
    final outcome = await service.restorePurchases();
    if (!mounted) return;
    setState(() => _purchaseInProgress = false);

    switch (outcome) {
      case PremiumPurchaseOutcome.cancelled:
        return;
      case PremiumPurchaseOutcome.failure:
        _showMessage(service.lastErrorMessage ?? 'La restauration a échoué.');
        return;
      case PremiumPurchaseOutcome.success:
        await _refreshPremiumDependents();
        if (!mounted) return;
        final isPremiumNow = context.read<SettingsViewModel>().isPremium;
        _showMessage(
          isPremiumNow
              ? 'Vos achats ont été restaurés. Vous êtes Premium.'
              : 'Aucun abonnement actif à restaurer.',
        );
    }
  }

  /// Reloads the 5 view models that gate on premium after a successful
  /// purchase/restore, so they pick up the new server-authoritative state
  /// without an app restart.
  Future<void> _refreshPremiumDependents() async {
    final settingsVm = context.read<SettingsViewModel>();
    final littersVm = context.read<LittersViewModel>();
    final dashboardVm = context.read<DashboardViewModel>();
    // Capture the puppy file VM (if any) before any await — Provider lookups
    // after an async gap would otherwise trip use_build_context_synchronously.
    PuppyFileViewModel? puppyFileVm;
    try {
      puppyFileVm = context.read<PuppyFileViewModel>();
    } catch (_) {
      // No puppy file VM in scope — nothing to refresh.
    }
    final puppy = puppyFileVm?.puppy;

    await Future.wait([
      settingsVm.loadSettings(),
      littersVm.loadLitters(),
      dashboardVm.loadDashboard(),
    ]);
    if (puppy?.id != null) {
      await puppyFileVm!.loadPuppyFile(puppy!.id!);
    }
  }

  void _showMessage(String message, {bool success = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.primary : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final isPremium = viewModel.isPremium;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [
                    Color(0xFF2C1914), // dark peach/orange tint
                    Color(0xFF121212), // dark background
                  ]
                : const [
                    Color(0xFFFAECE7),
                    Color(0xFFFAF6F2),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textPrimary,
                      size: 28,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.star_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Portea Premium',
                            style: AppTextStyles.screenTitle.copyWith(
                              fontSize: 28,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Votre paperasse en 3 clics',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          _buildBenefitRow(
                            context,
                            Icons.description_rounded,
                            'Documents administratifs illimités',
                          ),
                          const SizedBox(height: 16),
                          _buildBenefitRow(
                            context,
                            Icons.layers_rounded,
                            'Portées et historique illimités',
                          ),
                          const SizedBox(height: 16),
                          _buildBenefitRow(
                            context,
                            Icons.scale_rounded,
                            'Courbes de croissance exportables',
                          ),
                          const SizedBox(height: 16),
                          _buildBenefitRow(
                            context,
                            Icons.notifications_active_rounded,
                            'Rappels et alertes de santé avancées',
                          ),
                          const SizedBox(height: 40),

                          _buildPricingSection(context, isPremium),
                          const SizedBox(height: 32),

                          _buildPurchaseButton(context, isPremium),
                          const SizedBox(height: 16),

                          if (!isPremium)
                            TextButton(
                              onPressed: _purchaseInProgress
                                  ? null
                                  : _onRestorePressed,
                              child: Text(
                                'Restaurer mes achats',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingSection(BuildContext context, bool isPremium) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(
              Icons.verified_rounded,
              color: AppColors.primary,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous êtes Premium',
              style: AppTextStyles.screenTitle.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Merci pour votre soutien !',
              style: AppTextStyles.captionLabel,
            ),
          ],
        ),
      );
    }

    if (_loadingOfferings) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final offerings = _offerings;
    if (offerings == null || offerings.isEmpty) {
      // Store not configured yet (no products / sandbox not set up). Show a
      // clean message instead of crashing.
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              color: AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Les offres seront disponibles prochainement.',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Vous pourrez vous abonner dès que les boutiques seront configurées.',
              style: AppTextStyles.captionLabel,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Periodicity toggle — only shows options that actually exist.
        if (offerings.annual != null && offerings.monthly != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Annuel (2 mois offerts)'),
                  selected: _selectedPeriodicity == PremiumPeriodicity.annual,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _selectedPeriodicity == PremiumPeriodicity.annual
                        ? Colors.white
                        : null,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(
                        () => _selectedPeriodicity = PremiumPeriodicity.annual,
                      );
                    }
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Mensuel'),
                  selected: _selectedPeriodicity == PremiumPeriodicity.monthly,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _selectedPeriodicity == PremiumPeriodicity.monthly
                        ? Colors.white
                        : null,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(
                        () => _selectedPeriodicity = PremiumPeriodicity.monthly,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                _selectedPackage?.priceString ?? '',
                style: AppTextStyles.screenTitle.copyWith(
                  color: AppColors.primary,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedPeriodicity == PremiumPeriodicity.annual
                    ? 'Soit l\'équivalent de 2 mois offerts'
                    : 'Sans engagement, annulable à tout moment',
                style: AppTextStyles.captionLabel,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton(BuildContext context, bool isPremium) {
    final label = isPremium
        ? 'Gérer mon abonnement'
        : (_selectedPackage == null
              ? 'Offres indisponibles'
              : 'Passer à Premium');
    final disabled =
        _purchaseInProgress || (!isPremium && _selectedPackage == null);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(56),
      ),
      onPressed: disabled ? null : _onPurchaseOrManagePressed,
      child: _purchaseInProgress
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Text(label),
    );
  }

  Widget _buildBenefitRow(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primaryDark.withValues(alpha: 0.3)
                : AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
