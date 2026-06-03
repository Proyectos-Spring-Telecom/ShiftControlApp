import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../config/app_environment.dart';
import '../../../core/errors/app_exception.dart';

/// Resultado del login Face Auth.
class FaceAuthLoginResult {
  const FaceAuthLoginResult({required this.accessToken});
  final String accessToken;
}

/// Resultado de GET /auth/me (datos del usuario autenticado; usado en otros servicios API).
class FaceAuthMeResult {
  const FaceAuthMeResult({
    required this.idCliente,
    this.idUsuario,
    this.idSolucion,
    this.usuario,
    this.isRoot,
    this.rol,
  });
  final String idCliente;
  final int? idUsuario;
  final dynamic idSolucion;
  final String? usuario;
  final bool? isRoot;
  final String? rol;
}

/// Resultado de liveness-check.
class FaceAuthLivenessResult {
  const FaceAuthLivenessResult({required this.passed, this.reason, this.score});
  final bool passed;
  final String? reason;
  final num? score;
}

/// Resultado de validateFace (persona reconocida).
class FaceAuthValidateResult {
  const FaceAuthValidateResult({
    required this.success,
    required this.nombre,
    this.paterno,
    this.materno,
    this.distancia,
  });
  final bool success;
  final String nombre;
  final String? paterno;
  final String? materno;
  final num? distancia;
}

/// Fuente de datos remota para Face Auth (API BehaviorIQ).
abstract interface class FaceAuthRemoteDatasource {
  Future<FaceAuthLoginResult> login(String usuario, String contrasena);
  Future<FaceAuthMeResult> me(String token);
  Future<FaceAuthLivenessResult> livenessCheck(String token, List<int> image1, List<int> image2);
  Future<List<double>> embed(String token, List<int> imageBytes);
  Future<FaceAuthValidateResult> validateFace(String token, String idCliente, List<double> embedding);
}

class FaceAuthRemoteDatasourceImpl implements FaceAuthRemoteDatasource {
  FaceAuthRemoteDatasourceImpl({String? baseUrl})
      : _baseUrl = baseUrl ?? AppEnvironmentConfig.faceAuthBaseUrl;

  final String _baseUrl;

  String get _livenessBaseUrl =>
      AppEnvironmentConfig.faceAuthLivenessBaseUrl ?? _baseUrl;

  Uri _uri(String path) {
    final p = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_baseUrl/$p');
  }

  Uri _uriLiveness(String path) {
    final p = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_livenessBaseUrl/$p');
  }

