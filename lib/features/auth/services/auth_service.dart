import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';
import '../../../data/datasources/remote/auth_remote_datasource.dart';
import '../../../data/models/user_model.dart';

// ! Login mediante NIP.
// TODO: Implementar biometría futura.
// ? Delega HTTP a AuthRemoteDatasource (mismo patrón que login credenciales).

/// Servicio de autenticación (login por NIP, etc.).
class AuthService {
  AuthService(this._remote, this._local);

  final AuthRemoteDatasource _remote;
  final AuthLocalDatasource _local;

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

    try {
      final result = await _remote.loginWithNip(userName, codigo);
      await _local.saveSession(
        result.user,
        result.token,
        refreshToken: result.refreshToken,
        expiresIn: result.expiresIn,
      );
      debugPrint('✅ Login con NIP exitoso');
      return result.user;
    } on AuthException catch (e) {
      debugPrint('❌ Error en login NIP: ${e.code} ${e.message}');
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('❌ Error en login NIP (red): ${e.message}');
      rethrow;
    }
  }

  /// Último correo con login exitoso (para prellenar campo en login por NIP).
  Future<String?> getLastLoginEmail() async {
    return _local.getLastLoginEmail();
  }
}
