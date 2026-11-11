import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers.dart';
import 'editor.dart';
import 'app_theme.dart';
import 'home_screen.dart';
import 'session_screen.dart';
import 'history_screen.dart';
import 'territory_screen.dart';
import 'settings_screen.dart';

class CorreAlongaApp extends ConsumerStatefulWidget {
  const CorreAlongaApp({super.key});
  @override
  ConsumerState<CorreAlongaApp> createState() => _AppState();
}

class _AppState extends ConsumerState<CorreAlongaApp>
    with WidgetsBindingObserver {
  late final GoRouter router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/workout/new', builder: (_, _) => const WorkoutEditor()),
      GoRoute(
        path: '/workout/:id',
        builder: (_, s) => WorkoutEditor(id: s.pathParameters['id']),
      ),
      GoRoute(path: '/session', builder: (_, _) => const SessionScreen()),
      GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
      GoRoute(path: '/territory', builder: (_, _) => const TerritoryScreen()),
      GoRoute(
        path: '/activity/:id',
        builder: (_, s) => ActivityScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(trainingProvider);
    if (state == AppLifecycleState.resumed) {
      controller.onForeground();
    } else {
      controller.onBackground();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(trainingProvider);
    return MaterialApp.router(
      title: 'AlongaPET',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: switch (controller.preferences.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      themeAnimationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      routerConfig: router,
    );
  }
}
