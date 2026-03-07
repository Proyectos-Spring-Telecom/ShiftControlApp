import '../../core/errors/app_exception.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Implementación del repositorio de autenticación.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._local);

  final AuthRemoteDatasource _remote;
  final AuthLocalDatasource _local;

  @override
  Future<UserEntity?> login(String email, String password) async {
    try {
      final result = await _remote.login(email, password);
      await _local.saveSession(result.user, result.token);
      return result.user;
    } on AppException {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _local.clearSession();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _local.getStoredUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    return _local.hasSession();
  }

  @override
  Future<void> saveSession(UserEntity user, String token) async {
    final model = user is UserModel
        ? user
        : UserModel(
            id: user.id,
            email: user.email,
            name: user.name,
            roleName: user.roleName,
            apellidoPaterno: user.apellidoPaterno,
            apellidoMaterno: user.apellidoMaterno,
            telefono: user.telefono,
            userName: user.userName,
            fotoPerfil: user.fotoPerfil,
          );
    await _local.saveSession(model, token);
  }

  @override
  Future<void> recuperarAcceso(String userName) async {
    await _remote.recuperarAcceso(userName: userName);
  }

  @override
  Future<void> cambiarContrasenaDesdeRecuperacion({
    required String token,
    required String passwordNueva,
    required String passwordConfirmacion,
  }) async {
    await _remote.cambiarContrasenaDesdeRecuperacion(
      token: token,
      passwordNueva: passwordNueva,
      passwordConfirmacion: passwordConfirmacion,
    );
  }
}
