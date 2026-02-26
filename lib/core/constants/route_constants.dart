/// Nombres de rutas centralizadas.
abstract final class RouteConstants {
  RouteConstants._();

  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  /// Ruta pública para restaurar contraseña. Espera query: ?token=...
  /// Ejemplo: #/nueva-contrasena?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  static const String nuevaContrasena = '/nueva-contrasena';

  /// Construye la ruta de nueva contraseña con el token (para enlaces o navegación).
  /// Ejemplo: nuevaContrasenaWithToken(token) → '/nueva-contrasena?token=...'
  static String nuevaContrasenaWithToken(String token) {
    final encoded = Uri.encodeComponent(token);
    return '$nuevaContrasena?token=$encoded';
  }
}
