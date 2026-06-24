import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../config/app_environment.dart';
import '../../../core/auth/token_storage_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../models/face_affiliation_request.dart';
import '../../models/face_affiliation_response.dart';
import '../../models/face_affiliation_validate_pose_result.dart';

/// Fuente remota para afiliación facial (validate-pose y POST /api/rostros).
abstract class FaceAffiliationRemoteDatasource {
  Future<String> obtenerJwtSesion();

  Future<FaceAffiliationValidatePoseResult> validatePose({
    required int sampleIndex,
    required List<int> imageBytes,
    required String filename,
  });

  Future<FaceAffiliationResponse> registrarRostro({
    required FaceAffiliationRequest request,
  });
}

class FaceAffiliationRemoteDatasourceImpl implements FaceAffiliationRemoteDatasource {
  FaceAffiliationRemoteDatasourceImpl({
    required TokenStorageService tokenStorage,
    String? baseUrl,
  })  : _tokenStorage = tokenStorage,
        _baseUrl = baseUrl ?? AppEnvironmentConfig.baseUrl;

  final TokenStorageService _tokenStorage;
  final String _baseUrl;

  static const _pathValidatePose = '/api/embed/validate-pose';
  static const _pathRostros = '/api/rostros';
  static const _requestTimeout = Duration(seconds: 30);
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
      case 503:
        throw NetworkException(
          serverMsg?.isNotEmpty == true
              ? serverMsg!
              : 'No fue posible completar la afiliación facial.',
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
  Future<String> obtenerJwtSesion() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Tu sesión ha expirado.', '401');
    }
    return token.replaceAll(RegExp(r'\s+'), '');
  }

  @override
  Future<FaceAffiliationValidatePoseResult> validatePose({
    required int sampleIndex,
    required List<int> imageBytes,
    required String filename,
  }) async {
    final jwt = await obtenerJwtSesion();

    final request = http.MultipartRequest(
      'POST',
      _uri(_pathValidatePose, query: {'sample_index': '$sampleIndex'}),
    );
    request.headers['Authorization'] = 'Bearer $jwt';
    request.headers['Accept'] = 'application/json';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
        contentType: _contentTypeJpeg,
      ),
    );

    final streamed = await request.send().timeout(
      _requestTimeout,
      onTimeout: () => throw const NetworkException(
        'La solicitud tardó demasiado. Intenta nuevamente.',
        '408',
      ),
    );
    final response = await http.Response.fromStream(streamed);
    debugPrint(
      'FaceAffiliationRemoteDatasource: POST $_pathValidatePose?sample_index=$sampleIndex status=${response.statusCode}',
    );
    _throwForStatus(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return FaceAffiliationValidatePoseResult(
      valid: data['valid'] as bool? ?? false,
      message: data['message'] as String? ?? data['reason'] as String?,
    );
  }

  @override
  Future<FaceAffiliationResponse> registrarRostro({
    required FaceAffiliationRequest request,
  }) async {
    final jwt = await obtenerJwtSesion();

    final response = await http
        .post(
          _uri(_pathRostros),
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw const NetworkException(
            'La solicitud tardó demasiado. Intenta nuevamente.',
            '408',
          ),
        );

    debugPrint('FaceAffiliationRemoteDatasource: POST $_pathRostros status=${response.statusCode}');

    if (response.statusCode == 409) {
      final serverMsg = _parseMessage(response.body);
      throw NetworkException(
        serverMsg?.isNotEmpty == true
            ? serverMsg!
            : 'El rostro ya ha sido registrado previamente en el sistema.',
        '409',
      );
    }

    _throwForStatus(response);

    if (response.body.isEmpty) {
      return const FaceAffiliationResponse(success: true);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return FaceAffiliationResponse.fromJson(data);
  }
}
