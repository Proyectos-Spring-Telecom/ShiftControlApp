import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_environment.dart';
import '../errors/app_exception.dart';
import 'api_client.dart';

/// Implementación del [ApiClient] con soporte para refresh token.
/// - Adjunta Bearer token desde [getToken] (no en paths login/refresh).
/// - Ante 401/403 intenta [refreshToken] una vez y reintenta la request.
/// - Si el refresh falla llama [onSessionExpired] y lanza.
class HttpApiClient implements ApiClient {
  HttpApiClient({
    required this.getToken,
    this.refreshToken,
    this.onSessionExpired,
    String? baseUrl,
  }) : _baseUrl = baseUrl ?? AppEnvironmentConfig.baseUrl;

  final Future<String?> Function() getToken;
  final Future<String?> Function()? refreshToken;
  final VoidCallback? onSessionExpired;

  final String _baseUrl;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  static const _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$p');
  }

  bool _isAuthPath(String path) {
    final lower = path.toLowerCase();
    return lower.contains('login') || lower.contains('refresh');
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

  void _handleResponse(http.Response response, {required String path}) {
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
      case 403:
        message = _parseMessage(body) ?? 'No autorizado.';
        debugPrint('! ApiClient 403: $message');
        throw AuthException(message, '403');
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

  Future<String?> _doRefresh() async {
    if (_refreshCompleter != null) {
      try {
        return await _refreshCompleter!.future;
      } on AuthException {
        rethrow;
      }
    }
    _refreshCompleter = Completer<String?>();
    _isRefreshing = true;
    try {
      final newToken = refreshToken != null ? await refreshToken!() : null;
      _refreshCompleter!.complete(newToken);
      return newToken;
    } on AuthException catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } catch (e) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  void _triggerSessionExpired() {
    debugPrint('Refresh token expirado. Cerrando sesión.');
    onSessionExpired?.call();
  }

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, String>? headers}) async {
    final useAuth = !_isAuthPath(path);
    var h = await _headers(extra: headers, useAuth: useAuth);
    var response = await http.get(_uri(path), headers: h);

    if ((response.statusCode == 401 || response.statusCode == 403) &&
        useAuth &&
        refreshToken != null) {
      try {
        final newToken = await _doRefresh();
        if (newToken != null && newToken.isNotEmpty) {
          debugPrint('Reintentando request original (GET)');
          h = await _headers(extra: headers, useAuth: true);
          response = await http.get(_uri(path), headers: h);
        } else {
          _triggerSessionExpired();
        }
      } on AuthException {
        _triggerSessionExpired();
        rethrow;
      }
    }

    _handleResponse(response, path: path);
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
    final useAuth = !_isAuthPath(path);
    var h = await _headers(extra: headers, useAuth: useAuth);
    final encoded = body != null ? jsonEncode(body is Map ? body : body) : null;
    var response = await http.post(_uri(path), headers: h, body: encoded);

    if ((response.statusCode == 401 || response.statusCode == 403) &&
        useAuth &&
        refreshToken != null) {
      try {
        final newToken = await _doRefresh();
        if (newToken != null && newToken.isNotEmpty) {
          debugPrint('Reintentando request original (POST)');
          h = await _headers(extra: headers, useAuth: true);
          response = await http.post(_uri(path), headers: h, body: encoded);
        } else {
          _triggerSessionExpired();
        }
      } on AuthException {
        _triggerSessionExpired();
        rethrow;
      }
    }

    _handleResponse(response, path: path);
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
    var h = await _headers(extra: headers);
    final encoded = body != null ? jsonEncode(body is Map ? body : body) : null;
    var response = await http.put(_uri(path), headers: h, body: encoded);

    if ((response.statusCode == 401 || response.statusCode == 403) &&
        refreshToken != null) {
      try {
        final newToken = await _doRefresh();
        if (newToken != null && newToken.isNotEmpty) {
          debugPrint('Reintentando request original (PUT)');
          h = await _headers(extra: headers);
          response = await http.put(_uri(path), headers: h, body: encoded);
        } else {
          _triggerSessionExpired();
        }
      } on AuthException {
        _triggerSessionExpired();
        rethrow;
      }
    }

    _handleResponse(response, path: path);
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
    var h = await _headers(extra: headers);
    final encoded = body != null ? jsonEncode(body is Map ? body : body) : null;
    var response = await http.patch(_uri(path), headers: h, body: encoded);

    if ((response.statusCode == 401 || response.statusCode == 403) &&
        refreshToken != null) {
      try {
        final newToken = await _doRefresh();
        if (newToken != null && newToken.isNotEmpty) {
          debugPrint('Reintentando request original (PATCH)');
          h = await _headers(extra: headers);
          response = await http.patch(_uri(path), headers: h, body: encoded);
        } else {
          _triggerSessionExpired();
        }
      } on AuthException {
        _triggerSessionExpired();
        rethrow;
      }
    }

    _handleResponse(response, path: path);
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
    var h = await _headers(extra: headers);
    var response = await http.delete(_uri(path), headers: h);

    if ((response.statusCode == 401 || response.statusCode == 403) &&
        refreshToken != null) {
      try {
        final newToken = await _doRefresh();
        if (newToken != null && newToken.isNotEmpty) {
          debugPrint('Reintentando request original (DELETE)');
          h = await _headers(extra: headers);
          response = await http.delete(_uri(path), headers: h);
        } else {
          _triggerSessionExpired();
        }
      } on AuthException {
        _triggerSessionExpired();
        rethrow;
      }
    }

    _handleResponse(response, path: path);
    if (response.body.isEmpty) return {};
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('! ApiClient delete parse error: $e');
      return {};
    }
  }
}