  String? _parseMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>?;
      if (json == null) return null;
      final msg = json['message'] ?? json['error'] ?? json['msg'] ?? json['reason'];
      return msg is String ? msg : null;
    } catch (_) {
      return null;
    }
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final msg = _parseMessage(response.body) ?? 'Error ${response.statusCode}';
    if (response.statusCode == 400 || response.statusCode == 401) {
      throw AuthException(msg, '${response.statusCode}');
    }
    throw NetworkException(msg, '${response.statusCode}');
  }

  @override
  Future<FaceAuthLoginResult> login(String usuario, String contrasena) async {
    final body = jsonEncode({'usuario': usuario, 'contrasena': contrasena});
    final response = await http.post(
      _uri('auth/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: body,
    );
    debugPrint('[FaceAuth] Paso 1 - auth/login: status=${response.statusCode}');
    debugPrint('[FaceAuth] auth/login response body: ${response.body}');
    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['accessToken'] as String? ?? data['token'] as String? ?? data['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw const AuthException('No se recibió token del servidor.');
    }
    debugPrint('[FaceAuth] auth/login: token recibido (length=${token.length})');
    return FaceAuthLoginResult(accessToken: token);
  }

  @override
  Future<FaceAuthMeResult> me(String token) async {
    final response = await http.get(
      _uri('auth/me'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    debugPrint('[FaceAuth] Paso 2 - auth/me: status=${response.statusCode}');
    debugPrint('[FaceAuth] auth/me response: ${response.body}');
    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final idCliente = data['idCliente']?.toString() ?? data['id']?.toString() ?? '';
    if (idCliente.isEmpty) {
      throw const AuthException('No se recibió idCliente.');
    }
    final idUsuario = data['idUsuario'] is int ? data['idUsuario'] as int : null;
    final isRoot = data['isRoot'] as bool?;
    final rol = data['rol'] as String?;
    return FaceAuthMeResult(
      idCliente: idCliente,
      idUsuario: idUsuario,
      idSolucion: data['idSolucion'],
      usuario: data['usuario'] as String?,
      isRoot: isRoot,
      rol: rol,
    );
  }

  static final _contentTypeJpeg = MediaType('image', 'jpeg');

  @override
  Future<FaceAuthLivenessResult> livenessCheck(String token, List<int> image1, List<int> image2) async {
    final request = http.MultipartRequest('POST', _uriLiveness('embed/liveness-check'));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.files.add(http.MultipartFile.fromBytes(
      'files',
      image1,
      filename: 'capture_0.jpg',
      contentType: _contentTypeJpeg,
    ));
    request.files.add(http.MultipartFile.fromBytes(
      'files',
      image2,
      filename: 'capture_1.jpg',
      contentType: _contentTypeJpeg,
    ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    debugPrint('[FaceAuth] Paso 4 - embed/liveness-check: status=${response.statusCode}');
    debugPrint('[FaceAuth] liveness-check response body: ${response.body}');
    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final passed = data['passed'] as bool? ?? false;
    final reason = data['reason'] as String?;
    final score = data['score'] as num?;
    debugPrint('[FaceAuth] liveness-check: passed=$passed, reason=$reason, score=$score');
    return FaceAuthLivenessResult(passed: passed, reason: reason, score: score);
  }

  @override
  Future<List<double>> embed(String token, List<int> imageBytes) async {
    final request = http.MultipartRequest('POST', _uri('embed'));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: 'capture.jpg',
      contentType: _contentTypeJpeg,
    ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    debugPrint('[FaceAuth] Paso 5 - embed: status=${response.statusCode}');
    debugPrint('[FaceAuth] embed response body (length=${response.body.length}): ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}');
    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['embedding'];
    if (list is! List) {
      throw const NetworkException('Respuesta de embed inválida.');
    }
    final embedding = list.map((e) => (e as num).toDouble()).toList();
    debugPrint('[FaceAuth] embed: embedding length=${embedding.length}');
    return embedding;
  }

  @override
  Future<FaceAuthValidateResult> validateFace(String token, String idCliente, List<double> embedding) async {
    // API espera: { "embeddings": [ n1, n2, ..., n512 ] } — el arreglo 512D directo (InsightFace ArcFace de /embed)
    if (embedding.length != 512) {
      throw NetworkException('El embedding debe tener 512 elementos, se recibieron ${embedding.length}.');
    }
    final body = jsonEncode({'embeddings': embedding});
    debugPrint('[FaceAuth] validateFace request body: embeddings (512 elementos), body length=${body.length} chars');
    final response = await http.post(
      _uri('auth/validateFace/$idCliente'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    debugPrint('[FaceAuth] Paso 6 - auth/validateFace/$idCliente: status=${response.statusCode}');
    debugPrint('[FaceAuth] validateFace response body: ${response.body}');
    if (response.statusCode == 404) {
      debugPrint('[FaceAuth] validateFace: 404 - Rostro no reconocido');
      throw AuthException(
        _parseMessage(response.body) ?? 'Rostro no reconocido.',
        '404',
      );
    }
    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final success = data['success'] as bool? ?? true;
    final nombre = data['nombre'] as String? ?? '';
    final paterno = data['paterno'] as String?;
    final materno = data['materno'] as String?;
    final distancia = data['distancia'] as num?;
    debugPrint('[FaceAuth] validateFace: success=$success, nombre=$nombre, paterno=$paterno, materno=$materno, distancia=$distancia');
    return FaceAuthValidateResult(
      success: success,
      nombre: nombre,
      paterno: paterno,
      materno: materno,
      distancia: distancia,
    );
  }
}
