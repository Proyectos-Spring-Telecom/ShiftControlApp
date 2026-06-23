/// Constantes globales de la aplicación.
abstract final class AppConstants {
  AppConstants._();

  static const String appName = 'Turnos Spring';

  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  /// Segundos hasta expiración del access token (POST /api/login expiresIn).
  static const String keyTokenExpiresIn = 'token_expires_in';
  /// Timestamp Unix (segundos) en que expira el access token.
  static const String keyTokenExpiresAt = 'token_expires_at';
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

  static const String keyChecklistIdTurno = 'checklist_id_turno';
  static const String keyChecklistIdBitacoraApertura = 'checklist_id_bitacora_apertura';
  static const String keyChecklistPasoActual = 'checklist_paso_actual';
  static const String keyChecklistCompleto = 'checklist_completo';
  static const String keyChecklistPlaca = 'checklist_placa';
  static const String keyChecklistNumeroEconomico = 'checklist_numero_economico';
  static const String keyChecklistModeloNombre = 'checklist_modelo_nombre';
  static const String keyChecklistMarcaNombre = 'checklist_marca_nombre';
  static const String keyChecklistAnio = 'checklist_anio';
  static const String keyChecklistIdBitacoraCierre = 'checklist_id_bitacora_cierre';
  static const String keyChecklistDuracionCierre = 'checklist_duracion_cierre';
  static const String keyChecklistEsCierre = 'checklist_es_cierre';

  /// Ancho del área leading cuando no hay botón de regreso (equivale al IconButton back).
  static const double appBarLeadingWidthWithoutBack = 56;
}
