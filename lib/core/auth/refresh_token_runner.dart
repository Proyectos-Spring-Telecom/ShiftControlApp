import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';
import 'token_storage_service.dart';

/// Ejecuta POST /api/login/refresh usando [http] directo (no ApiClient)
/// para evitar ciclos cuando el cliente recibe 401 y dispara refresh.
class RefreshTokenRunner {
  RefreshTokenRunner(this._tokenStorage, this._baseUrl);

  final TokenStorageService _tokenStorage;
  final String _baseUrl;

  static const _pathRefresh = '/api/login/refresh';

  static String _normalizeBaseUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static Map<String, dynamic>? _unwrapPayload(Map<String, dynamic>? json) {
    if (json == null) return null;
    if (json['data'] is Map<String, dynamic>) {
      return json['data'] as Map<String, dynamic>;
    }
    return json;
  }

  /// Obtiene refreshToken, llama POST /api/login/refresh, guarda nuevos tokens y retorna el nuevo access token.
  /// Retorna null si no hay refreshToken o si la respuesta no es exitosa (salvo 401/403).
  /// Lanza [AuthException] si el servidor responde 401/403 (sesión expirada).
  Future<String?> run() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint('Refresh: no hay refresh token almacenado.');
      return null;
    }

    debugPrint('Intentando renovar token...');
    final base = _normalizeBaseUrl(_baseUrl);
    final uri = Uri.parse('$base$_pathRefresh');
    final body = jsonEncode({'refreshToken': refreshToken});
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: body,
    );

    switch (response.statusCode) {
      case 401:
      case 403:
        debugPrint('Refresh token expirado o inválido. Cerrando sesión.');
        throw AuthException(
          response.statusCode == 401 ? 'Sesión expirada.' : 'No autorizado.',
          '${response.statusCode}',
        );
      case 400:
        debugPrint('Refresh fallido: refresh token inválido o request incorrecto.');
        throw const AuthException('Refresh token inválido.', '400');
      case 429:
        debugPrint('Refresh fallido: demasiados intentos.');
        return null;
      case 500:
      case 503:
        debugPrint('Refresh fallido: servicio no disponible (${response.statusCode}).');
        return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('Refresh fallido: ${response.statusCode}');
      return null;
    }

    try {
      final raw = jsonDecode(response.body) as Map<String, dynamic>?;
      final data = _unwrapPayload(raw);
      if (data == null) return null;
      final token = (data['token'] as String?) ?? (data['accessToken'] as String?);
      final newRefresh = data['refreshToken'] as String?;
      if (token == null || token.isEmpty) return null;

      await _tokenStorage.saveToken(token);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _tokenStorage.saveRefreshToken(newRefresh);
      } else {
        await _tokenStorage.saveRefreshToken(refreshToken);
      }
      final expiresIn = (data['expiresIn'] as num?)?.toInt();
      await _tokenStorage.saveTokenExpiry(expiresInSeconds: expiresIn);
      debugPrint('Token renovado correctamente');
      return token;
    } catch (e) {
      debugPrint('Refresh parse error: $e');
      return null;
    }
  }
}
