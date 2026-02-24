import '../../../../core/errors/app_exception.dart';
import '../../models/user_model.dart';

/// Fuente de datos remota para autenticación.
/// Implementar con ApiClient cuando exista backend.
abstract interface class AuthRemoteDatasource {
  Future<UserModel> login(String email, String password);
}

/// Implementación mock para desarrollo sin API.
class AuthRemoteDatasourceMock implements AuthRemoteDatasource {
  @override
  Future<UserModel> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (email.isEmpty || password.isEmpty) {
      throw const AuthException('Email y contraseña son obligatorios');
    }
    return UserModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: email.split('@').first,
    );
  }
}
