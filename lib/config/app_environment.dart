// Configuración global de ambientes (DEV, QA, PROD).
// Cambiar [current] en un solo lugar para que toda la app use el baseUrl correspondiente.

enum AppEnvironment {
  dev,
  qa,
  prod,
}

/// Variable global: cambiar aquí el ambiente para toda la aplicación.
/// No es necesario tocar URLs en servicios ni en el ApiClient.
const AppEnvironment current = AppEnvironment.dev;

abstract final class AppEnvironmentConfig {
  AppEnvironmentConfig._();

  /// Base URL según el ambiente actual.
  /// DEV y PROD: http://springtelecom.mx:3003 (login = .../api/login, sin segmento "dev").
  /// QA:  http://springtelecom.mx:3003/qa
  static String get baseUrl {
    const base = 'http://springtelecom.mx:3003';
    switch (current) {
      case AppEnvironment.dev:
      case AppEnvironment.prod:
        return base;
      case AppEnvironment.qa:
        return '$base/qa';
    }
  }
}
