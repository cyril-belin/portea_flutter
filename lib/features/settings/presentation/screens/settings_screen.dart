import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/operation_state.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/settings_view_model.dart';
import '../../../dashboard/presentation/view_models/dashboard_view_model.dart';
import '../../domain/services/account_data_exporter.dart';

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

        // Section 3: RGPD — data portability (article 20) + erasure (article 17).
        // Both actions are LEGAL and IRREVERSIBLE — no fake success message is
        // shown until the server has confirmed the operation (verdict §2.2).
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
                subtitle: const Text(
                  'Téléchargez un fichier JSON de toutes vos données.',
                ),
                onTap: viewModel.isBusy
                    ? null
                    : () => _exportMyData(context, viewModel),
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
                subtitle: const Text(
                  'Action irréversible. Toutes vos données seront définitivement effacées.',
                ),
                onTap: viewModel.isBusy
                    ? null
                    : () => _confirmDeleteAccount(context, viewModel),
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

  /// RGPD export flow (article 20 — data portability).
  ///
  /// Calls the server, then hands the JSON payload to the OS share sheet.
  /// Success is surfaced ONLY AFTER the share sheet has been invoked — no
  /// fake "Données exportées" message before the server has actually
  /// returned the data (verdict §2.2).
  Future<void> _exportMyData(
    BuildContext context,
    SettingsViewModel viewModel,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final export = await viewModel.exportMyData();
    if (!mounted) return;

    if (export == null) {
      // Failure: the VM has populated errorMessage. No success UI.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ?? 'Une erreur est survenue.',
          ),
        ),
      );
      return;
    }

    // Hand the JSON to the OS share sheet. The success message is shown
    // only after this call returns — we know the file was built and the
    // sheet was invoked. (We cannot guarantee the user completed the share,
    // but that is the OS's responsibility, not ours.)
    try {
      await AccountDataExporter().exportAndShare(export);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Données exportées.')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "L'export a été préparé mais le partage a échoué. Réessayez.",
          ),
        ),
      );
    }
  }

  /// RGPD account deletion flow (article 17 — right to erasure).
  ///
  /// Two-step confirmation: dialog 1 explains what will be destroyed and
  /// that the action is irreversible; dialog 2 requires the user to type
  /// "SUPPRIMER" verbatim — intentional friction on a legal, irreversible
  /// action. Only on that explicit confirmation does the server call run.
  ///
  /// The server call is the only source of truth. No "Compte supprimé"
  /// message is shown before it succeeds — on failure the user stays
  /// signed in and the VM's errorMessage is surfaced.
  Future<void> _confirmDeleteAccount(
    BuildContext context,
    SettingsViewModel viewModel,
  ) async {
    // Capture context-dependent singletons BEFORE the first await. After
    // the awaits below, `context` may be unmounted even though `mounted`
    // was checked — the lint is right to flag this, and the captures
    // (ScaffoldMessenger/GoRouter) stay valid across the async gap because
    // they are framework singletons looked up from the still-mounted tree.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer votre compte ?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est irréversible. Les éléments suivants seront '
              'définitivement effacés :',
            ),
            SizedBox(height: 12),
            Text(
              '• Votre élevage et ses informations\n'
              '• Tous les reproducteurs\n'
              '• Toutes les portées et chiots\n'
              '• L\'historique des pesées et soins\n'
              '• Les attestations de cession émises',
            ),
            SizedBox(height: 12),
            Text(
              'Votre abonnement Premium, s\'il est actif, doit être résilié '
              'séparément depuis les réglages de l\'App Store ou du Google '
              'Play — nous ne pouvons pas le faire pour vous.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Step 2 — type-to-confirm. The friction is intentional: this is a
    // legal, irreversible action and a misclick must not destroy data.
    // The `context` here is the StatefulWidget's context, re-checked by
    // the `mounted` guard above. The lint can't track that guarantee
    // statically, so we silence it on this single call site.
    final typed = await showDialog<String>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Confirmation finale'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pour confirmer, saisissez exactement le mot '
                '« SUPPRIMER » ci-dessous :',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'SUPPRIMER',
                ),
                onSubmitted: (value) => Navigator.pop(dialogContext, value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );

    if (typed != 'SUPPRIMER') return;
    if (!mounted) return;

    // The server call — the only source of truth. No UI optimism here.
    // `messenger` and `router` were captured before the awaits above.
    final ok = await viewModel.deleteAccount();
    if (!mounted) return;

    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ??
                'La suppression a échoué. Vos données sont intactes — réessayez.',
          ),
        ),
      );
      return;
    }

    // Success — the server confirmed. CancelAll + clearLocalState +
    // signOutDevice have run inside the VM. Navigate to the welcome screen
    // with a clean route stack (no /settings, /dashboard, etc. lingering
    // above a deleted session).
    router.go('/onboarding/welcome');
  }
}
