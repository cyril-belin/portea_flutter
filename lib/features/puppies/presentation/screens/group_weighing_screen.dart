import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/group_weighing_view_model.dart';
import '../../../litters/presentation/view_models/litter_detail_view_model.dart';

class GroupWeighingScreen extends StatefulWidget {
  final int litterId;

  const GroupWeighingScreen({super.key, required this.litterId});

  @override
  State<GroupWeighingScreen> createState() => _GroupWeighingScreenState();
}

class _GroupWeighingScreenState extends State<GroupWeighingScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupWeighingViewModel>().loadLitterPuppies(widget.litterId);
    });
  }

  Future<void> _selectDateTime(
    BuildContext context,
    GroupWeighingViewModel vm,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: vm.weighedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(vm.weighedAt),
      );
      if (pickedTime != null) {
        vm.weighedAt = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroupWeighingViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesée groupée'),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Date selector
                      InkWell(
                        onTap: () => _selectDateTime(context, viewModel),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: AppColors.primaryLight.withValues(alpha: 0.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Date de la pesée :',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${viewModel.weighedAt.day}/${viewModel.weighedAt.month}/${viewModel.weighedAt.year} à ${viewModel.weighedAt.hour}:${viewModel.weighedAt.minute.toString().padLeft(2, '0')}',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.edit_calendar_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 700) {
                              return GridView.builder(
                                padding: const EdgeInsets.all(16.0),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 500,
                                  mainAxisExtent: 88,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: viewModel.items.length,
                                itemBuilder: (context, index) {
                                  final item = viewModel.items[index];
                                  return _buildWeighingRow(index, item, viewModel);
                                },
                              );
                            } else {
                              return ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: viewModel.items.length,
                                itemBuilder: (context, index) {
                                  final item = viewModel.items[index];
                                  return _buildWeighingRow(index, item, viewModel);
                                },
                              );
                            }
                          },
                        ),
                      ),

                      // Bottom Save bar
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(
                            top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final litterDetailVm =
                                  context.read<LitterDetailViewModel>();
                              final goRouter = GoRouter.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final success = await viewModel.saveWeighingSession();
                              if (success && mounted) {
                                // Refresh litter detail
                                litterDetailVm.loadLitterDetail(widget.litterId);
                                goRouter.pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Pesée de la portée enregistrée'),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Enregistrer la pesée'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWeighingRow(
    int index,
    dynamic item,
    GroupWeighingViewModel viewModel,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.lastWeight != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Dernier poids : ${item.lastWeight!.toStringAsFixed(0)} g',
                      style: AppTextStyles.captionLabel,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextFormField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                decoration: const InputDecoration(
                  hintText: '0',
                  suffixText: ' g',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (val) {
                  viewModel.updateWeight(
                    index,
                    double.tryParse(val),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
