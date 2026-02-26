import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_environment.dart';
import '../errors/app_exception.dart';
import 'api_client.dart';

/// Implementación del [ApiClient] usando package [http].
/// Usa [AppEnvironmentConfig.baseUrl], headers globales y Bearer dinámico.
/// TODO: Añadir interceptor para refresh token.
/// ? Errores HTTP se mapean a [NetworkException] o [AuthException].
class HttpApiClient implements ApiClient {
  HttpApiClient({
    required this.getToken,
    String? baseUrl,
  }) : _baseUrl = baseUrl ?? AppEnvironmentConfig.baseUrl;

  /// Callback para obtener el token (sin Authorization en login).
  final Future<String?> Function() getToken;

  final String _baseUrl;

  static const _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$p');
  }

  Future<Map<String, String>> _headers({Map<String, String>? extra, bool useAuth = true}) async {
    final map = Map<String, String>.of(_defaultHeaders);
    if (extra != null) map.addAll(extra);
    if (useAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        map['Authorization'] = 'Bearer $token';
      }
    }
    return map;
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = response.body;
    String message;
    switch (response.statusCode) {
      case 400:
        message = _parseMessage(body) ?? 'Datos incorrectos. Revisa tu correo y contraseña.';
        debugPrint('! ApiClient 400: $message');
        throw AuthException(message, '400');
      case 401:
        message = _parseMessage(body) ?? 'Sesión expirada o credenciales inválidas. Vuelve a iniciar sesión.';
        debugPrint('! ApiClient 401: $message');
        throw AuthException(message, '401');
      case 404:
        message = _parseMessage(body) ?? 'No encontrado.';
        throw NetworkException(message, '404');
      case 500:
        message = _parseMessage(body) ?? 'Error en el servidor. Intenta más tarde.';
        debugPrint('! ApiClient 500: $message');
        throw NetworkException(message, '500');
      default:
        message = _parseMessage(body) ?? 'Error de conexión (${response.statusCode}).';
        throw NetworkException(message, '${response.statusCode}');
    }
  }

  String? _parseMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>?;
      if (json == null) return null;
      final msg = json['message'] ?? json['error'] ?? json['msg'];
      return msg is String ? msg : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, String>? headers}) async {
    final h = await _headers(extra: headers);
    final response = await http.get(_uri(path), headers: h);
    _handleResponse(response);
    if (response.body.isEmpty) return {};
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('! ApiClient get parse error: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    // ! Login: no enviar Authorization
    final useAuth = !path.toLowerCase().contains('login');
    final h = await _headers(extra: headers, useAuth: useAuth);
    final encoded = body != null ? jsonEncode(body is Map ? body : body) : null;
    final response = await http.post(_uri(path), headers: h, body: encoded);
    _handleResponse(response);
    if (response.body.isEmpty) return {};
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('! ApiClient post parse error: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final h = await _headers(extra: headers);
    final encoded = body != null ? jsonEncode(body is Map ? body : body) : null;
    final response = await http.put(_uri(path), headers: h, body: encoded);
    _handleResponse(response);
    if (response.body.isEmpty) return {};
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('! ApiClient put parse error: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final h = await _headers(extra: headers);
    final encoded = body != null ? jsonEncode(body is Map ? body : body) : null;
    final uri = _uri(path);
    debugPrint('ApiClient PATCH $uri bodyLength=${encoded?.length ?? 0}');
    final response = await http.patch(uri, headers: h, body: encoded);
    debugPrint('ApiClient PATCH response ${response.statusCode}');
    _handleResponse(response);
    if (response.body.isEmpty) return {};
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('! ApiClient patch parse error: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> delete(String path, {Map<String, String>? headers}) async {
    final h = await _headers(extra: headers);
    final response = await http.delete(_uri(path), headers: h);
    _handleResponse(response);
    if (response.body.isEmpty) return {};
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('! ApiClient delete parse error: $e');
      return {};
    }
  }
}
