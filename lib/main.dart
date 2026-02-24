import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/app_router.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/theme_controller.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TurnosSpringApp(),
    ),
  );
}

class TurnosSpringApp extends ConsumerWidget {
  const TurnosSpringApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final themePreference = ref.watch(themeModePreferenceProvider);

    return MaterialApp(
      title: 'Turnos Spring',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themePreference.mode,
      onGenerateRoute: AppRouter.onGenerateRouteStatic,
      home: _InitialScreen(status: authState.status),
    );
  }
}

class _InitialScreen extends ConsumerWidget {
  const _InitialScreen({required this.status});

  final AuthStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (status == AuthStatus.loading || status == AuthStatus.initial) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (status == AuthStatus.authenticated) {
      return AppRouter.homeWidget;
    }
    return AppRouter.loginWidget;
  }
}
