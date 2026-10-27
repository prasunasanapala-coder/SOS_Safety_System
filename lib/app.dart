import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/history_provider.dart';
import 'providers/location_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/sos_provider.dart';
import 'providers/tips_provider.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';
import 'services/data_repository.dart';
import 'services/location_service.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'services/tips_api_service.dart';
import 'theme/app_theme.dart';

/// All services the app needs. `main.dart` passes real ones; tests pass fakes.
class AppDependencies {
  const AppDependencies({
    required this.auth,
    required this.repository,
    required this.location,
    required this.tipsApi,
    required this.storage,
    required this.notifications,
  });

  final AuthService auth;
  final DataRepository repository;
  final LocationService location;
  final TipsApiService tipsApi;
  final LocalStorageService storage;
  final NotificationService notifications;
}

/// Root widget: registers providers (Experiment 5b) and the MaterialApp with
/// theme (Experiment 6b) and named routes (Experiment 4b).
class SosApp extends StatelessWidget {
  const SosApp({
    super.key,
    required this.deps,
    this.initialRoute = AppRoutes.splash,
  });

  final AppDependencies deps;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalStorageService>.value(value: deps.storage),
        Provider<NotificationService>.value(value: deps.notifications),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider(deps.auth)),
        // The providers below follow the signed-in user: when AuthProvider
        // changes, `update` hands them the new uid (or null after sign-out).
        ChangeNotifierProxyProvider<AuthProvider, SettingsProvider>(
          create: (_) => SettingsProvider(
            repository: deps.repository,
            storage: deps.storage,
          ),
          update: (_, auth, previous) =>
              previous!..setUser(auth.user, fallbackName: auth.pendingDisplayName),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ContactsProvider>(
          create: (_) => ContactsProvider(deps.repository),
          update: (_, auth, previous) => previous!..setUser(auth.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, HistoryProvider>(
          create: (_) => HistoryProvider(deps.repository),
          update: (_, auth, previous) => previous!..setUser(auth.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SosProvider>(
          create: (_) => SosProvider(
            repository: deps.repository,
            locationService: deps.location,
          ),
          update: (_, auth, previous) => previous!..setUser(auth.uid),
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(deps.location),
        ),
        ChangeNotifierProvider<TipsProvider>(
          create: (_) => TipsProvider(api: deps.tipsApi, storage: deps.storage),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'SOS Safety System',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            initialRoute: initialRoute,
            onGenerateRoute: AppRouter.generate,
          );
        },
      ),
    );
  }
}