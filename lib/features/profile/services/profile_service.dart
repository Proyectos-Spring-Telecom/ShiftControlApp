import 'package:flutter/foundation.dart';

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
  ProfileService(this._client);

  final ApiClient _client;

  static const _pathActualizarContrasena = '/api/usuarios/actualizar/contrasena';
  static const _pathMiNip = '/api/usuarios/mi-nip';

  /// Cambia la contraseña del usuario logueado.
  /// Token se envía automáticamente por [ApiClient] (ID del usuario desde JWT).
  /// Retorna el body de la respuesta (status, message, data) para usar en la UI.
  /// Lanza [AuthException] o [NetworkException] con mensaje amigable según 400/401/404.
  Future<Map<String, dynamic>> changePassword(ChangePasswordRequest request) async {
    debugPrint('🔐 Iniciando cambio de contraseña...');

    final body = request.toJson();
    debugPrint('🔐 PATCH $_pathActualizarContrasena keys: ${body.keys.join(", ")}');

    try {
      final response = await _client.patch(
        _pathActualizarContrasena,
        body: body,
      );
      debugPrint('✅ Contraseña actualizada correctamente (servidor respondió 2xx)');
      if (response['message'] is String) {
        debugPrint('✅ Mensaje backend: ${response['message']}');
      }
      return response;
    } on AuthException catch (e) {
      final String message;
      if (e.code == '400') {
        message = 'La contraseña actual es incorrecta o no cumple con los requisitos.';
        debugPrint('❌ Error 400: Contraseña inválida');
      } else if (e.code == '401') {
        message = 'Tu sesión ha expirado. Inicia sesión nuevamente.';
        debugPrint('❌ Error 401: No autorizado');
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

  // ! Servicio actualización de NIP.
  // TODO: Implementar hash seguro antes de enviar si backend lo requiere.
  // ? Validaciones de seguridad.

  /// Crea o actualiza el NIP del usuario logueado.
  /// Token se envía automáticamente por [ApiClient].
  /// [request.pinHash] debe ser el valor de "Confirmar NIP" (6 u 8 dígitos).
  Future<void> updateUserNip(UpdateNipRequest request) async {
    debugPrint('🔐 Iniciando actualización de NIP...');

    final body = request.toJson();
    debugPrint('🔐 PATCH $_pathMiNip');

    try {
      await _client.patch(
        _pathMiNip,
        body: body,
      );
      debugPrint('✅ NIP actualizado correctamente');
    } on AuthException catch (e) {
      final String message;
      if (e.code == '400') {
        message = 'El NIP no es válido. Verifica que cumpla con los requisitos.';
        debugPrint('❌ Error 400: NIP inválido');
      } else if (e.code == '401') {
        message = 'Tu sesión ha expirado. Inicia sesión nuevamente.';
        debugPrint('❌ Error 401: No autorizado');
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
