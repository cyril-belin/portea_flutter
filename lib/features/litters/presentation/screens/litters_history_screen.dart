import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../view_models/litters_view_model.dart';

class LittersHistoryScreen extends StatefulWidget {
  const LittersHistoryScreen({super.key});

  @override
  State<LittersHistoryScreen> createState() => _LittersHistoryScreenState();
}

class _LittersHistoryScreenState extends State<LittersHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LittersViewModel>().loadLitters();
    });
  }

  void _onDeclarePress(BuildContext context, LittersViewModel vm) {
    if (!vm.isPremium && vm.activeLitter != null) {
      context.push('/premium');
    } else {
      context.push('/litters/new');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LittersViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portées'),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: viewModel.loadLitters,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Active litter card (if any)
                        if (viewModel.activeLitter != null) ...[
                          Text(
                            'Portée active',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 8),
                          _buildActiveLitterCard(
                            context,
                            viewModel.activeLitter!,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // History list
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Historique',
                              style: AppTextStyles.sectionTitle,
                            ),
                            if (!viewModel.isPremium)
                              const Row(
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    color: AppColors.premium,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      color: AppColors.premium,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (viewModel.pastLitters.isEmpty &&
                            viewModel.activeLitter == null)
                          EmptyStateWidget(
                            icon: Icons.folder_open_rounded,
                            title: 'Aucune portée enregistrée',
                            subtitle:
                                'Commencez par déclarer une portée de chiots.',
                            primaryActionLabel: 'Déclarer une portée',
                            onPrimaryAction: () =>
                                _onDeclarePress(context, viewModel),
                          )
                        else if (viewModel.pastLitters.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'Pas d\'anciennes portées dans l\'historique.',
                                style: AppTextStyles.captionLabel,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 650) {
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 450,
                                        mainAxisExtent: 88,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 8,
                                      ),
                                  itemCount: viewModel.pastLitters.length,
                                  itemBuilder: (context, index) {
                                    final litter = viewModel.pastLitters[index];
                                    return _buildHistoryLitterCard(
                                      context,
                                      litter,
                                      viewModel.isPremium,
                                    );
                                  },
                                );
                              } else {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: viewModel.pastLitters
                                      .map(
                                        (litter) => _buildHistoryLitterCard(
                                          context,
                                          litter,
                                          viewModel.isPremium,
                                        ),
                                      )
                                      .toList(),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _onDeclarePress(context, viewModel),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildActiveLitterCard(BuildContext context, Litter litter) {
    final diff = DateTime.now().difference(litter.birthDate).inDays;
    final ageLabel = diff < 7 ? 'J+$diff' : 'Semaine ${diff ~/ 7}';

    return Card(
      child: ListTile(
        onTap: () => context.push('/litters/${litter.id}'),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.primaryDark.withValues(alpha: 0.25)
              : AppColors.primaryLight,
          child: const Icon(
            Icons.child_friendly_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          'Portée de Salsa', // Mother name
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Née le ${litter.birthDate.day}/${litter.birthDate.month}/${litter.birthDate.year} • $ageLabel',
          style: AppTextStyles.captionLabel,
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkTextSecondary
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildHistoryLitterCard(
    BuildContext context,
    Litter litter,
    bool isPremium,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: isPremium ? 1.0 : 0.6,
        child: ListTile(
          onTap: () {
            if (isPremium) {
              context.push('/litters/${litter.id}');
            } else {
              context.push('/premium');
            }
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: CircleAvatar(
            backgroundColor: isPremium
                ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.primaryDark.withValues(alpha: 0.25)
                      : AppColors.primaryLight)
                : Theme.of(context).colorScheme.outlineVariant,
            child: Icon(
              isPremium ? Icons.folder_zip_rounded : Icons.lock_rounded,
              color: isPremium
                  ? AppColors.primary
                  : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary),
            ),
          ),
          title: Text(
            'Portée Historique (${litter.birthDate.year})',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Mise bas : ${litter.birthDate.day}/${litter.birthDate.month}/${litter.birthDate.year}',
            style: AppTextStyles.captionLabel,
          ),
          trailing: isPremium
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                )
              : const Icon(
                  Icons.lock_rounded,
                  color: AppColors.premium,
                  size: 18,
                ),
        ),
      ),
    );
  }
}
