import 'package:flutter/foundation.dart';

import '../../../core/auth/token_storage_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/change_password_request.dart';
import '../models/update_nip_request.dart';

// ! Servicio de actualización de contraseña y NIP.
// TODO: Implementar auditoría futura.
// ? Manejo centralizado de errores por código HTTP.

/// Servicio de perfil (cambio de contraseña, NIP, etc.).
/// Usa [ApiClient], que inyecta Authorization Bearer desde el almacenamiento.
class ProfileService {
  ProfileService(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorageService _tokenStorage;

  static const _pathCambiarAcceso = '/api/login/cambiar/accesso';
  static const _pathMiNip = '/api/login/mi-nip';

  /// Cambia la contraseña del usuario logueado (perfil).
  /// PATCH /api/login/cambiar/accesso con Bearer explícito.
  /// Retorna el body de la respuesta (status, message, data) para usar en la UI.
  Future<Map<String, dynamic>> changePassword(ChangePasswordRequest request) async {
    debugPrint('🔐 Iniciando cambio de contraseña...');

    final body = request.toJson();
    debugPrint('🔐 PATCH $_pathCambiarAcceso keys: ${body.keys.join(", ")}');

    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Sesión expirada. Inicia sesión de nuevo.', '401');
    }

    try {
      final response = await _client.patch(
        _pathCambiarAcceso,
        body: body,
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('✅ Contraseña actualizada correctamente (servidor respondió 2xx)');
      if (response['message'] is String) {
        debugPrint('✅ Mensaje backend: ${response['message']}');
      }
      return response;
    } on AuthException catch (e) {
      final String message;
      if (e.code == '400') {
        message = e.message;
        debugPrint('❌ Error 400: $message');
      } else if (e.code == '401') {
        message = 'Tu sesión ha expirado. Inicia sesión nuevamente.';
        debugPrint('❌ Error 401: No autorizado');
      } else if (e.code == '403') {
        message = e.message.isNotEmpty
            ? e.message
            : 'No tienes permisos para realizar esta acción.';
        debugPrint('❌ Error 403: Sin permisos');
      } else {
        message = e.message;
        debugPrint('❌ AuthException: ${e.message}');
      }
      throw AuthException(message, e.code);
    } on NetworkException catch (e) {
      if (e.code == '404') {
        debugPrint('❌ Error 404: ${e.message}');
        throw NetworkException(
          e.message.isNotEmpty ? e.message : 'Usuario no encontrado.',
          '404',
        );
      }
      if (e.code == '500') {
        debugPrint('❌ Error 500: servicio no disponible');
        throw NetworkException(
          e.message.isNotEmpty ? e.message : 'Error en el servidor. Intenta más tarde.',
          '500',
        );
      }
      debugPrint('❌ NetworkException: ${e.message}');
      rethrow;
    }
  }

  // ! Servicio actualización de NIP.
  // TODO: Implementar hash seguro antes de enviar si backend lo requiere.
  // ? Validaciones de seguridad.

  /// Crea o actualiza el NIP del usuario logueado.
  /// Path bajo `/api/login/` requiere Bearer explícito en headers.
  /// [request.pinHash] debe ser el valor de "Confirmar NIP" (6 u 8 dígitos).
  Future<Map<String, dynamic>> updateUserNip(UpdateNipRequest request) async {
    debugPrint('🔐 Iniciando actualización de NIP...');

    final body = request.toJson();
    debugPrint('🔐 PATCH $_pathMiNip keys: ${body.keys.join(", ")}');

    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Sesión expirada. Inicia sesión de nuevo.', '401');
    }

    try {
      final response = await _client.patch(
        _pathMiNip,
        body: body,
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('✅ NIP actualizado correctamente (servidor respondió 2xx)');
      if (response['message'] is String) {
        debugPrint('✅ Mensaje backend: ${response['message']}');
      }
      return response;
    } on AuthException catch (e) {
      final String message;
      if (e.code == '400') {
        message = e.message;
        debugPrint('❌ Error 400: $message');
      } else if (e.code == '401') {
        message = 'Tu sesión ha expirado. Inicia sesión nuevamente.';
        debugPrint('❌ Error 401: No autorizado');
      } else if (e.code == '403') {
        message = 'No tienes permisos para realizar esta acción.';
        debugPrint('❌ Error 403: Sin permisos');
      } else {
        message = e.message;
        debugPrint('❌ AuthException: ${e.message}');
      }
      throw AuthException(message, e.code);
    } on NetworkException catch (e) {
      if (e.code == '404') {
        debugPrint('❌ Error 404: Usuario no encontrado');
        throw NetworkException('Usuario no encontrado.', '404');
      }
      debugPrint('❌ NetworkException: ${e.message}');
      rethrow;
    }
  }
}
