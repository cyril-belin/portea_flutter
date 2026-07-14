import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../view_models/dashboard_view_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();

    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final kennel = viewModel.kennel;
    final activeLitter = viewModel.activeLitter;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kennel?.name ?? 'Mon Élevage',
                            style: AppTextStyles.screenTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (kennel?.affix != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Affixe: ${kennel!.affix}',
                              style: AppTextStyles.captionLabel,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!viewModel.isPremium)
                      IconButton(
                        icon: const Icon(
                          Icons.lock_rounded,
                          color: AppColors.premium,
                        ),
                        onPressed: () => context.push('/premium'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Active litter section
                if (activeLitter == null)
                  EmptyStateWidget(
                    icon: Icons.layers_outlined,
                    title: 'Aucune portée active',
                    subtitle:
                        'Déclarez votre portée ou configurez vos reproducteurs.',
                    primaryActionLabel: 'Déclarer ma première portée',
                    onPrimaryAction: () => context.push('/litters/new'),
                    secondaryActionLabel: 'Ajouter mes reproducteurs d\'abord',
                    onSecondaryAction: () => context.go('/breeders'),
                  )
                else ...[
                  Text(
                    'Portée en cours',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 8),
                  _buildActiveLitterCard(context, viewModel),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Accès rapides',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 8),
                  _buildQuickActionsRow(context, activeLitter.id!),
                  const SizedBox(height: 24),
                ],

                // Upcoming reminders
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prochains rappels',
                      style: AppTextStyles.sectionTitle,
                    ),
                    if (viewModel.upcomingReminders.isNotEmpty)
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (viewModel.upcomingReminders.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.statusAvailable,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tout est à jour ! Aucun rappel à venir.',
                              style: AppTextStyles.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...viewModel.upcomingReminders.map(
                    (reminder) => _buildReminderTile(context, reminder),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveLitterCard(BuildContext context, DashboardViewModel vm) {
    final litter = vm.activeLitter!;
    final puppies = vm.activeLitterPuppies;
    final ageDays = DateTime.now().difference(litter.birthDate).inDays;
    final ageWeeks = ageDays ~/ 7;
    final ageLabel = ageDays < 7
        ? 'J+$ageDays'
        : 'Semaine $ageWeeks ($ageDays jours)';

    final availableCount = puppies.where((p) => p.status == 'available').length;
    final reservedCount = puppies.where((p) => p.status == 'reserved').length;

    return Card(
      child: InkWell(
        onTap: () => context.push('/litters/${litter.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Portée de ${vm.motherName ?? "Mère"}',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      ageLabel,
                      style: AppTextStyles.captionLabel.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Chiots', '${puppies.length}'),
                  _buildStatItem(
                    'Disponibles',
                    '$availableCount',
                    color: AppColors.statusAvailable,
                  ),
                  _buildStatItem(
                    'Réservés',
                    '$reservedCount',
                    color: AppColors.statusReserved,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.screenTitle.copyWith(
            color: color ?? AppColors.textPrimary,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.captionLabel,
        ),
      ],
    );
  }

  Widget _buildQuickActionsRow(BuildContext context, int litterId) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              elevation: 0,
            ),
            onPressed: () => context.push('/litters/$litterId/weighing'),
            icon: const Icon(Icons.scale_rounded),
            label: const Text('Pesée'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              elevation: 0,
            ),
            onPressed: () => context.push('/litters/$litterId/care'),
            icon: const Icon(Icons.vaccines_rounded),
            label: const Text('Nouveau soin'),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderTile(BuildContext context, CareEntry reminder) {
    final diff = reminder.reminderAt!.difference(DateTime.now()).inDays;
    final diffLabel = diff == 0
        ? "Aujourd'hui"
        : diff == 1
        ? "Demain"
        : "Dans $diff jours";

    IconData icon;
    Color color;
    switch (reminder.type) {
      case 'vaccine':
        icon = Icons.vaccines_rounded;
        color = AppColors.statusSold;
        break;
      case 'deworming':
        icon = Icons.bug_report_rounded;
        color = AppColors.statusReserved;
        break;
      default:
        icon = Icons.medication_rounded;
        color = AppColors.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () {
          if (reminder.puppyId != null) {
            context.push('/puppies/${reminder.puppyId}');
          } else if (reminder.litterId != null) {
            context.push('/litters/${reminder.litterId}');
          }
        },
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          reminder.product ?? 'Soin sans produit',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          reminder.type == 'deworming' ? 'Vermifuge groupe' : 'Vaccination',
          style: AppTextStyles.captionLabel,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            diffLabel,
            style: AppTextStyles.captionLabel.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
