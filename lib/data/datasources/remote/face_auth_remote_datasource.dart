import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../config/app_environment.dart';
import '../../../core/errors/app_exception.dart';
import '../../models/login_me_response.dart';
import '../../models/login_tokens_response.dart';
import '../../models/user_model.dart';

/// Resultado de POST /api/embed/liveness-check.
class FaceAuthLivenessResult {
  const FaceAuthLivenessResult({required this.passed, this.reason, this.score});
  final bool passed;
  final String? reason;
  final num? score;
}

/// Sesión emitida por POST /api/auth/validateFace.
class FaceAuthValidateSessionResult {
  const FaceAuthValidateSessionResult({
    required this.token,
    this.refreshToken,
    this.expiresIn,
  });

  final String token;
  final String? refreshToken;
  final int? expiresIn;
}

/// Fuente de datos remota para Face Auth vía BFF ShiftControl.
abstract interface class FaceAuthRemoteDatasource {
  Future<String> obtainEmbedServiceJwt();

  Future<FaceAuthLivenessResult> livenessCheck(
    String jwt,
    List<int> image1,
    List<int> image2,
  );

  Future<List<double>> embed(String jwt, List<int> imageBytes);

  Future<FaceAuthValidateSessionResult> validateFace(
    List<double> embedding, {
    double? latitud,
    double? longitud,
  });

  Future<UserModel> fetchLoginMe(String sessionToken);
}

class FaceAuthRemoteDatasourceImpl implements FaceAuthRemoteDatasource {
  FaceAuthRemoteDatasourceImpl({String? baseUrl})
      : _baseUrl = baseUrl ?? AppEnvironmentConfig.baseUrl;

  final String _baseUrl;

  static const _pathLogin = '/api/login';
  static const _pathLivenessCheck = '/api/embed/liveness-check';
  static const _pathEmbed = '/api/embed';
  static const _pathValidateFace = '/api/auth/validateFace';
  static const _pathLoginMe = '/api/login/me';
  static const _requestTimeout = Duration(seconds: 30);

  /// Credenciales de servicio para JWT de liveness/embed (BFF ShiftControl).
  static const _embedServiceUser = 'admin@shiftcontrol.mx';
  static const _embedServicePassword = 'P@ssw0rd.';

  static final _contentTypeJpeg = MediaType('image', 'jpeg');

  Uri _uri(String path, {Map<String, String>? query}) {
    final base = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';
    final p = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$base$p').replace(queryParameters: query);
  }

