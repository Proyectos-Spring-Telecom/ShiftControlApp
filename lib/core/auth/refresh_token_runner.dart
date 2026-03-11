import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';
import 'token_storage_service.dart';

/// Ejecuta POST /api/auth/refresh usando [http] directo (no ApiClient)
/// para evitar ciclos cuando el cliente recibe 401 y dispara refresh.
class RefreshTokenRunner {
  RefreshTokenRunner(this._tokenStorage, this._baseUrl);

  final TokenStorageService _tokenStorage;
  final String _baseUrl;

  static String _normalizeBaseUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Obtiene refreshToken, llama POST /api/auth/refresh, guarda nuevos tokens y retorna el nuevo access token.
  /// Retorna null si no hay refreshToken o si la respuesta no es 200.
  /// Lanza [AuthException] si el servidor responde 401/403.
  Future<String?> run() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint('Refresh: no hay refresh token almacenado.');
      return null;
    }

    debugPrint('Intentando renovar token...');
    final base = _normalizeBaseUrl(_baseUrl);
    final uri = Uri.parse('$base/api/auth/refresh');
    final body = jsonEncode({'refreshToken': refreshToken});
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: body,
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      debugPrint('Refresh token expirado. Cerrando sesión.');
      throw AuthException(
        response.statusCode == 401 ? 'Sesión expirada.' : 'No autorizado.',
        '${response.statusCode}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('Refresh fallido: ${response.statusCode}');
      return null;
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (data == null) return null;
      final token = data['token'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (token == null || token.isEmpty) return null;

      await _tokenStorage.saveToken(token);
      await _tokenStorage.saveRefreshToken(newRefresh ?? refreshToken);
      debugPrint('Token renovado correctamente');
      return token;
    } catch (e) {
      debugPrint('Refresh parse error: $e');
      return null;
    }
  }
}
