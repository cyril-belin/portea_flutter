import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge_widget.dart';
import '../view_models/puppy_file_view_model.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<PuppyFileViewModel>();
      await vm.loadPuppyFile(widget.id);
      if (vm.puppy != null) {
        _buyerNameController.text = vm.puppy!.buyerName ?? '';
        _buyerPhoneController.text = vm.puppy!.buyerPhone ?? '';
        _buyerEmailController.text = vm.puppy!.buyerEmail ?? '';
        _buyerAddressController.text = vm.puppy!.buyerAddress ?? '';
      }
    });
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _buyerEmailController.dispose();
    _buyerAddressController.dispose();
    _weightController.dispose();
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
                  await vm.addSingleWeight(w);
                  _weightController.clear();
                  if (mounted) nav.pop();
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

    if (viewModel.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final puppy = viewModel.puppy;
    if (puppy == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chiot introuvable')),
        body: const Center(child: Text('Ce chiot n\'existe pas.')),
      );
    }

    final isFemale = puppy.sex.toLowerCase() == 'female' || puppy.sex == '♀';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Section
            _buildHeader(puppy, isFemale),
            const SizedBox(height: 24),

            // 2. Weight Curve stub
            _buildWeightCurveSection(),
            const SizedBox(height: 24),

            // 3. Weight History
            _buildWeightHistorySection(viewModel),
            const SizedBox(height: 24),

            // 4. Health / Care timeline
            _buildHealthSection(viewModel),
            const SizedBox(height: 24),

            // 5. Buyer & Status section
            _buildBuyerSection(puppy, viewModel),
            const SizedBox(height: 24),

            // 6. Documents Cession
            _buildDocumentsSection(viewModel),
          ],
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

  Widget _buildWeightCurveSection() {
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
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Graphique de croissance',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
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
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.border),
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

  Widget _buildBuyerSection(dynamic puppy, PuppyFileViewModel vm) {
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
                onSelected: (selected) {
                  if (selected) vm.updateStatus('available');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Réservé')),
                selected: puppy.status == 'reserved',
                onSelected: (selected) {
                  if (selected) vm.updateStatus('reserved');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Vendu')),
                selected: puppy.status == 'sold',
                onSelected: (selected) {
                  if (selected) vm.updateStatus('sold');
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
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _buyerEmailController,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _buyerAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse postale',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await vm.saveBuyerInfo(
                        name: _buyerNameController.text.trim(),
                        phone: _buyerPhoneController.text.trim(),
                        email: _buyerEmailController.text.trim(),
                        address: _buyerAddressController.text.trim(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
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
                  border: Border.all(color: AppColors.border),
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
