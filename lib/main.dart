import 'package:portea_client/portea_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:provider/provider.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/auth/authenticated_listenable.dart';
import 'core/notifications/notification_service.dart';

// Import repositories
import 'features/onboarding/domain/repositories/i_kennel_repository.dart';
import 'features/onboarding/data/repositories/serverpod_kennel_repository.dart';
import 'features/breeders/domain/repositories/i_breeder_repository.dart';
import 'features/breeders/data/repositories/serverpod_breeder_repository.dart';
import 'features/litters/domain/repositories/i_litter_repository.dart';
import 'features/litters/data/repositories/serverpod_litter_repository.dart';
import 'features/puppies/domain/repositories/i_puppy_repository.dart';
import 'features/puppies/data/repositories/mock_puppy_repository.dart';
import 'features/puppies/domain/repositories/i_weighing_repository.dart';
import 'features/puppies/data/repositories/mock_weighing_repository.dart';
import 'features/puppies/domain/repositories/i_care_repository.dart';
import 'features/puppies/data/repositories/mock_care_repository.dart';
import 'features/settings/domain/repositories/i_settings_repository.dart';
import 'features/settings/data/repositories/mock_settings_repository.dart';

// Import view models
import 'features/onboarding/presentation/view_models/onboarding_view_model.dart';
import 'features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'features/breeders/presentation/view_models/breeder_list_view_model.dart';
import 'features/breeders/presentation/view_models/breeder_profile_view_model.dart';
import 'features/litters/presentation/view_models/litters_view_model.dart';
import 'features/litters/presentation/view_models/litter_detail_view_model.dart';
import 'features/litters/presentation/view_models/litter_declaration_view_model.dart';
import 'features/puppies/presentation/view_models/puppy_batch_view_model.dart';
import 'features/puppies/presentation/view_models/group_weighing_view_model.dart';
import 'features/puppies/presentation/view_models/puppy_file_view_model.dart';
import 'features/puppies/presentation/view_models/add_care_view_model.dart';
import 'features/settings/presentation/view_models/settings_view_model.dart';

