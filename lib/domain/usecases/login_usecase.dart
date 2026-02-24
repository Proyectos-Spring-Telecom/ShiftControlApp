import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: iniciar sesión.
class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity?> call(String email, String password) {
    return _repository.login(email, password);
  }
}
