import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../config/app_environment.dart';
import '../../../core/auth/token_storage_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../models/afiliar_rostro_request.dart';
import '../../models/afiliar_rostro_response.dart';

/// Fuente remota para afiliación de rostro (POST /api/face-auth/enroll).
abstract class AfiliarRostroRemoteDatasource {
  Future<AfiliarRostroResponse> afiliar({required AfiliarRostroRequest request});
}

class AfiliarRostroRemoteDatasourceImpl implements AfiliarRostroRemoteDatasource {
  AfiliarRostroRemoteDatasourceImpl({
    required TokenStorageService tokenStorage,
    String? baseUrl,
  })  : _tokenStorage = tokenStorage,
        _baseUrl = baseUrl ?? AppEnvironmentConfig.baseUrl;

  final TokenStorageService _tokenStorage;
  final String _baseUrl;

  static const _pathEnroll = '/api/face-auth/enroll';

  @override
  Future<AfiliarRostroResponse> afiliar({
    required AfiliarRostroRequest request,
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Tu sesión ha expirado.', '401');
    }

    final bearerToken = token.replaceAll(RegExp(r'\s+'), '');

    final uri = Uri.parse(
      '${_baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/'}api/face-auth/enroll',
    );

    final multipartRequest = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $bearerToken'
      ..headers['Accept'] = 'application/json'
      ..fields['idUsuario'] = request.idUsuario
      ..files.add(
        http.MultipartFile.fromBytes(
          'foto1',
          request.foto1,
          filename: 'foto1.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      )
      ..files.add(
        http.MultipartFile.fromBytes(
          'foto2',
          request.foto2,
          filename: 'foto2.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

    debugPrint('AfiliarRostroRemoteDatasource: POST $_pathEnroll');

    final streamed = await multipartRequest.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401) {
      throw const AuthException('Tu sesión ha expirado.', '401');
    }
    if (response.statusCode == 400) {
      throw NetworkException(
        _parseMessage(response.body) ?? 'No fue posible validar las capturas faciales.',
        '400',
      );
    }
    if (response.statusCode >= 500) {
      throw const NetworkException(
        'No fue posible afiliar el rostro.\nIntenta nuevamente.',
        '500',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NetworkException(
        _parseMessage(response.body) ?? 'Error al afiliar el rostro (${response.statusCode}).',
        '${response.statusCode}',
      );
    }

    if (response.body.isEmpty) {
      return AfiliarRostroResponse(
        message: 'Rostro afiliado correctamente',
        fechaAfiliacion: DateTime.now(),
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AfiliarRostroResponse.fromJson(json).copyWithFallbackFecha();
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
}

extension on AfiliarRostroResponse {
  AfiliarRostroResponse copyWithFallbackFecha() {
    return AfiliarRostroResponse(
      message: message,
      fechaAfiliacion: fechaAfiliacion ?? DateTime.now(),
    );
  }
}