/// Sets up a global client object that can be used to talk to the server from
/// anywhere in our app. The client is generated from your server code
/// and is set up to connect to a Serverpod running on a local server on
/// the default port. You will need to modify this to connect to staging or
/// production servers.
late final Client client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final serverUrl = await getServerUrl();

  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();

  client.auth.initialize();

  // Expose the auth state as a simple bool listenable so view models stay
  // decoupled from Serverpod's auth session types.
  final authListenable = AuthenticatedListenable(
    client.auth.authInfoListenable,
  );

  // Create core repositories
  final kennelRepository = ServerpodKennelRepository(client);
  final breederRepository = ServerpodBreederRepository(client);
  final litterRepository = ServerpodLitterRepository(client);
  final puppyRepository = MockPuppyRepository();
  final weighingRepository = MockWeighingRepository();
  final careRepository = MockCareRepository();
  final settingsRepository = MockSettingsRepository();

  // Core services
  final notificationService = NotificationService();

  // Pre-instantiate OnboardingViewModel because GoRouter needs it for refreshListenable
  final onboardingViewModel = OnboardingViewModel(
    kennelRepository: kennelRepository,
    authListenable: authListenable,
  );

  runApp(
    MultiProvider(
      providers: [
        // Repositories injection
        Provider<IKennelRepository>.value(value: kennelRepository),
        Provider<IBreederRepository>.value(value: breederRepository),
        Provider<ILitterRepository>.value(value: litterRepository),
        Provider<IPuppyRepository>.value(value: puppyRepository),
        Provider<IWeighingRepository>.value(value: weighingRepository),
        Provider<ICareRepository>.value(value: careRepository),
        Provider<ISettingsRepository>.value(value: settingsRepository),

        // Core services
        Provider<NotificationService>.value(value: notificationService),

        // View models injection
        ChangeNotifierProvider<OnboardingViewModel>.value(
          value: onboardingViewModel,
        ),
        ChangeNotifierProxyProvider6<
          IKennelRepository,
          IBreederRepository,
          ILitterRepository,
          IPuppyRepository,
          ICareRepository,
          ISettingsRepository,
          DashboardViewModel
        >(
          create: (context) => DashboardViewModel(
            kennelRepository: context.read<IKennelRepository>(),
            breederRepository: context.read<IBreederRepository>(),
            litterRepository: context.read<ILitterRepository>(),
            puppyRepository: context.read<IPuppyRepository>(),
            careRepository: context.read<ICareRepository>(),
            settingsRepository: context.read<ISettingsRepository>(),
          ),
          update: (context, k, b, l, p, c, s, prev) =>
              prev ??
              DashboardViewModel(
                kennelRepository: k,
                breederRepository: b,
                litterRepository: l,
                puppyRepository: p,
                careRepository: c,
                settingsRepository: s,
              ),
        ),
        ChangeNotifierProxyProvider<IBreederRepository, BreederListViewModel>(
          create: (context) => BreederListViewModel(
            breederRepository: context.read<IBreederRepository>(),
          ),
          update: (context, repo, prev) =>
              prev ?? BreederListViewModel(breederRepository: repo),
        ),
        ChangeNotifierProxyProvider<
          IBreederRepository,
          BreederProfileViewModel
        >(
          create: (context) => BreederProfileViewModel(
            breederRepository: context.read<IBreederRepository>(),
          ),
          update: (context, repo, prev) =>
              prev ?? BreederProfileViewModel(breederRepository: repo),
        ),
        ChangeNotifierProxyProvider3<
          ILitterRepository,
          IBreederRepository,
          ISettingsRepository,
          LittersViewModel
        >(
          create: (context) => LittersViewModel(
            litterRepository: context.read<ILitterRepository>(),
            breederRepository: context.read<IBreederRepository>(),
            settingsRepository: context.read<ISettingsRepository>(),
          ),
          update: (context, litterRepo, breederRepo, settingsRepo, prev) =>
              prev ??
              LittersViewModel(
                litterRepository: litterRepo,
                breederRepository: breederRepo,
                settingsRepository: settingsRepo,
              ),
        ),
        ChangeNotifierProxyProvider3<
          ILitterRepository,
          IBreederRepository,
          IPuppyRepository,
          LitterDetailViewModel
        >(
          create: (context) => LitterDetailViewModel(
            litterRepository: context.read<ILitterRepository>(),
            breederRepository: context.read<IBreederRepository>(),
            puppyRepository: context.read<IPuppyRepository>(),
          ),
          update: (context, litterRepo, breederRepo, puppyRepo, prev) =>
              prev ??
              LitterDetailViewModel(
                litterRepository: litterRepo,
                breederRepository: breederRepo,
                puppyRepository: puppyRepo,
              ),
        ),
        ChangeNotifierProxyProvider2<
          ILitterRepository,
          IBreederRepository,
          LitterDeclarationViewModel
        >(
          create: (context) => LitterDeclarationViewModel(
            litterRepository: context.read<ILitterRepository>(),
            breederRepository: context.read<IBreederRepository>(),
          ),
          update: (context, litterRepo, breederRepo, prev) =>
              prev ??
              LitterDeclarationViewModel(
                litterRepository: litterRepo,
                breederRepository: breederRepo,
              ),
        ),
        ChangeNotifierProxyProvider<IPuppyRepository, PuppyBatchViewModel>(
          create: (context) => PuppyBatchViewModel(
            puppyRepository: context.read<IPuppyRepository>(),
          ),
          update: (context, repo, prev) =>
              prev ?? PuppyBatchViewModel(puppyRepository: repo),
        ),
        ChangeNotifierProxyProvider2<
          IPuppyRepository,
          IWeighingRepository,
          GroupWeighingViewModel
        >(
          create: (context) => GroupWeighingViewModel(
            puppyRepository: context.read<IPuppyRepository>(),
            weighingRepository: context.read<IWeighingRepository>(),
          ),
          update: (context, puppyRepo, weighingRepo, prev) =>
              prev ??
              GroupWeighingViewModel(
                puppyRepository: puppyRepo,
                weighingRepository: weighingRepo,
              ),
        ),
        ChangeNotifierProxyProvider4<
          IPuppyRepository,
          IWeighingRepository,
          ICareRepository,
          ISettingsRepository,
          PuppyFileViewModel
        >(
          create: (context) => PuppyFileViewModel(
            puppyRepository: context.read<IPuppyRepository>(),
            weighingRepository: context.read<IWeighingRepository>(),
            careRepository: context.read<ICareRepository>(),
            settingsRepository: context.read<ISettingsRepository>(),
          ),
          update: (context, puppy, weighing, care, settings, prev) =>
              prev ??
              PuppyFileViewModel(
                puppyRepository: puppy,
                weighingRepository: weighing,
                careRepository: care,
                settingsRepository: settings,
              ),
        ),
        ChangeNotifierProxyProvider2<
          IPuppyRepository,
          ICareRepository,
          AddCareViewModel
        >(
          create: (context) => AddCareViewModel(
            puppyRepository: context.read<IPuppyRepository>(),
            careRepository: context.read<ICareRepository>(),
          ),
          update: (context, puppy, care, prev) =>
              prev ??
              AddCareViewModel(
                puppyRepository: puppy,
                careRepository: care,
              ),
        ),
        ChangeNotifierProxyProvider2<
          IKennelRepository,
          ISettingsRepository,
          SettingsViewModel
        >(
          create: (context) => SettingsViewModel(
            kennelRepository: context.read<IKennelRepository>(),
            settingsRepository: context.read<ISettingsRepository>(),
          )..loadSettings(),
          update: (context, kennel, settings, prev) =>
              prev ??
                    SettingsViewModel(
                      kennelRepository: kennel,
                      settingsRepository: settings,
                    )
                ..loadSettings(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final onboardingVM = context.read<OnboardingViewModel>();
    _router = createRouter(onboardingVM);
  }

  @override
  Widget build(BuildContext context) {
    final settingsVM = context.watch<SettingsViewModel>();

    return MaterialApp.router(
      routerConfig: _router,
      title: 'Portea',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsVM.themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
