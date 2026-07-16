import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/litter_declaration_view_model.dart';
import '../view_models/litters_view_model.dart';

class LitterDeclarationScreen extends StatefulWidget {
  const LitterDeclarationScreen({super.key});

  @override
  State<LitterDeclarationScreen> createState() =>
      _LitterDeclarationScreenState();
}

class _LitterDeclarationScreenState extends State<LitterDeclarationScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedMotherId;
  int? _selectedFatherId;
  bool _isExternalSire = false;

  final _externalSireNameController = TextEditingController();
  final _externalSireIdController = TextEditingController();

  DateTime _birthDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LitterDeclarationViewModel>().loadBreedersForDeclaration();
    });
  }

  @override
  void dispose() {
    _externalSireNameController.dispose();
    _externalSireIdController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2020),
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
    final viewModel = context.watch<LitterDeclarationViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Déclarer une portée'),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Nouvelle portée',
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Remplissez les détails des parents et de la naissance.',
                          style: AppTextStyles.captionLabel,
                        ),
                        const SizedBox(height: 24),

                        // Mother Dropdown
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Mère (reproductrice active)',
                          ),
                          initialValue: _selectedMotherId,
                          items: viewModel.mothers.map((m) {
                            return DropdownMenuItem<int>(
                              value: m.id,
                              child: Text(m.name),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedMotherId = val),
                          validator: (val) =>
                              val == null ? 'Veuillez choisir la mère' : null,
                        ),
                        const SizedBox(height: 16),

                        // Sire selector option (Internal or External)
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text('Père de l\'élevage'),
                                ),
                                selected: !_isExternalSire,
                                selectedColor: AppColors.primary,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: !_isExternalSire ? Colors.white : null,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _isExternalSire = false);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text('Père extérieur'),
                                ),
                                selected: _isExternalSire,
                                selectedColor: AppColors.primary,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: _isExternalSire ? Colors.white : null,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _isExternalSire = true);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Father options depending on selection
                        if (!_isExternalSire)
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Père (reproducteur actif)',
                            ),
                            initialValue: _selectedFatherId,
                            items: viewModel.fathers.map((f) {
                              return DropdownMenuItem<int>(
                                value: f.id,
                                child: Text(f.name),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedFatherId = val),
                            validator: (val) => !_isExternalSire && val == null
                                ? 'Veuillez choisir le père'
                                : null,
                          )
                        else ...[
                          TextFormField(
                            controller: _externalSireNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom du mâle extérieur',
                              hintText: 'Ex: Rocky',
                            ),
                            validator: (val) =>
                                _isExternalSire &&
                                    (val == null || val.trim().isEmpty)
                                ? 'Veuillez entrer le nom du père'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _externalSireIdController,
                            decoration: const InputDecoration(
                              labelText: 'N° puce/tatouage du père (optionnel)',
                              hintText: 'Ex: 250268...',
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Birth date picker
                        InkWell(
                          onTap: () => _selectBirthDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date de mise bas',
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
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
                        const SizedBox(height: 32),

                        // Declare button
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final littersVm = context
                                  .read<LittersViewModel>();
                              final goRouter = GoRouter.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final result = await viewModel.declareLitter(
                                motherId: _selectedMotherId!,
                                fatherId: _isExternalSire
                                    ? null
                                    : _selectedFatherId,
                                externalSireName: _isExternalSire
                                    ? _externalSireNameController.text
                                    : null,
                                externalSireId: _isExternalSire
                                    ? _externalSireIdController.text
                                    : null,
                                birthDate: _birthDate,
                              );

                              if (!mounted) return;

                              switch (result.outcome) {
                                case LitterDeclarationOutcome.success:
                                  // Refresh litters list
                                  littersVm.loadLitters();
                                  // Navigate to batch creation screen for this litter
                                  goRouter.go(
                                    '/litters/${result.litter!.id}/puppies/batch',
                                  );
                                case LitterDeclarationOutcome
                                    .activeLimitReached:
                                  // Freemium limit reached — open the paywall
                                  // (NOT a generic error message).
                                  goRouter.go('/premium');
                                case LitterDeclarationOutcome.error:
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result.errorMessage ??
                                            'Impossible de déclarer la portée.',
                                      ),
                                    ),
                                  );
                              }
                            }
                          },
                          child: const Text('Déclarer la portée'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
