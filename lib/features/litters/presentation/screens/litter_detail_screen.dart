import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge_widget.dart';
import '../view_models/litter_detail_view_model.dart';
import '../../../../core/widgets/empty_state_widget.dart';

class LitterDetailScreen extends StatefulWidget {
  final int id;

  const LitterDetailScreen({super.key, required this.id});

  @override
  State<LitterDetailScreen> createState() => _LitterDetailScreenState();
}

class _LitterDetailScreenState extends State<LitterDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LitterDetailViewModel>().loadLitterDetail(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LitterDetailViewModel>();

    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final litter = viewModel.litter;
    if (litter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Portée introuvable')),
        body: const Center(child: Text('Cette portée n\'existe pas.')),
      );
    }

    final mother = viewModel.mother;
    final father = viewModel.father;
    final puppies = viewModel.puppies;

    final diff = DateTime.now().difference(litter.birthDate).inDays;
    final ageWeeks = diff ~/ 7;
    final ageLabel = diff < 7 ? 'J+$diff' : 'Semaine $ageWeeks ($diff jours)';

    final availableCount = puppies.where((p) => p.status == 'available').length;
    final reservedCount = puppies.where((p) => p.status == 'reserved').length;
    final soldCount = puppies.where((p) => p.status == 'sold').length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Portée de ${mother?.name ?? "Mère"}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parents',
                              style: AppTextStyles.captionLabel.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${mother?.name ?? "Mère"} ♀ • ${father?.name ?? litter.externalSireName ?? "Père"} ♂',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                    Text(
                      'Date de naissance : ${litter.birthDate.day}/${litter.birthDate.month}/${litter.birthDate.year}',
                      style: AppTextStyles.captionLabel,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Group Actions
            Row(
              children: [
                Expanded(
                  child: _buildGroupActionBtn(
                    context: context,
                    icon: Icons.scale_rounded,
                    label: 'Pesée',
                    onTap: () => context.push('/litters/${litter.id}/weighing'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGroupActionBtn(
                    context: context,
                    icon: Icons.vaccines_rounded,
                    label: 'Soin',
                    onTap: () => context.push('/litters/${litter.id}/care'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGroupActionBtn(
                    context: context,
                    icon: Icons.description_rounded,
                    label: 'Docs',
                    onTap: () =>
                        context.push('/litters/${litter.id}/documents'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chiots (${puppies.length})',
                  style: AppTextStyles.sectionTitle,
                ),
                Row(
                  children: [
                    _buildMiniBadge(
                      '$availableCount dispo',
                      AppColors.statusAvailable,
                    ),
                    const SizedBox(width: 6),
                    _buildMiniBadge(
                      '$reservedCount rés.',
                      AppColors.statusReserved,
                    ),
                    const SizedBox(width: 6),
                    _buildMiniBadge('$soldCount vendus', AppColors.statusSold),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (puppies.isEmpty)
              EmptyStateWidget(
                icon: Icons.pets_outlined,
                title: 'Aucun chiot déclaré',
                subtitle:
                    'Ajoutez des chiots à cette portée pour commencer le suivi.',
                primaryActionLabel: 'Déclarer les chiots',
                onPrimaryAction: () =>
                    context.push('/litters/${litter.id}/puppies/batch'),
              )
            else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: puppies.length,
                itemBuilder: (context, index) {
                  final puppy = puppies[index];
                  final isFemale =
                      puppy.sex.toLowerCase() == 'female' || puppy.sex == '♀';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => context.push('/puppies/${puppy.id}'),
                      leading: CircleAvatar(
                        backgroundColor: isFemale
                            ? AppColors.female.withValues(alpha: 0.15)
                            : AppColors.male.withValues(alpha: 0.15),
                        child: Text(
                          puppy.sex.toLowerCase() == 'female' ? '♀' : '♂',
                          style: TextStyle(
                            color: isFemale ? AppColors.female : AppColors.male,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        puppy.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        puppy.color ?? 'Couleur non précisée',
                        style: AppTextStyles.captionLabel,
                      ),
                      trailing: StatusBadgeWidget(status: puppy.status),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () =>
                    context.push('/litters/${litter.id}/puppies/batch'),
                icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                label: const Text(
                  'Ajouter / Editer les chiots',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupActionBtn({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border, width: 0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: Size.zero,
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.captionLabel.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
