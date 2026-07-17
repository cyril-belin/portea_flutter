import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/add_care_view_model.dart';
import '../../../litters/presentation/view_models/litter_detail_view_model.dart';
import '../view_models/puppy_file_view_model.dart';

class AddCareScreen extends StatefulWidget {
  final int litterId;
  final int? puppyId;

  const AddCareScreen({
    super.key,
    required this.litterId,
    this.puppyId,
  });

  @override
  State<AddCareScreen> createState() => _AddCareScreenState();
}

class _AddCareScreenState extends State<AddCareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'vaccine'; // 'vaccine' | 'deworming' | 'other'
  DateTime _date = DateTime.now();
  bool _targetAllLitter = true;
  bool _setReminder = false;
  int _reminderDays = 15;

  @override
  void initState() {
    super.initState();
    if (widget.puppyId != null) {
      _targetAllLitter = false;
    }
  }

  @override
  void dispose() {
    _productController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddCareViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un soin'),
      ),
      body: viewModel.isBusy
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
                        // Segmented control type
                        Text(
                          'Type de soin',
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
                                label: const Center(child: Text('Vaccin')),
                                selected: _type == 'vaccine',
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _type = 'vaccine');
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Vermifuge')),
                                selected: _type == 'deworming',
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _type = 'deworming');
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Autre')),
                                selected: _type == 'other',
                                onSelected: (selected) {
                                  if (selected) setState(() => _type = 'other');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Product field
                        TextFormField(
                          controller: _productController,
                          decoration: const InputDecoration(
                            labelText: 'Produit',
                            hintText: 'Ex: Milbemax, CHPPIL...',
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Veuillez entrer le produit'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Date picker
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date du soin',
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_date.day}/${_date.month}/${_date.year}',
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

                        // Target toggle (Puppy vs Litter)
                        if (widget.puppyId != null) ...[
                          Text(
                            'Cible',
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
                                  label: const Center(
                                    child: Text('Cet animal uniquement'),
                                  ),
                                  selected: !_targetAllLitter,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _targetAllLitter = false);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(
                                    child: Text('Toute la portée'),
                                  ),
                                  selected: _targetAllLitter,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _targetAllLitter = true);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Reminder section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: Text(
                                    'Programmer un rappel',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  value: _setReminder,
                                  onChanged: (val) =>
                                      setState(() => _setReminder = val),
                                ),
                                if (_setReminder) ...[
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Délai :',
                                        style: AppTextStyles.body,
                                      ),
                                      DropdownButton<int>(
                                        value: _reminderDays,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 7,
                                            child: Text('Dans 7 jours'),
                                          ),
                                          DropdownMenuItem(
                                            value: 15,
                                            child: Text('Dans 15 jours'),
                                          ),
                                          DropdownMenuItem(
                                            value: 30,
                                            child: Text('Dans 30 jours'),
                                          ),
                                          DropdownMenuItem(
                                            value: 90,
                                            child: Text('Dans 3 mois'),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _reminderDays = val);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes / Remarques (optionnel)',
                            hintText:
                                'Ex: Bien toléré, pris pendant le repas...',
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final DateTime? reminderDate = _setReminder
                                  ? _date.add(Duration(days: _reminderDays))
                                  : null;

                              final litterDetailVm = context
                                  .read<LitterDetailViewModel>();
                              final puppyFileVm = widget.puppyId != null
                                  ? context.read<PuppyFileViewModel>()
                                  : null;
                              final router = GoRouter.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final success = await viewModel.saveCareEntry(
                                type: _type,
                                product: _productController.text.trim(),
                                date: _date,
                                puppyId: widget.puppyId,
                                litterId: widget.litterId,
                                targetAllLitter: _targetAllLitter,
                                reminderDate: reminderDate,
                                notes: _notesController.text.trim().isEmpty
                                    ? null
                                    : _notesController.text.trim(),
                              );

                              if (!mounted) return;
                              if (success) {
                                // Refresh callers
                                litterDetailVm.loadLitterDetail(
                                  widget.litterId,
                                );
                                puppyFileVm?.loadPuppyFile(widget.puppyId!);
                                router.pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Soin enregistré'),
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      viewModel.errorMessage ??
                                          'Enregistrement impossible.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Enregistrer le soin'),
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
