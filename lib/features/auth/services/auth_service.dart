import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';
import '../../../data/models/login_response_model.dart';
import '../../../data/models/user_model.dart';
import '../models/login_nip_request.dart';

// ! Login mediante NIP.
// TODO: Implementar biometría futura.
// ? Reutiliza LoginResponse existente (LoginResponseModel).

/// Servicio de autenticación (login por NIP, etc.).
/// No envía Authorization en login (ApiClient omite en paths con "login").
class AuthService {
  AuthService(this._client, this._local);

  final ApiClient _client;
  final AuthLocalDatasource _local;

  static const _pathLoginNip = '/api/login/operador/accesso/nip';

  /// Login con NIP. [userName] = correo (prellenado desde almacenamiento, editable en UI).
  /// Guarda token y usuario en almacenamiento. Retorna el usuario para mostrar rol en banner.
  Future<UserModel> loginWithNip(String userName, String codigo) async {
    debugPrint('🔐 Iniciando login con NIP...');
    debugPrint('📧 Usuario obtenido del almacenamiento: $userName');

    if (userName.trim().isEmpty) {
      throw const AuthException(
        'No hay credenciales guardadas. Inicia sesión con correo y contraseña primero.',
      );
    }

    final body = LoginNipRequest(userName: userName.trim(), codigo: codigo.trim()).toJson();

    try {
      final data = await _client.post(_pathLoginNip, body: body);
      final response = LoginResponseModel.fromJson(data);

      if (response.token.isEmpty) {
        debugPrint('! AuthService NIP: respuesta sin token');
        throw const AuthException('No se recibió sesión. Intenta de nuevo.');
      }

      final name = response.nombre ?? response.userName ?? userName.split('@').first;
      final userId = response.id ?? 'user-${DateTime.now().millisecondsSinceEpoch}';
      final userEmail = response.email ?? response.userName ?? userName;

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

      await _local.saveSession(user, response.token, refreshToken: response.refreshToken);
      debugPrint('✅ Login con NIP exitoso');
      return user;
    } on AuthException catch (e) {
      if (e.code == '400') {
        debugPrint('❌ Error en login NIP: 400');
        throw AuthException('NIP incorrecto. Intenta nuevamente.', '400');
      }
      if (e.code == '401') {
        debugPrint('❌ Error en login NIP: 401');
        throw AuthException('No autorizado. Verifica tu NIP.', '401');
      }
      debugPrint('❌ Error en login NIP: ${e.code} ${e.message}');
      rethrow;
    } on NetworkException catch (e) {
      if (e.code == '404') {
        debugPrint('❌ Error en login NIP: 404');
        throw NetworkException('Usuario no encontrado.', '404');
      }
      debugPrint('❌ Error en login NIP (red): ${e.message}');
      rethrow;
    }
  }

  /// Último correo con login exitoso (para prellenar campo en login por NIP).
  Future<String?> getLastLoginEmail() async {
    return _local.getLastLoginEmail();
  }
}
