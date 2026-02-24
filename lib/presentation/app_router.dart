import 'package:flutter/material.dart';

import 'auth/login/login_page.dart';
import 'home/main_shell.dart';
import '../core/constants/route_constants.dart';

/// Rutas centralizadas de la aplicación.
abstract final class AppRouter {
  static const loginWidget = LoginPage();
  static const homeWidget = MainShell();

  static Route<dynamic>? onGenerateRouteStatic(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => loginWidget,
        );
      case RouteConstants.home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => homeWidget,
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => loginWidget,
        );
    }
  }
}
