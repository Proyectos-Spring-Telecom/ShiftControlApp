import '../entities/user_entity.dart';

/// Contrato del repositorio de autenticación.
abstract interface class AuthRepository {
  Future<UserEntity?> login(String email, String password);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<bool> isLoggedIn();
  /// Guarda sesión (p. ej. tras login por Face Auth) sin llamar al API remoto principal.
  Future<void> saveSession(UserEntity user, String token);
  Future<void> recuperarAcceso(String userName);
  Future<void> cambiarContrasenaDesdeRecuperacion({
    required String token,
    required String passwordNueva,
    required String passwordConfirmacion,
  });
}
