import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/operation_state.dart';
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
      // Load the real puppies of this litter from the server. The view model
      // resolves the species label itself; the screen passes nothing but the
      // route's litterId.
      context.read<PuppyBatchViewModel>().loadLitterPuppies(widget.litterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PuppyBatchViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Saisie des ${viewModel.youngNounPlural}'),
      ),
      body: viewModel.state == OperationState.loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: viewModel.items.isEmpty
                            // Empty-but-loaded state: the litter has no puppies
                            // yet. Offer the add button instead of a blank grid.
                            ? _buildEmptyState(viewModel)
                            : LayoutBuilder(
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
                                        return _buildPuppyRow(
                                          index,
                                          item,
                                          viewModel,
                                        );
                                      },
                                    );
                                  } else {
                                    return ListView.builder(
                                      padding: const EdgeInsets.all(16.0),
                                      itemCount: viewModel.items.length,
                                      itemBuilder: (context, index) {
                                        final item = viewModel.items[index];
                                        return _buildPuppyRow(
                                          index,
                                          item,
                                          viewModel,
                                        );
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

  Widget _buildEmptyState(PuppyBatchViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun ${vm.youngNoun} déclaré pour cette portée.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
              ),
              onPressed: vm.addItem,
              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
              label: Text(
                'Ajouter un ${vm.youngNoun}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
                    decoration: InputDecoration(
                      labelText: 'Nom du ${vm.youngNoun}',
                      contentPadding: const EdgeInsets.symmetric(
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
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: () => vm.removeItem(index),
                ),
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
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
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
            label: Text(
              'Ajouter un ${vm.youngNoun}',
              style: const TextStyle(
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
                final messenger = ScaffoldMessenger.of(context);
                final success = await vm.saveBatch(widget.litterId);
                if (!mounted) return;
                if (success) {
                  // Reload details of this litter
                  litterDetailVm.loadLitterDetail(widget.litterId);
                  goRouter.go('/litters/${widget.litterId}');
                } else {
                  // F05 smoke test: the refused puppy (e.g. with a weighing
                  // history) has just reappeared in the list (VM reloads from
                  // source of truth on failure); surface the server-authored
                  // business message from the mapper.
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        vm.errorMessage ??
                            'Échec de l\'enregistrement. Vérifiez votre connexion '
                                'et réessayez.',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Enregistrer les ${vm.items.length} ${vm.youngNounPlural}',
            ),
          ),
        ],
      ),
    );
  }
}
