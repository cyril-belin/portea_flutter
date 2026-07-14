import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/settings_view_model.dart';
import '../../../dashboard/presentation/view_models/dashboard_view_model.dart';
import '../../../litters/presentation/view_models/litters_view_model.dart';
import '../../../puppies/presentation/view_models/puppy_file_view_model.dart';

class PorteaPremiumScreen extends StatefulWidget {
  const PorteaPremiumScreen({super.key});

  @override
  State<PorteaPremiumScreen> createState() => _PorteaPremiumScreenState();
}

class _PorteaPremiumScreenState extends State<PorteaPremiumScreen> {
  bool _isAnnual = true;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAECE7),
              Color(0xFFFAF6F2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Close button
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Header Logo / Icon
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
                        style: AppTextStyles.screenTitle.copyWith(fontSize: 28),
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

                      // Benefits
                      _buildBenefitRow(
                        Icons.description_rounded,
                        'Documents administratifs illimités',
                      ),
                      const SizedBox(height: 16),
                      _buildBenefitRow(
                        Icons.layers_rounded,
                        'Portées et historique illimités',
                      ),
                      const SizedBox(height: 16),
                      _buildBenefitRow(
                        Icons.scale_rounded,
                        'Courbes de croissance exportables',
                      ),
                      const SizedBox(height: 16),
                      _buildBenefitRow(
                        Icons.notifications_active_rounded,
                        'Rappels et alertes de santé avancées',
                      ),

                      const SizedBox(height: 40),

                      // Toggle Annual / Monthly
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Annuel (2 mois offerts)'),
                            selected: _isAnnual,
                            onSelected: (selected) {
                              if (selected) setState(() => _isAnnual = true);
                            },
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Mensuel'),
                            selected: !_isAnnual,
                            onSelected: (selected) {
                              if (selected) setState(() => _isAnnual = false);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Price Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isAnnual ? '89,99 € / an' : '9,99 € / mois',
                              style: AppTextStyles.screenTitle.copyWith(
                                color: AppColors.primary,
                                fontSize: 26,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isAnnual
                                  ? 'Soit 7,49 € par mois'
                                  : 'Sans engagement, annulable à tout moment',
                              style: AppTextStyles.captionLabel,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Purchase Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: () async {
                          final newStatus = !viewModel.isPremium;
                          final littersVm = context.read<LittersViewModel>();
                          final dashboardVm =
                              context.read<DashboardViewModel>();
                          PuppyFileViewModel? puppyFileVm;
                          try {
                            puppyFileVm = context.read<PuppyFileViewModel>();
                          } catch (_) {}
                          final messenger = ScaffoldMessenger.of(context);
                          final goRouter = GoRouter.of(context);
                          await viewModel.togglePremium(newStatus);

                          // Refresh dependent states
                          if (mounted) {
                            littersVm.loadLitters();
                            dashboardVm.loadDashboard();
                            // If there is any active puppy file viewModel loaded, refresh it too
                            try {
                              puppyFileVm?.loadPuppyFile(
                                puppyFileVm.puppy!.id!,
                              );
                            } catch (_) {}

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  newStatus
                                      ? 'Félicitations ! Vous êtes Premium.'
                                      : 'Retour à la version gratuite.',
                                ),
                              ),
                            );
                            goRouter.pop();
                          }
                        },
                        child: Text(
                          viewModel.isPremium
                              ? 'Résilier l\'abonnement (Test)'
                              : 'Passer à Premium (Test)',
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Restaurer mes achats',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
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
