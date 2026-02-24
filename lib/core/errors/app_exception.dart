/// Excepción base de la aplicación.
sealed class AppException implements Exception {
  const AppException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Error de autenticación.
final class AuthException extends AppException {
  const AuthException(super.message, [super.code]);
}

/// Error de red o API.
final class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

/// Error de almacenamiento local.
final class StorageException extends AppException {
  const StorageException(super.message, [super.code]);
}
