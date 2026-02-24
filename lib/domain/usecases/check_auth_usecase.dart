import '../repositories/auth_repository.dart';

/// Caso de uso: verificar si hay sesión activa.
class CheckAuthUseCase {
  CheckAuthUseCase(this._repository);

  final AuthRepository _repository;

  Future<bool> call() => _repository.isLoggedIn();
}
