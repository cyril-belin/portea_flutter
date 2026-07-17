import 'package:portea_client/portea_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:provider/provider.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/auth/authenticated_listenable.dart';
import 'core/notifications/inotification_service.dart';
import 'core/notifications/notification_service.dart';

// Import repositories
import 'features/onboarding/domain/repositories/i_kennel_repository.dart';
import 'features/onboarding/data/repositories/serverpod_kennel_repository.dart';
import 'features/breeders/domain/repositories/i_breeder_repository.dart';
import 'features/breeders/data/repositories/serverpod_breeder_repository.dart';
import 'features/litters/domain/repositories/i_litter_repository.dart';
import 'features/litters/data/repositories/serverpod_litter_repository.dart';
import 'features/puppies/domain/repositories/i_puppy_repository.dart';
import 'features/puppies/data/repositories/serverpod_puppy_repository.dart';
import 'features/puppies/domain/repositories/i_weighing_repository.dart';
import 'features/puppies/data/repositories/serverpod_weighing_repository.dart';
import 'features/puppies/domain/repositories/i_care_repository.dart';
import 'features/puppies/data/repositories/serverpod_care_repository.dart';
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
  final puppyRepository = ServerpodPuppyRepository(client);
  final weighingRepository = ServerpodWeighingRepository(client);
  final careRepository = ServerpodCareRepository(client);
  final settingsRepository = MockSettingsRepository();

  // Core services
  final notificationService = NotificationService();

  // F07: initialize the notification plugin + resolve the device timezone before
  // runApp, so reminders can be scheduled and a notification that LAUNCHED the
  // app (killed-app case) can be routed. The tap callback is bound to the
  // GoRouter once it exists (see NotificationRouter + _MyAppState).
  await notificationService.initialize(
    onNotificationTap: NotificationRouter.handle,
  );

  // Capture a notification that LAUNCHED the app (killed-app case). Routed
  // after the router is bound — see _MyAppState + NotificationRouter.
  final launchDetails = await notificationService
      .getNotificationAppLaunchDetails();
  if (launchDetails != null && launchDetails.didLaunchApp) {
    NotificationRouter.queueLaunch(launchDetails.payload);
  }

  // Pre-instantiate OnboardingViewModel because GoRouter needs it for refreshListenable
  final onboardingViewModel = OnboardingViewModel(
    kennelRepository: kennelRepository,
    careRepository: careRepository,
    puppyRepository: puppyRepository,
    litterRepository: litterRepository,
    breederRepository: breederRepository,
    notificationService: notificationService,
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

        // Core services. INotificationService is what view models depend on
        // (testable, mockable); NotificationService stays available for the few
        // widgets that read the concrete type (e.g. onboarding screen).
        Provider<INotificationService>.value(value: notificationService),
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
        ChangeNotifierProxyProvider2<
          IKennelRepository,
          IPuppyRepository,
          PuppyBatchViewModel
        >(
          create: (context) => PuppyBatchViewModel(
            kennelRepository: context.read<IKennelRepository>(),
            puppyRepository: context.read<IPuppyRepository>(),
          ),
          update: (context, kennelRepo, puppyRepo, prev) =>
              prev ??
              PuppyBatchViewModel(
                kennelRepository: kennelRepo,
                puppyRepository: puppyRepo,
              ),
        ),
        ChangeNotifierProxyProvider<
          IWeighingRepository,
          GroupWeighingViewModel
        >(
          create: (context) => GroupWeighingViewModel(
            weighingRepository: context.read<IWeighingRepository>(),
          ),
          update: (context, weighingRepo, prev) =>
              prev ??
              GroupWeighingViewModel(
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
        ChangeNotifierProxyProvider<ICareRepository, AddCareViewModel>(
          create: (context) => AddCareViewModel(
            careRepository: context.read<ICareRepository>(),
            notificationService: context.read<INotificationService>(),
          ),
          update: (context, care, prev) =>
              prev ??
              AddCareViewModel(
                careRepository: care,
                notificationService: context.read<INotificationService>(),
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

    // Bind the router so notification taps (app-alive) and the launch payload
    // (app-killed) can deep-link. addPostFrameCallback ensures the router is
    // mounted in the tree before pushing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationRouter.bind(_router);
      NotificationRouter.consumePendingLaunch();
    });
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

/// Bridge between notification taps and the go_router.
///
/// Two paths exist (F07 spec, verdict §6): the tap while the app is alive
/// ([handle], set as the plugin's `onDidReceiveNotificationResponse` callback)
/// and the tap that LAUNCHED the killed app ([queueLaunch] captured in main →
/// [consumePendingLaunch] routed once the router is mounted). Invalid payloads
/// fall back to the dashboard — never crash.
class NotificationRouter {
  NotificationRouter._();

  static GoRouter? _router;
  static String? _pendingLaunch;

  /// Binds the router so taps can navigate. Called once from _MyAppState after
  /// the router is created.
  static void bind(GoRouter router) => _router = router;

  /// Routes a tap payload (app-alive case).
  static void handle(String payload) {
    _router?.push(parseNotificationPayload(payload));
  }

  /// Stores a launch payload captured in main() (app-killed case) for routing
  /// after the router is bound.
  static void queueLaunch(String? payload) {
    _pendingLaunch = (payload == null || payload.isEmpty) ? null : payload;
  }

  /// Routes the stored launch payload once, then clears it. Called from
  /// _MyAppState after bind().
  static void consumePendingLaunch() {
    final payload = _pendingLaunch;
    if (payload == null) return;
    _pendingLaunch = null;
    _router?.push(parseNotificationPayload(payload));
  }
}
