import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/log/presentation/log_screen.dart';
import '../features/profile/presentation/import_profile_screen.dart';
import '../features/profile/presentation/profile_detail_screen.dart';
import '../features/profile/presentation/profile_list_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/status/presentation/status_screen.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'profiles',
          builder: (context, state) => const ProfileListScreen(),
        ),
        GoRoute(
          path: 'profile/:id',
          builder: (context, state) =>
              ProfileDetailScreen(profileId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: 'import',
          builder: (context, state) => const ImportProfileScreen(),
        ),
        GoRoute(
          path: 'status',
          builder: (context, state) => const StatusScreen(),
        ),
        GoRoute(
          path: 'log',
          builder: (context, state) => const LogScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
