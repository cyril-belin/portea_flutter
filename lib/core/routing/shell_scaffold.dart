import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../../features/dashboard/presentation/view_models/dashboard_view_model.dart';
import '../../features/breeders/presentation/view_models/breeder_list_view_model.dart';
import '../../features/litters/presentation/view_models/litters_view_model.dart';

class ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScaffold({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );

    // The app uses a StatefulShellRoute.indexedStack: each tab screen is kept
    // alive in memory, so initState (and thus its initial data load) runs only
    // once. When the user comes back to a tab, we refresh its data so it
    // reflects any change made elsewhere (e.g. a newly declared litter must
    // appear on the Dashboard without a manual pull-to-refresh).
    switch (index) {
      case 0:
        context.read<DashboardViewModel>().loadDashboard();
      case 1:
        context.read<BreederListViewModel>().loadBreeders();
      case 2:
        context.read<LittersViewModel>().loadLitters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 720) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) => _onTap(context, index),
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 20,
                      child: Icon(
                        Icons.pets_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_rounded),
                      label: Text('Accueil'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.pets_rounded),
                      label: Text('Reproducteurs'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.layers_rounded),
                      label: Text('Portées'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_rounded),
                      label: Text('Réglages'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 0.5),
                Expanded(
                  child: navigationShell,
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _onTap(context, index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_rounded),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pets_rounded),
                  label: 'Reproducteurs',
                ),
                NavigationDestination(
                  icon: Icon(Icons.layers_rounded),
                  label: 'Portées',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Réglages',
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
