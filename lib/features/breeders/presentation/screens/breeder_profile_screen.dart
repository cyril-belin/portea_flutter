import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/breeder_profile_view_model.dart';
import '../view_models/breeder_list_view_model.dart';

class BreederProfileScreen extends StatefulWidget {
  final int? id;

  const BreederProfileScreen({super.key, this.id});

  @override
  State<BreederProfileScreen> createState() => _BreederProfileScreenState();
}

class _BreederProfileScreenState extends State<BreederProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _chipController = TextEditingController();
  final _tattooController = TextEditingController();

  String _sex = 'female';
  String _status = 'active';
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<BreederProfileViewModel>();
      if (widget.id != null) {
        await viewModel.loadBreeder(widget.id!);
        final b = viewModel.breeder;
        if (b != null) {
          _nameController.text = b.name;
          _breedController.text = b.breed ?? '';
          _chipController.text = b.chipNumber ?? '';
          _tattooController.text = b.tattooNumber ?? '';
          setState(() {
            _sex = b.sex;
            _status = b.status;
            _birthDate = b.birthDate;
          });
        }
      } else {
        viewModel.setupNewBreeder();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _chipController.dispose();
    _tattooController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 2)),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BreederProfileViewModel>();
    final isEditing = widget.id != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Fiche Reproducteur' : 'Nouveau Reproducteur'),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar Placeholder
                    Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: _sex == 'female'
                            ? AppColors.female.withValues(alpha: 0.1)
                            : AppColors.male.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.pets_rounded,
                          size: 48,
                          color: _sex == 'female'
                              ? AppColors.female
                              : AppColors.male,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nom
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'animal',
                        hintText: 'Ex: Salsa',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sexe Selector
                    Text(
                      'Sexe',
                      style: AppTextStyles.captionLabel.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Femelle ♀')),
                            selected: _sex == 'female',
                            selectedColor: AppColors.female.withValues(alpha: 0.2),
                            onSelected: (selected) {
                              if (selected) setState(() => _sex = 'female');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Mâle ♂')),
                            selected: _sex == 'male',
                            selectedColor: AppColors.male.withValues(alpha: 0.2),
                            onSelected: (selected) {
                              if (selected) setState(() => _sex = 'male');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Race
                    TextFormField(
                      controller: _breedController,
                      decoration: const InputDecoration(
                        labelText: 'Race',
                        hintText: 'Ex: Golden Retriever',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date de naissance
                    InkWell(
                      onTap: () => _selectBirthDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de naissance',
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _birthDate == null
                                  ? 'Sélectionner une date'
                                  : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                              style: AppTextStyles.body,
                            ),
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Identification Puce/Tatouage
                    TextFormField(
                      controller: _chipController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'N° de Puce (I-CAD)',
                        hintText: 'Ex: 250268...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tattooController,
                      decoration: const InputDecoration(
                        labelText: 'N° de Tatouage',
                        hintText: 'Ex: XXX123',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Statut Actif/Retraité
                    Text(
                      'Statut',
                      style: AppTextStyles.captionLabel.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Actif')),
                            selected: _status == 'active',
                            onSelected: (selected) {
                              if (selected) setState(() => _status = 'active');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Retraité')),
                            selected: _status == 'retired',
                            onSelected: (selected) {
                              if (selected) setState(() => _status = 'retired');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final listVm = context.read<BreederListViewModel>();
                          final goRouter = GoRouter.of(context);
                          final success = await viewModel.saveBreeder(
                            name: _nameController.text.trim(),
                            sex: _sex,
                            breed: _breedController.text.trim(),
                            birthDate: _birthDate,
                            chipNumber: _chipController.text.trim(),
                            tattooNumber: _tattooController.text.trim(),
                            status: _status,
                          );
                          if (success && mounted) {
                            listVm.loadBreeders();
                            goRouter.pop();
                          }
                        }
                      },
                      child: Text(
                        isEditing
                            ? 'Enregistrer les modifications'
                            : 'Créer le reproducteur',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
