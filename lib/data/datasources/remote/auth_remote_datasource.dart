import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/models/login_nip_request.dart';
import '../../models/login_me_response.dart';
import '../../models/login_request_model.dart';
import '../../models/login_tokens_response.dart';
import '../../models/user_model.dart';

/// Resultado del login: usuario y token para persistir.
class LoginResult {
  const LoginResult({
    required this.user,
    required this.token,
    this.refreshToken,
    this.expiresIn,
  });

  final UserModel user;
  final String token;
  final String? refreshToken;
  final int? expiresIn;
}

/// Resultado de POST /api/login/refresh.
class RefreshResult {
  const RefreshResult({
    required this.token,
    required this.refreshToken,
    this.expiresIn,
  });

  final String token;
  final String refreshToken;
  final int? expiresIn;
}

/// Fuente de datos remota para autenticación.
abstract interface class AuthRemoteDatasource {
  Future<LoginResult> login(String email, String password);
  Future<LoginResult> loginWithNip(String userName, String codigo);
  Future<RefreshResult> refreshToken(String refreshToken);
  Future<void> recuperarAcceso({required String userName});
  Future<void> cambiarContrasenaDesdeRecuperacion({
    required String token,
    required String passwordNueva,
    required String passwordConfirmacion,
  });
  Future<void> remoteLogout(String token);
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
  Future<LoginResult> loginWithNip(String userName, String codigo) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (userName.isEmpty || codigo.isEmpty) {
      throw const AuthException('Usuario y NIP son obligatorios');
    }
    final user = UserModel(
      id: 'mock-nip-${DateTime.now().millisecondsSinceEpoch}',
      email: userName,
      name: userName.split('@').first,
    );
    return LoginResult(user: user, token: 'mock-token');
  }

  @override
  Future<RefreshResult> refreshToken(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return RefreshResult(token: 'mock-token-new', refreshToken: 'mock-refresh-new');
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

  @override
  Future<void> remoteLogout(String token) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

/// Implementación real: POST /api/login con [ApiClient].
/// ! No envía Authorization header (ApiClient lo omite en path login).
class AuthRemoteDatasourceReal implements AuthRemoteDatasource {
  AuthRemoteDatasourceReal(this._client);

  final ApiClient _client;

  static const _pathLogin = '/api/login';
  static const _pathLoginNip = '/api/login/operador/accesso/nip';
  static const _pathLoginMe = '/api/login/me';

  Future<LoginResult> _loginResultFromTokens(
    LoginTokensResponse tokens, {
    required String fallbackEmail,
    required String logLabel,
  }) async {
    if (tokens.token.isEmpty) {
      debugPrint('! AuthRemoteDatasourceReal: respuesta sin token ($logLabel)');
      throw const AuthException('No se recibió sesión. Intenta de nuevo.');
    }

    final meData = await _client.get(
      _pathLoginMe,
      headers: {'Authorization': 'Bearer ${tokens.token}'},
    );
    debugPrint('Login me response ($logLabel): $meData');
    final me = LoginMeResponse.fromJson(meData);
    final user = me.toUserModel(fallbackEmail: fallbackEmail);

    debugPrint('AuthRemoteDatasourceReal: $logLabel exitoso para ${user.email}');
    return LoginResult(
      user: user,
      token: tokens.token,
      refreshToken: tokens.refreshToken,
      expiresIn: tokens.expiresIn,
    );
  }

  @override
  Future<LoginResult> login(String email, String password) async {
    final body = LoginRequestModel(userName: email, password: password).toJson();
    try {
      final loginData = await _client.post(_pathLogin, body: body);
      debugPrint('Login tokens response: $loginData');
      final tokens = LoginTokensResponse.fromJson(loginData);
      return _loginResultFromTokens(tokens, fallbackEmail: email, logLabel: 'login');
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('! AuthRemoteDatasourceReal NetworkException: ${e.message}');
      throw AuthException(e.message, e.code);
    }
  }

  @override
  Future<LoginResult> loginWithNip(String userName, String codigo) async {
    final body = LoginNipRequest(userName: userName.trim(), codigo: codigo.trim()).toJson();
    try {
      final loginData = await _client.post(_pathLoginNip, body: body);
      debugPrint('Login NIP tokens response: $loginData');
      final tokens = LoginTokensResponse.fromJson(loginData);
      return _loginResultFromTokens(
        tokens,
        fallbackEmail: userName.trim(),
        logLabel: 'login NIP',
      );
    } on AuthException {
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('! AuthRemoteDatasourceReal login NIP NetworkException: ${e.message}');
      throw AuthException(e.message, e.code);
    }
  }

  static const _pathRefresh = '/api/login/refresh';
  static const _pathRecuperarAcceso = '/api/login/usuario/solicitud/recuperacion';

  @override
  Future<RefreshResult> refreshToken(String refreshToken) async {
    debugPrint('Intentando renovar token...');
    try {
      final body = <String, dynamic>{'refreshToken': refreshToken};
      final raw = await _client.post(_pathRefresh, body: body);
      final data = raw['data'] is Map<String, dynamic>
          ? raw['data'] as Map<String, dynamic>
          : raw;
      final token = (data['token'] as String?) ?? (data['accessToken'] as String?);
      final newRefreshToken = data['refreshToken'] as String?;
      final expiresIn = (data['expiresIn'] as num?)?.toInt();
      if (token == null || token.isEmpty) {
        throw const AuthException('No se recibió token en refresh.', '400');
      }
      debugPrint('Token renovado correctamente');
      return RefreshResult(
        token: token,
        refreshToken: newRefreshToken ?? refreshToken,
        expiresIn: expiresIn,
      );
    } on AuthException catch (e) {
      debugPrint('Refresh token fallido: ${e.code} ${e.message}');
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('Refresh token fallido (red): ${e.message}');
      throw AuthException(e.message, e.code);
    }
  }

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

  @override
  Future<void> remoteLogout(String token) async {
    debugPrint('Cerrando sesión en servidor...');
    try {
      await _client.post(
        '/api/login/logout',
        body: <String, dynamic>{},
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('Logout en servidor exitoso');
    } on AuthException catch (e) {
      debugPrint('Logout servidor AuthException: ${e.code} - ignorando');
    } on NetworkException catch (e) {
      debugPrint('Logout servidor NetworkException: ${e.message} - ignorando');
    } catch (e) {
      debugPrint('Logout servidor error inesperado: $e - ignorando');
    }
  }
}
