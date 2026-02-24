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
      final user = await _remote.login(email, password);
      const token = 'mock-token';
      await _local.saveSession(UserModel.fromEntity(user), token);
      return user;
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
}
