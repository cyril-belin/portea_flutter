import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animal_list_tile.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../view_models/breeder_list_view_model.dart';

class BreedersListScreen extends StatefulWidget {
  const BreedersListScreen({super.key});

  @override
  State<BreedersListScreen> createState() => _BreedersListScreenState();
}

class _BreedersListScreenState extends State<BreedersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BreederListViewModel>().loadBreeders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BreederListViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reproducteurs'),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: viewModel.breeders.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.pets_rounded,
                        title: 'Aucun reproducteur',
                        subtitle:
                            'Ajoutez vos reproducteurs pour pouvoir déclarer une portée.',
                        primaryActionLabel: 'Ajouter un reproducteur',
                        onPrimaryAction: () => context.push('/breeders/new'),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 650) {
                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 400,
                                    mainAxisExtent: 88,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: viewModel.breeders.length,
                              itemBuilder: (context, index) {
                                final breeder = viewModel.breeders[index];
                                final birthDateStr = breeder.birthDate != null
                                    ? '${breeder.birthDate!.day}/${breeder.birthDate!.month}/${breeder.birthDate!.year}'
                                    : 'Date inconnue';
                                return AnimalListTile(
                                  name: breeder.name,
                                  sex: breeder.sex,
                                  subtitle:
                                      '${breeder.breed ?? "Race inconnue"} • Né le $birthDateStr',
                                  onTap: () =>
                                      context.push('/breeders/${breeder.id}'),
                                );
                              },
                            );
                          } else {
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: viewModel.breeders.length,
                              itemBuilder: (context, index) {
                                final breeder = viewModel.breeders[index];
                                final birthDateStr = breeder.birthDate != null
                                    ? '${breeder.birthDate!.day}/${breeder.birthDate!.month}/${breeder.birthDate!.year}'
                                    : 'Date inconnue';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: AnimalListTile(
                                    name: breeder.name,
                                    sex: breeder.sex,
                                    subtitle:
                                        '${breeder.breed ?? "Race inconnue"} • Né le $birthDateStr',
                                    onTap: () =>
                                        context.push('/breeders/${breeder.id}'),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => context.push('/breeders/new'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
