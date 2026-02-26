import '../entities/user_entity.dart';

/// Contrato del repositorio de autenticación.
abstract interface class AuthRepository {
  Future<UserEntity?> login(String email, String password);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<void> recuperarAcceso(String userName);
  Future<void> cambiarContrasenaDesdeRecuperacion({
    required String token,
    required String passwordNueva,
    required String passwordConfirmacion,
  });
}
