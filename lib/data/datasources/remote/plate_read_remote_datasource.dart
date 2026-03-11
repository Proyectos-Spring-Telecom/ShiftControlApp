import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../config/app_environment.dart';
import '../../../core/errors/app_exception.dart';

/// Resultado de POST /plate/read (detección + OCR de placa).
class PlateReadResult {
  const PlateReadResult({required this.plateNumber, this.confidence});
  final String plateNumber;
  final double? confidence;
}

/// Fuente de datos remota para lectura de placa (API BehaviorIQ).
abstract interface class PlateReadRemoteDatasource {
  Future<PlateReadResult> readPlate(String token, List<int> imageBytes);
}

class PlateReadRemoteDatasourceImpl implements PlateReadRemoteDatasource {
  PlateReadRemoteDatasourceImpl({String? baseUrl})
      : _baseUrl = baseUrl ?? AppEnvironmentConfig.faceAuthBaseUrl;

  final String _baseUrl;

  Uri get _uri => Uri.parse('$_baseUrl/plate/read');

  static final _contentTypeJpeg = MediaType('image', 'jpeg');

  String? _parseMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>?;
      if (json == null) return null;
      final msg = json['message'] ?? json['error'] ?? json['msg'] ?? json['detail'];
      return msg is String ? msg : null;
    } catch (_) {
      return null;
    }
  }

  /// POST /plate/read: request body = multipart/form-data con un único campo "file" (binary).
  /// Equivalente curl: -X POST ... -H 'accept: application/json' -H 'Authorization: Bearer <token>' -H 'Content-Type: multipart/form-data' -F 'file=@placa.jpeg;type=image/jpeg'
  /// Response 200/201: body JSON { "plate_number": "12G-270", "confidence": 0.99 }. Headers típicos: Content-Type: application/json; charset=utf-8, server: nginx, etc.
  @override
  Future<PlateReadResult> readPlate(String token, List<int> imageBytes) async {
    final request = http.MultipartRequest('POST', _uri);
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';
    // Content-Type se fija automáticamente: multipart/form-data; boundary=...
    final bytes = Uint8List.fromList(imageBytes);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: 'placa.jpeg',
      contentType: _contentTypeJpeg,
    ));

    debugPrint('Plate read API: POST $_uri');
    debugPrint('Plate read API: multipart/form-data campo "file" = imagen capturada (${imageBytes.length} bytes, filename placa.jpeg, type=image/jpeg)');

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint('Plate read API: statusCode=${response.statusCode}, body=${response.body}');

    if (response.statusCode == 400) {
      final message = _parseMessage(response.body) ?? 'No se detectó placa o parámetros inválidos.';
      debugPrint('Plate read API: 400 - mensaje del servidor: $message');
      throw NetworkException(message, '400');
    }
    // El API devuelve 404 cuando no detecta placa en la imagen (code: no_plate_found)
    if (response.statusCode == 404) {
      final message = _parseMessage(response.body) ?? 'No se detectó placa en la imagen.';
      debugPrint('Plate read API: 404 - mensaje del servidor: $message');
      throw NetworkException(message, '404');
    }
    if (response.statusCode == 403) {
      throw NetworkException(
        _parseMessage(response.body) ?? 'Servicio de placa no habilitado para esta solución.',
        '403',
      );
    }
    if (response.statusCode == 503) {
      throw NetworkException(
        _parseMessage(response.body) ?? 'Servicio no disponible. Intente más tarde.',
        '503',
      );
    }
    if (response.statusCode == 401) {
      throw AuthException(
        _parseMessage(response.body) ?? 'Sesión expirada o no autorizado.',
        '401',
      );
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw NetworkException(
        _parseMessage(response.body) ?? 'Error ${response.statusCode}',
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final plateNumber = (data['plate_number'] as String? ?? '').trim();
    final confidence = data['confidence'] as num?;
    if (plateNumber.isEmpty) {
      throw const NetworkException('No se recibió número de placa en la respuesta.');
    }
    debugPrint('Plate read API: 200/201 plate_number=$plateNumber confidence=${confidence?.toDouble()}');
    return PlateReadResult(
      plateNumber: plateNumber,
      confidence: confidence?.toDouble(),
    );
  }
}