  String? _parseMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>?;
      if (json == null) return null;
      final msg = json['message'] ?? json['error'] ?? json['msg'] ?? json['reason'];
      if (msg is String) return msg;
      if (msg is List) return msg.join('\n');
      return null;
    } catch (_) {
      return null;
    }
  }

  void _throwForStatus(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    final serverMsg = _parseMessage(response.body);
    final code = '${response.statusCode}';

    switch (response.statusCode) {
      case 400:
      case 401:
      case 403:
      case 404:
        throw AuthException(
          serverMsg?.isNotEmpty == true ? serverMsg! : 'Error $code',
          code,
        );
      case 429:
        throw NetworkException(
          serverMsg?.isNotEmpty == true
              ? serverMsg!
              : 'Demasiados intentos. Intenta nuevamente más tarde.',
          code,
        );
      case 500:
        throw NetworkException(
          serverMsg?.isNotEmpty == true ? serverMsg! : 'Error al validar identidad',
          code,
        );
      case 503:
        throw NetworkException(
          serverMsg?.isNotEmpty == true
              ? serverMsg!
              : 'Servicio de rostro no disponible.',
          code,
        );
      default:
        throw NetworkException(
          serverMsg ?? 'Error ${response.statusCode}',
          code,
        );
    }
  }

  @override
  Future<String> obtainEmbedServiceJwt() async {
    final response = await http
        .post(
          _uri(_pathLogin, query: const {'Nombres': 'SIT'}),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'userName': _embedServiceUser,
            'password': _embedServicePassword,
          }),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw const NetworkException(
            'La solicitud tardó demasiado. Intenta nuevamente.',
            '408',
          ),
        );
    debugPrint('[FaceAuth] POST $_pathLogin (embed JWT): status=${response.statusCode}');
    _throwForStatus(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tokens = LoginTokensResponse.fromJson(data);
    if (tokens.token.isEmpty) {
      throw const AuthException('No se recibió JWT de servicio para embed.');
    }
    return tokens.token;
  }

  @override
  Future<FaceAuthLivenessResult> livenessCheck(
    String jwt,
    List<int> image1,
    List<int> image2,
  ) async {
    final request = http.MultipartRequest('POST', _uri(_pathLivenessCheck));
    request.headers['Authorization'] = 'Bearer $jwt';
    request.headers['Accept'] = 'application/json';
    request.files.add(http.MultipartFile.fromBytes(
      'files',
      image1,
      filename: 'captura1.jpg',
      contentType: _contentTypeJpeg,
    ));
    request.files.add(http.MultipartFile.fromBytes(
      'files',
      image2,
      filename: 'captura2.jpg',
      contentType: _contentTypeJpeg,
    ));

    final streamed = await request.send().timeout(
      _requestTimeout,
      onTimeout: () => throw const NetworkException(
        'La solicitud tardó demasiado. Intenta nuevamente.',
        '408',
      ),
    );
    final response = await http.Response.fromStream(streamed);
    debugPrint('[FaceAuth] POST $_pathLivenessCheck: status=${response.statusCode}');
    debugPrint('[FaceAuth] liveness-check: ${response.body}');
    _throwForStatus(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return FaceAuthLivenessResult(
      passed: data['passed'] as bool? ?? false,
      reason: data['reason'] as String?,
      score: data['score'] as num?,
    );
  }

  @override
  Future<List<double>> embed(String jwt, List<int> imageBytes) async {
    final request = http.MultipartRequest('POST', _uri(_pathEmbed));
    request.headers['Authorization'] = 'Bearer $jwt';
    request.headers['Accept'] = 'application/json';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: 'capture.jpg',
      contentType: _contentTypeJpeg,
    ));

    final streamed = await request.send().timeout(
      _requestTimeout,
      onTimeout: () => throw const NetworkException(
        'La solicitud tardó demasiado. Intenta nuevamente.',
        '408',
      ),
    );
    final response = await http.Response.fromStream(streamed);
    debugPrint('[FaceAuth] POST $_pathEmbed: status=${response.statusCode}');
    _throwForStatus(response);

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
  Future<FaceAuthValidateSessionResult> validateFace(
    List<double> embedding, {
    double? latitud,
    double? longitud,
  }) async {
    if (embedding.isEmpty) {
      throw const AuthException('El embedding está vacío.', '400');
    }
    if (embedding.length != 512) {
      debugPrint('[FaceAuth] Embedding length inválido: ${embedding.length}');
      throw AuthException(
        'El embedding debe tener 512 elementos, se recibieron ${embedding.length}.',
        '400',
      );
    }

    final bodyMap = <String, dynamic>{'embeddings': embedding};
    if (latitud != null) bodyMap['latitud'] = latitud;
    if (longitud != null) bodyMap['longitud'] = longitud;

    final response = await http
        .post(
          _uri(_pathValidateFace),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(bodyMap),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw const NetworkException(
            'La solicitud tardó demasiado. Intenta nuevamente.',
            '408',
          ),
        );
    debugPrint('[FaceAuth] POST $_pathValidateFace: status=${response.statusCode}');
    debugPrint('[FaceAuth] validateFace: ${response.body}');
    _throwForStatus(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tokens = LoginTokensResponse.fromJson(data);
    if (tokens.token.isEmpty) {
      throw const AuthException('No se recibió token de sesión.');
    }
    return FaceAuthValidateSessionResult(
      token: tokens.token,
      refreshToken: tokens.refreshToken,
      expiresIn: tokens.expiresIn,
    );
  }

  @override
  Future<UserModel> fetchLoginMe(String sessionToken) async {
    final response = await http
        .get(
          _uri(_pathLoginMe),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $sessionToken',
          },
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw const NetworkException(
            'La solicitud tardó demasiado. Intenta nuevamente.',
            '408',
          ),
        );
    debugPrint('[FaceAuth] GET $_pathLoginMe: status=${response.statusCode}');
    _throwForStatus(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final me = LoginMeResponse.fromJson(data);
    return me.toUserModel(fallbackEmail: me.userName);
  }
}
