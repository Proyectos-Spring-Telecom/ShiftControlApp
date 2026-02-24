import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: obtener usuario actual.
class GetCurrentUserUseCase {
  GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity?> call() => _repository.getCurrentUser();
}
