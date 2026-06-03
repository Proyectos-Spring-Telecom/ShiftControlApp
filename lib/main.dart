import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/route_constants.dart';
import 'core/utils/initial_route_stub.dart'
    if (dart.library.html) 'core/utils/initial_route_web.dart' as initial_route;
import 'presentation/app_router.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/theme_controller.dart';
import 'core/theme/app_theme.dart';

/// Ruta inicial desde el hash (#/nueva-contrasena?token=...).
/// En web: Uri.base.fragment puede venir vacío en release; se usa window.location.hash.
String? _resolveInitialRoute() {
  if (!kIsWeb) return null;

  debugPrint('[main] _resolveInitialRoute: web, Uri.base.fragment="${Uri.base.fragment}"');

  // Primero intentar Uri.base (puede funcionar en debug).
  final fragment = Uri.base.fragment;
  if (fragment.isNotEmpty) {
    final path = Uri.parse(fragment).path;
    debugPrint('[main] _resolveInitialRoute: path desde fragment="$path"');
    if (path == RouteConstants.nuevaContrasena) {
      debugPrint('[main] _resolveInitialRoute: → nuevaContrasena (desde Uri.base)');
      return RouteConstants.nuevaContrasena;
    }
  }

  // En release el fragment suele venir vacío; leer desde el navegador (solo web).
  final fromHash = initial_route.getInitialRouteFromHash();
  debugPrint('[main] _resolveInitialRoute: getInitialRouteFromHash() → $fromHash');
  return fromHash;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final initialRoute = _resolveInitialRoute();
  debugPrint('[main] initialRoute usada en runApp: $initialRoute');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: TurnosSpringApp(initialRoute: initialRoute),
    ),
  );
}

class TurnosSpringApp extends ConsumerWidget {
  const TurnosSpringApp({
    super.key,
    this.initialRoute,
  });

  final String? initialRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(sessionExpiredTriggerProvider, (prev, next) {
      if (next != null && next > 0) {
        ref.read(authControllerProvider.notifier).logout();
      }
    });

    final authState = ref.watch(authControllerProvider);
    final themePreference = ref.watch(themeModePreferenceProvider);

    final useHome = initialRoute == null;
    debugPrint('[main] TurnosSpringApp.build: initialRoute=$initialRoute → ${useHome ? "_InitialScreen (login/home)" : "initialRoute (nueva-contrasena)"}');

    return MaterialApp(
      title: 'Turnos Spring',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themePreference.mode,
      onGenerateRoute: AppRouter.onGenerateRouteStatic,
      initialRoute: initialRoute,
      home: useHome
          ? _InitialScreen(status: authState.status)
          : null,
    );
  }
}

class _InitialScreen extends ConsumerWidget {
  const _InitialScreen({required this.status});

  final AuthStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (status == AuthStatus.loading || status == AuthStatus.initial) {
      debugPrint('[main] _InitialScreen → loading');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (status == AuthStatus.authenticated) {
      debugPrint('[main] _InitialScreen → home');
      return AppRouter.homeWidget;
    }
    debugPrint('[main] _InitialScreen → login');
    return AppRouter.loginWidget;
  }
}
