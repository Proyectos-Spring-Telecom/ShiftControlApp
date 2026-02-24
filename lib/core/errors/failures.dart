import 'app_exception.dart';

/// Representación de un fallo en la capa de dominio.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

/// Fallo de autenticación.
final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Fallo de servidor/red.
final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Fallo de caché/almacenamiento.
final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Convierte [AppException] a [Failure].
Failure failureFromException(AppException e) {
  return switch (e) {
    AuthException() => AuthFailure(e.message),
    NetworkException() => ServerFailure(e.message),
    StorageException() => CacheFailure(e.message),
  };
}
