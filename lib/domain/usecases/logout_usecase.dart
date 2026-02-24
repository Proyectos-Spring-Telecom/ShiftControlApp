import '../repositories/auth_repository.dart';

/// Caso de uso: cerrar sesión.
class LogoutUseCase {
  LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
