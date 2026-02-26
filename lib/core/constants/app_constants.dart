/// Constantes globales de la aplicación.
abstract final class AppConstants {
  AppConstants._();

  static const String appName = 'Turnos Spring';

  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyUserRoleName = 'user_role_name';
  static const String keyUserApellidoPaterno = 'user_apellido_paterno';
  static const String keyUserApellidoMaterno = 'user_apellido_materno';
  static const String keyUserTelefono = 'user_telefono';
  static const String keyUserUserName = 'user_user_name';
  static const String keyUserFotoPerfil = 'user_foto_perfil';
  static const String keyIsLoggedIn = 'is_logged_in';
  /// Último correo con login exitoso (para prellenar login por NIP). No se borra al cerrar sesión.
  static const String keyLastLoginEmail = 'last_login_email';

  static const String keyThemeMode = 'theme_mode';
}
