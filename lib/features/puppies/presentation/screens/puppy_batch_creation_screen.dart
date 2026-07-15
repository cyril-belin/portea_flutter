import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/puppy_batch_view_model.dart';
import '../../../litters/presentation/view_models/litter_detail_view_model.dart';

class PuppyBatchCreationScreen extends StatefulWidget {
  final int litterId;

  const PuppyBatchCreationScreen({super.key, required this.litterId});

  @override
  State<PuppyBatchCreationScreen> createState() =>
      _PuppyBatchCreationScreenState();
}

class _PuppyBatchCreationScreenState extends State<PuppyBatchCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // In a mock environment we load with default values or read existing ones if any
      context.read<PuppyBatchViewModel>().loadLitterPuppies([]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PuppyBatchViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saisie des chiots'),
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
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 700) {
                              return GridView.builder(
                                padding: const EdgeInsets.all(16.0),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 500,
                                  mainAxisExtent: 160,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: viewModel.items.length,
                                itemBuilder: (context, index) {
                                  final item = viewModel.items[index];
                                  return _buildPuppyRow(index, item, viewModel);
                                },
                              );
                            } else {
                              return ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: viewModel.items.length,
                                itemBuilder: (context, index) {
                                  final item = viewModel.items[index];
                                  return _buildPuppyRow(index, item, viewModel);
                                },
                              );
                            }
                          },
                        ),
                      ),
                      _buildBottomBar(context, viewModel),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPuppyRow(
    int index,
    PuppyBatchItem item,
    PuppyBatchViewModel vm,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: item.name,
                    decoration: const InputDecoration(
                      labelText: 'Nom du chiot',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (val) => item.name = val,
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          padding: EdgeInsets.zero,
                          label: const Text(
                            '♀',
                            style: TextStyle(fontSize: 14),
                          ),
                          selected: item.sex == 'female',
                          selectedColor: AppColors.female,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: item.sex == 'female' ? Colors.white : null,
                          ),
                          onSelected: (selected) {
                            if (selected) vm.updateSex(index, 'female');
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ChoiceChip(
                          padding: EdgeInsets.zero,
                          label: const Text(
                            '♂',
                            style: TextStyle(fontSize: 14),
                          ),
                          selected: item.sex == 'male',
                          selectedColor: AppColors.male,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: item.sex == 'male' ? Colors.white : null,
                          ),
                          onSelected: (selected) {
                            if (selected) vm.updateSex(index, 'male');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (vm.items.length > 1) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                    onPressed: () => vm.removeItem(index),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.color,
                    decoration: const InputDecoration(
                      labelText: 'Couleur',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (val) => item.color = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.birthWeight > 0
                        ? item.birthWeight.toStringAsFixed(0)
                        : '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Poids (g)',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (val) {
                      item.birthWeight = double.tryParse(val) ?? 0.0;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, PuppyBatchViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.primary),
            ),
            onPressed: vm.addItem,
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            label: const Text(
              'Ajouter un chiot',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final litterDetailVm = context.read<LitterDetailViewModel>();
                final goRouter = GoRouter.of(context);
                final success = await vm.saveBatch(widget.litterId);
                if (success && mounted) {
                  // Reload details of this litter
                  litterDetailVm.loadLitterDetail(widget.litterId);
                  goRouter.go('/litters/${widget.litterId}');
                }
              }
            },
            child: Text('Enregistrer les ${vm.items.length} chiots'),
          ),
        ],
      ),
    );
  }
}
