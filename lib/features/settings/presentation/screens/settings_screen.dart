import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/operation_state.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/settings_view_model.dart';
import '../../../dashboard/presentation/view_models/dashboard_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _breederFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _affixController = TextEditingController();
  final _siretController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerAddressController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<SettingsViewModel>();
      await vm.loadSettings();
      if (vm.kennel != null) {
        _nameController.text = vm.kennel!.name;
        _affixController.text = vm.kennel!.affix ?? '';
        _siretController.text = vm.kennel!.siret ?? '';
        _ownerNameController.text = vm.kennel!.ownerName ?? '';
        _ownerAddressController.text = vm.kennel!.ownerAddress ?? '';
        _ownerPhoneController.text = vm.kennel!.ownerPhone ?? '';
        _ownerEmailController.text = vm.kennel!.ownerEmail ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _affixController.dispose();
    _siretController.dispose();
    _ownerNameController.dispose();
    _ownerAddressController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    if (viewModel.state == OperationState.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final k = viewModel.kennel;

    final kennelInfoSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mon Élevage', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nom de l'élevage",
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _affixController,
                  decoration: const InputDecoration(labelText: 'Affixe'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && k != null) {
                      k.name = _nameController.text.trim();
                      k.affix = _affixController.text.trim().isEmpty
                          ? null
                          : _affixController.text.trim();
                      final dashboardVm = context.read<DashboardViewModel>();
                      final messenger = ScaffoldMessenger.of(context);
                      await viewModel.updateKennel(k);

                      // Refresh other affected ViewModels
                      if (mounted) {
                        dashboardVm.loadDashboard();
                        if (viewModel.errorMessage != null) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(viewModel.errorMessage!)),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Réglages enregistrés'),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Enregistrer l\'élevage'),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    // Breeder (owner) info — the dedicated write surface (F09 prerequisite).
    // All five fields are optional here; completeness is enforced at attestation
    // generation (F09), not at data entry. email + SIRET validators mirror the
    // server rules (comfort UX; the server remains the authority).
    final breederInfoSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Informations éleveur', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 4),
        Text(
          'Ces informations apparaîtront sur l\'attestation de cession.',
          style: AppTextStyles.captionLabel,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'exploitant',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ownerAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse de l\'élevage',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ownerPhoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ownerEmailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null; // optional
                    if (!RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$',
                    ).hasMatch(text)) {
                      return 'Adresse e-mail invalide.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _siretController,
                  decoration: const InputDecoration(
                    labelText: 'N° SIRET (14 chiffres)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null; // optional
                    if (!RegExp(r'^[0-9]{14}$').hasMatch(text)) {
                      return 'Le SIRET doit comporter exactement 14 chiffres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: viewModel.isBusy
                      ? null
                      : () async {
                          if (!(_breederFormKey.currentState?.validate() ??
                              false)) {
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await viewModel.updateKennelOwnerInfo(
                            ownerName: _ownerNameController.text.trim(),
                            ownerAddress: _ownerAddressController.text.trim(),
                            ownerPhone: _ownerPhoneController.text.trim(),
                            ownerEmail: _ownerEmailController.text.trim(),
                            siret: _siretController.text.trim(),
                          );
                          if (!mounted) return;
                          if (!ok || viewModel.errorMessage != null) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  viewModel.errorMessage ??
                                      'Une erreur est survenue.',
                                ),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Informations éleveur enregistrées',
                                ),
                              ),
                            );
                          }
                        },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final otherSections = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Apparence Section
        Text('Apparence', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<ThemeMode>(
                  segments: const <ButtonSegment<ThemeMode>>[
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('Système'),
                      icon: Icon(Icons.settings_brightness_rounded),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('Clair'),
                      icon: Icon(Icons.light_mode_rounded),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('Sombre'),
                      icon: Icon(Icons.dark_mode_rounded),
                    ),
                  ],
                  selected: <ThemeMode>{viewModel.themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    viewModel.updateThemeMode(newSelection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Section 2: Subscription Info
        Text('Abonnement', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(
              viewModel.isPremium ? Icons.star_rounded : Icons.lock_rounded,
              color: AppColors.premium,
              size: 32,
            ),
            title: Text(
              viewModel.isPremium ? 'Portea Premium Actif' : 'Version Gratuite',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              viewModel.isPremium
                  ? 'Accès illimité à toutes les fonctions.'
                  : 'Une portée active max. Documents floutés.',
              style: AppTextStyles.captionLabel,
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onPressed: () => context.push('/premium'),
              child: Text(viewModel.isPremium ? 'Gérer' : 'Upgrade'),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Section 3: Actions
        Text('Données & RGPD', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.download_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: const Text('Exporter mes données'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Données exportées au format JSON'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Supprimer mon compte',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Supprimer le compte ?'),
                      content: const Text(
                        'Cette action est irréversible. Toutes vos portées et reproducteurs seront effacés définitivement.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Compte supprimé'),
                              ),
                            );
                          },
                          child: const Text(
                            'Supprimer',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Each form lives in its own Form widget (Flutter does not allow
                // nested Forms), so the kennel section validates independently
                // from the breeder section.
                final leftColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Form(key: _formKey, child: kennelInfoSection),
                    const SizedBox(height: 24),
                    Form(key: _breederFormKey, child: breederInfoSection),
                  ],
                );
                if (constraints.maxWidth > 800) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: leftColumn),
                      const SizedBox(width: 24),
                      Expanded(flex: 5, child: otherSections),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      leftColumn,
                      const SizedBox(height: 24),
                      otherSections,
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
