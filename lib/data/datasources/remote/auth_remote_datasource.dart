import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../models/login_request_model.dart';
import '../../models/login_response_model.dart';
import '../../models/user_model.dart';

/// Resultado del login: usuario y token para persistir.
class LoginResult {
  const LoginResult({required this.user, required this.token});

  final UserModel user;
  final String token;
}

/// Fuente de datos remota para autenticación.
abstract interface class AuthRemoteDatasource {
  Future<LoginResult> login(String email, String password);
  Future<void> recuperarAcceso({required String userName});
  Future<void> cambiarContrasenaDesdeRecuperacion({
    required String token,
    required String passwordNueva,
    required String passwordConfirmacion,
  });
}

/// Implementación mock para desarrollo sin API.
class AuthRemoteDatasourceMock implements AuthRemoteDatasource {
  @override
  Future<LoginResult> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (email.isEmpty || password.isEmpty) {
      throw const AuthException('Email y contraseña son obligatorios');
    }
    final user = UserModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: email.split('@').first,
    );
    return LoginResult(user: user, token: 'mock-token');
  }

  @override
  Future<void> recuperarAcceso({required String userName}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (userName.isEmpty) {
      throw const AuthException('El correo es obligatorio');
    }
  }

  @override
  Future<void> cambiarContrasenaDesdeRecuperacion({
    required String token,
    required String passwordNueva,
    required String passwordConfirmacion,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (token.isEmpty) throw const AuthException('Token requerido');
    if (passwordNueva != passwordConfirmacion) {
      throw const AuthException('Las contraseñas no coinciden');
    }
  }
}

/// Implementación real: POST /api/login con [ApiClient].
/// ! No envía Authorization header (ApiClient lo omite en path login).
class AuthRemoteDatasourceReal implements AuthRemoteDatasource {
  AuthRemoteDatasourceReal(this._client);

  final ApiClient _client;

  @override
  Future<LoginResult> login(String email, String password) async {
    final body = LoginRequestModel(userName: email, password: password).toJson();
    try {
      final data = await _client.post('/api/login', body: body);
      final response = LoginResponseModel.fromJson(data);
      if (response.token.isEmpty) {
        debugPrint('! AuthRemoteDatasourceReal: respuesta sin token');
        throw const AuthException('No se recibió sesión. Intenta de nuevo.');
      }

      final name = response.nombre ?? response.userName ?? email.split('@').first;
      final userId = response.id ?? 'user-${DateTime.now().millisecondsSinceEpoch}';
      final userEmail = response.email ?? response.userName ?? email;

      final user = UserModel(
        id: userId,
        email: userEmail,
        name: name,
        roleName: response.rol?.nombre,
        apellidoPaterno: response.apellidoPaterno,
        apellidoMaterno: response.apellidoMaterno,
        telefono: response.telefono,
        userName: response.userName,
        fotoPerfil: response.fotoPerfil,
      );

      debugPrint('AuthRemoteDatasourceReal: login exitoso para ${user.email}');
      return LoginResult(user: user, token: response.token);
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('! AuthRemoteDatasourceReal NetworkException: ${e.message}');
      throw AuthException(e.message, e.code);
    }
  }

  static const _pathRecuperarAcceso = '/api/login/usuario/solicitud/recuperacion';

  @override
  Future<void> recuperarAcceso({required String userName}) async {
    debugPrint('AuthRemoteDatasourceReal: recuperarAcceso request userName=$userName');
    try {
      final body = <String, dynamic>{'userName': userName};
      final response = await _client.post(_pathRecuperarAcceso, body: body);
      debugPrint('AuthRemoteDatasourceReal: recuperarAcceso response ok, body=$response');
    } on AuthException catch (e) {
      debugPrint('! AuthRemoteDatasourceReal recuperarAcceso AuthException: ${e.message}');
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('! AuthRemoteDatasourceReal recuperarAcceso NetworkException: ${e.message}');
      throw AuthException(
        e.message,
        e.code,
      );
    } catch (e, st) {
      debugPrint('! AuthRemoteDatasourceReal recuperarAcceso error: $e\n$st');
      rethrow;
    }
  }

  static const _pathCambiarAcceso = '/api/login/cambiar/accesso';

  @override
  Future<void> cambiarContrasenaDesdeRecuperacion({
    required String token,
    required String passwordNueva,
    required String passwordConfirmacion,
  }) async {
    final tokenPreview = token.length > 12 ? '${token.substring(0, 8)}...' : '***';
    debugPrint('AuthRemoteDatasourceReal: cambiarContrasenaDesdeRecuperacion request token=$tokenPreview');
    try {
      final body = <String, dynamic>{
        'passwordNueva': passwordNueva,
        'passwordConfirmacion': passwordConfirmacion,
      };
      final headers = <String, String>{'Authorization': 'Bearer $token'};
      final response = await _client.post(
        _pathCambiarAcceso,
        body: body,
        headers: headers,
      );
      debugPrint('AuthRemoteDatasourceReal: cambiarContrasenaDesdeRecuperacion response ok, body=$response');
    } on AuthException catch (e) {
      debugPrint('! AuthRemoteDatasourceReal cambiarContrasenaDesdeRecuperacion AuthException: ${e.message} (code=${e.code})');
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('! AuthRemoteDatasourceReal cambiarContrasenaDesdeRecuperacion NetworkException: ${e.message} (code=${e.code})');
      throw AuthException(e.message, e.code);
    } catch (e, st) {
      debugPrint('! AuthRemoteDatasourceReal cambiarContrasenaDesdeRecuperacion error: $e\n$st');
      rethrow;
    }
  }
}
