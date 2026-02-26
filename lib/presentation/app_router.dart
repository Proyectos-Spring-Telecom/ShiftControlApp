import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'auth/login/login_page.dart';
import 'auth/login/nueva_contrasena_page.dart';
import 'home/main_shell.dart';
import '../core/constants/route_constants.dart';

/// Rutas centralizadas de la aplicación.
abstract final class AppRouter {
  static const loginWidget = LoginPage();
  static const homeWidget = MainShell();

  static Route<dynamic>? onGenerateRouteStatic(RouteSettings settings) {
    debugPrint('[AppRouter] onGenerateRoute: name="${settings.name}"');

    final name = settings.name ?? '';
    final path = name.contains('?')
        ? Uri.parse(name).path
        : name;
    final queryToken = name.contains('?')
        ? Uri.parse(name).queryParameters['token']
        : null;

    switch (path) {
      case RouteConstants.login:
        debugPrint('[AppRouter] → LoginPage');
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => loginWidget,
        );
      case RouteConstants.home:
        debugPrint('[AppRouter] → MainShell (home)');
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => homeWidget,
        );
      case RouteConstants.nuevaContrasena:
        debugPrint('[AppRouter] → NuevaContrasenaPage (token: ${queryToken != null ? "ok" : "null"})');
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => NuevaContrasenaPage(token: queryToken),
        );
      default:
        debugPrint('[AppRouter] → default: LoginPage (name no coincide)');
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => loginWidget,
        );
    }
  }
}
