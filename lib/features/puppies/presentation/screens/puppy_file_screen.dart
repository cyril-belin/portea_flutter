import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/operation_state.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge_widget.dart';
import '../view_models/puppy_file_view_model.dart';
import '../widgets/growth_curve_widget.dart';

class PuppyFileScreen extends StatefulWidget {
  final int id;

  const PuppyFileScreen({super.key, required this.id});

  @override
  State<PuppyFileScreen> createState() => _PuppyFileScreenState();
}

class _PuppyFileScreenState extends State<PuppyFileScreen> {
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _buyerEmailController = TextEditingController();
  final _buyerAddressController = TextEditingController();
  final _weightController = TextEditingController();
  final _chipController = TextEditingController();
  final _buyerFormKey = GlobalKey<FormState>();
  final _chipFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<PuppyFileViewModel>();
      await vm.loadPuppyFile(widget.id);
      if (vm.puppy != null) {
        _syncBuyerControllers(vm.puppy!);
        _chipController.text = vm.puppy!.chipNumber ?? '';
      }
    });
  }

  /// Re-seeds the buyer form fields from the puppy row. Called after the
  /// initial load AND whenever the section reappears (status back to
  /// reserved/sold after an `available` interlude) — otherwise the fields
  /// would stay stale/empty while the database still holds the buyer dossier
  /// (the conservation rule keeps it; the UI must reflect it).
  void _syncBuyerControllers(Puppy puppy) {
    _buyerNameController.text = puppy.buyerName ?? '';
    _buyerPhoneController.text = puppy.buyerPhone ?? '';
    _buyerEmailController.text = puppy.buyerEmail ?? '';
    _buyerAddressController.text = puppy.buyerAddress ?? '';
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _buyerEmailController.dispose();
    _buyerAddressController.dispose();
    _weightController.dispose();
    _chipController.dispose();
    super.dispose();
  }

  void _showAddWeightDialog(PuppyFileViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ajouter une pesée', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Poids (g)',
                hintText: 'Ex: 1850',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final w = double.tryParse(_weightController.text);
                if (w != null && w > 0) {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  await vm.addSingleWeight(w);
                  if (!mounted) return;
                  if (vm.errorMessage != null) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(vm.errorMessage!)),
                    );
                  } else {
                    _weightController.clear();
                    nav.pop();
                  }
                }
              },
              child: const Text('Enregistrer la pesée'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PuppyFileViewModel>();

    if (viewModel.state == OperationState.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (viewModel.state == OperationState.error && viewModel.puppy == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chiot')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48),
                const SizedBox(height: 12),
                Text(viewModel.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => viewModel.loadPuppyFile(widget.id),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final puppy = viewModel.puppy;
    if (puppy == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chiot introuvable')),
        body: const Center(child: Text('Ce chiot n\'existe pas.')),
      );
    }

    final isFemale = puppy.sex.toLowerCase() == 'female' || puppy.sex == '♀';

    final headerWidget = _buildHeader(puppy, isFemale);
    final chipWidget = _buildChipSection(viewModel);
    final weightCurveWidget = _buildWeightCurveSection(viewModel.weighings);
    final weightHistoryWidget = _buildWeightHistorySection(viewModel);
    final healthWidget = _buildHealthSection(viewModel);
    final buyerWidget = _buildBuyerSection(puppy, viewModel);
    final documentsWidget = _buildDocumentsSection(viewModel);

    return Scaffold(
      appBar: AppBar(
        title: Text(puppy.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Partage de la courbe de poids (Premium)'),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 850) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            headerWidget,
                            const SizedBox(height: 24),
                            chipWidget,
                            const SizedBox(height: 24),
                            weightCurveWidget,
                            const SizedBox(height: 24),
                            weightHistoryWidget,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            healthWidget,
                            const SizedBox(height: 24),
                            buyerWidget,
                            const SizedBox(height: 24),
                            documentsWidget,
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      headerWidget,
                      const SizedBox(height: 24),
                      chipWidget,
                      const SizedBox(height: 24),
                      weightCurveWidget,
                      const SizedBox(height: 24),
                      weightHistoryWidget,
                      const SizedBox(height: 24),
                      healthWidget,
                      const SizedBox(height: 24),
                      buyerWidget,
                      const SizedBox(height: 24),
                      documentsWidget,
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

  Widget _buildHeader(dynamic puppy, bool isFemale) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: isFemale
              ? AppColors.female.withValues(alpha: 0.15)
              : AppColors.male.withValues(alpha: 0.15),
          child: Text(
            isFemale ? '♀' : '♂',
            style: TextStyle(
              color: isFemale ? AppColors.female : AppColors.male,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                puppy.name,
                style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                'Couleur : ${puppy.color ?? "Non renseignée"}',
                style: AppTextStyles.captionLabel,
              ),
              const SizedBox(height: 4),
              StatusBadgeWidget(status: puppy.status),
            ],
          ),
        ),
      ],
    );
  }

  /// Identification section: the puppy's chip number (I-CAD), implanted weeks
  /// after birth. Editable here because the chip is set long after the litter
  /// batch was created. Saved through the litter's identity write surface
  /// (savePuppiesBatch), NOT through updatePuppyStatus — the chip is an identity
  /// field, and `updatePuppyStatus` owns status + buyer* + cessionDate only
  /// (the F08 split).
  Widget _buildChipSection(PuppyFileViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _chipFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Identification', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              TextFormField(
                controller: _chipController,
                decoration: const InputDecoration(
                  labelText: 'N° de puce (I-CAD)',
                  hintText: '15 chiffres',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: vm.isBusy
                    ? null
                    : () async {
                        if (!(_chipFormKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        await vm.saveChipNumber(_chipController.text);
                        if (!mounted) return;
                        if (vm.errorMessage != null) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(vm.errorMessage!)),
                          );
                        } else {
                          // Reflect the normalized value (empty → null) back.
                          _chipController.text = vm.puppy?.chipNumber ?? '';
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Numéro de puce enregistré'),
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
    );
  }

  Widget _buildWeightCurveSection(List<WeighingEntry> weighings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Courbe de poids',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                ),
                const Icon(Icons.show_chart_rounded, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 16),
            GrowthCurveWidget(weighings: weighings),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightHistorySection(PuppyFileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pesées (${vm.weighings.length})',
              style: AppTextStyles.sectionTitle,
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primary,
              ),
              onPressed: () => _showAddWeightDialog(vm),
            ),
          ],
        ),
        if (vm.weighings.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Aucune pesée enregistrée',
                style: AppTextStyles.captionLabel,
              ),
            ),
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.weighings.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final w = vm.weighings[index];
                return ListTile(
                  title: Text('${w.weightGrams.toStringAsFixed(0)} g'),
                  subtitle: Text(
                    '${w.weighedAt.day}/${w.weighedAt.month}/${w.weighedAt.year}',
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHealthSection(PuppyFileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Timeline Santé', style: AppTextStyles.sectionTitle),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primary,
              ),
              onPressed: () => context.push(
                '/litters/${vm.puppy!.litterId}/care?puppyId=${vm.puppy!.id}',
              ),
            ),
          ],
        ),
        if (vm.careTimeline.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Aucun soin enregistré',
                style: AppTextStyles.captionLabel,
              ),
            ),
          )
        else
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.careTimeline.length,
              itemBuilder: (context, index) {
                final care = vm.careTimeline[index];
                return ListTile(
                  leading: const Icon(
                    Icons.vaccines_rounded,
                    color: AppColors.statusSold,
                  ),
                  title: Text(care.product ?? 'Soin sans produit'),
                  subtitle: Text(
                    '${care.appliedAt.day}/${care.appliedAt.month}/${care.appliedAt.year}',
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBuyerSection(Puppy puppy, PuppyFileViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Statut & Acquéreur', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Disponible')),
                selected: puppy.status == 'available',
                onSelected: (selected) async {
                  if (!selected) return;
                  final messenger = ScaffoldMessenger.of(context);
                  await vm.updateStatus('available');
                  if (!mounted) return;
                  // On available, the buyer section disappears — but the data
                  // is conserved in the DB. Surface a success/error.
                  if (vm.errorMessage != null) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(vm.errorMessage!)),
                    );
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Statut mis à jour : disponible. '
                          'Les infos acquéreur sont conservées.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Réservé')),
                selected: puppy.status == 'reserved',
                onSelected: (selected) async {
                  if (!selected) return;
                  final messenger = ScaffoldMessenger.of(context);
                  await vm.updateStatus('reserved');
                  if (!mounted) return;
                  if (vm.errorMessage != null) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(vm.errorMessage!)),
                    );
                  } else {
                    _syncBuyerControllers(vm.puppy!);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Statut mis à jour : réservé.'),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Vendu')),
                selected: puppy.status == 'sold',
                onSelected: (selected) async {
                  if (!selected) return;
                  // sold requires a buyerName (F08 rule). The server is the
                  // final authority, but we avoid a pointless round-trip and a
                  // visual flip-then-revert: if neither a typed nor a stored
                  // name exists, prompt the user to fill the dossier first.
                  final hasName =
                      _buyerNameController.text.trim().isNotEmpty ||
                      (puppy.buyerName ?? '').isNotEmpty;
                  if (!hasName) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Renseignez le nom de l\'acquéreur avant de '
                          'marquer le chiot comme vendu.',
                        ),
                      ),
                    );
                    return;
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  await vm.updateStatus('sold');
                  if (!mounted) return;
                  if (vm.errorMessage != null) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(vm.errorMessage!)),
                    );
                  } else {
                    _syncBuyerControllers(vm.puppy!);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Statut mis à jour : vendu.'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        if (puppy.status == 'reserved' || puppy.status == 'sold') ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _buyerFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Informations de l\'acquéreur',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _buyerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom & Prénom',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _buyerPhoneController,
                      decoration: const InputDecoration(labelText: 'Téléphone'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return null; // optional
                        // Strip separators and the FR country code.
                        final digits = text.replaceAll(
                          RegExp(r'[\s.\-()]'),
                          '',
                        );
                        final bare = digits.replaceFirst(
                          RegExp(r'^(?:\+33|0033|0)'),
                          '',
                        );
                        if (!RegExp(r'^[0-9]{9}$').hasMatch(bare)) {
                          return 'Numéro de téléphone invalide.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _buyerEmailController,
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
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _buyerAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse postale',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (!(_buyerFormKey.currentState?.validate() ??
                            false)) {
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        await vm.saveBuyerInfo(
                          name: _buyerNameController.text.trim(),
                          phone: _buyerPhoneController.text.trim(),
                          email: _buyerEmailController.text.trim(),
                          address: _buyerAddressController.text.trim(),
                        );
                        if (!mounted) return;
                        if (vm.errorMessage != null) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(vm.errorMessage!)),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Infos acquéreur enregistrées'),
                            ),
                          );
                        }
                      },
                      child: const Text('Enregistrer l\'acquéreur'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentsSection(PuppyFileViewModel vm) {
    final locked = !vm.isPremium;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Documents de cession',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                ),
                if (locked)
                  const Icon(Icons.lock_rounded, color: AppColors.premium),
              ],
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: locked ? 0.5 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Certificat d\'engagement et de connaissance',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Pré-rempli avec les informations du chiot.',
                            style: AppTextStyles.captionLabel,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: locked ? AppColors.premium : AppColors.primary,
              ),
              onPressed: () {
                if (locked) {
                  context.push('/premium');
                } else {
                  context.push('/litters/${vm.puppy!.litterId}/documents');
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (locked) ...[
                    const Icon(Icons.lock_rounded, size: 18),
                    const SizedBox(width: 8),
                  ],
                  const Text('Générer le document de cession'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
