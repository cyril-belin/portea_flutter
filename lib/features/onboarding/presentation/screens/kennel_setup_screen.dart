import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/onboarding_view_model.dart';

class KennelSetupScreen extends StatefulWidget {
  const KennelSetupScreen({super.key});

  @override
  State<KennelSetupScreen> createState() => _KennelSetupScreenState();
}

class _KennelSetupScreenState extends State<KennelSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Création élevage'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Parlez-nous de votre élevage',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ces informations permettront de pré-remplir vos documents légaux.',
                  style: AppTextStyles.captionLabel,
                ),
                const SizedBox(height: 24),
                // Nom Elevage
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Nom de l'élevage",
                    hintText: "Ex: Élevage du Val de la Sèvre",
                  ),
                  initialValue: viewModel.kennelName,
                  onChanged: (val) => viewModel.kennelName = val,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Veuillez entrer le nom de l'élevage";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Espèce toggle
                Text(
                  'Espèce principale élevée',
                  style: AppTextStyles.captionLabel.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => viewModel.species = 'dog',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: viewModel.species == 'dog'
                                ? AppColors.primaryLight
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: viewModel.species == 'dog'
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: viewModel.species == 'dog' ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.pets_rounded,
                                color: viewModel.species == 'dog'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Chien',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: viewModel.species == 'dog'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: viewModel.species == 'dog'
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => viewModel.species = 'cat',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: viewModel.species == 'cat'
                                ? AppColors.primaryLight
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: viewModel.species == 'cat'
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: viewModel.species == 'cat' ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons
                                    .pets_sharp, // different pet icon or anything for cats
                                color: viewModel.species == 'cat'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Chat',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: viewModel.species == 'cat'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: viewModel.species == 'cat'
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Affixe
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Affixe (optionnel)',
                    hintText: 'Ex: de la Plaine Fleurie',
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Qu\'est-ce que l\'affixe ?'),
                            content: const Text(
                              'L\'affixe est le "nom de famille" attribué aux chiots/chatons nés dans votre élevage. Il est enregistré auprès de la SCC ou du LOOF.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  initialValue: viewModel.affix,
                  onChanged: (val) => viewModel.affix = val,
                ),
                const SizedBox(height: 40),
                if (viewModel.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final goRouter = GoRouter.of(context);
                        final success = await viewModel.createKennel();
                        if (success && mounted) {
                          goRouter.go('/onboarding/notifications');
                        }
                      }
                    },
                    child: const Text('Créer mon élevage'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
