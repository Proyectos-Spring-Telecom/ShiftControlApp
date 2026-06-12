import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../config/app_environment.dart';
import '../../../core/auth/token_storage_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/crear_turno_response.dart';
import '../../../data/models/mi_turno_activo_response.dart';

class TurnosService {
  TurnosService(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorageService _tokenStorage;

  static const _pathMiTurno = '/api/turnos/mi-turno';

  /// Consulta si el usuario tiene un turno activo.
  Future<MiTurnoActivoResponse> obtenerMiTurnoActivo() async {
    debugPrint('TurnosService: GET $_pathMiTurno');
    try {
      final data = await _client.get(_pathMiTurno);
      debugPrint('TurnosService: mi-turno response turnoActivo=${data['turnoActivo']}');
      return MiTurnoActivoResponse.fromJson(data);
    } on AuthException catch (e) {
      debugPrint('TurnosService: AuthException ${e.code}: ${e.message}');
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('TurnosService: NetworkException ${e.code}: ${e.message}');
      rethrow;
    }
  }

  /// Crea un turno de apertura con foto + ubicación GPS.
  /// POST /api/turnos (multipart/form-data)
  Future<CrearTurnoResponse> crearTurno({
    required double latitud,
    required double longitud,
    required List<int> evidenciaBytes,
    String filename = 'evidencia.jpeg',
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Sesión expirada. Inicia sesión de nuevo.', '401');
    }

    final base = AppEnvironmentConfig.baseUrl.endsWith('/')
        ? AppEnvironmentConfig.baseUrl
        : '${AppEnvironmentConfig.baseUrl}/';
    final uri = Uri.parse('${base}api/turnos');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['latitud'] = latitud.toString();
    request.fields['longitud'] = longitud.toString();

    request.files.add(http.MultipartFile.fromBytes(
      'evidenciaApertura',
      Uint8List.fromList(evidenciaBytes),
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
    ));

    debugPrint(
      'TurnosService: POST /api/turnos (multipart) lat=$latitud, lng=$longitud, foto=${evidenciaBytes.length} bytes',
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint('TurnosService: crearTurno statusCode=${response.statusCode}');

    if (response.statusCode == 401) {
      throw AuthException(
        _parseMessage(response.body) ?? 'Sesión expirada.',
        '401',
      );
    }
    if (response.statusCode == 400) {
      throw AuthException(
        _parseMessage(response.body) ?? 'Datos inválidos.',
        '400',
      );
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw NetworkException(
        _parseMessage(response.body) ?? 'Error al crear turno (${response.statusCode})',
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('TurnosService: turno creado exitosamente');
    return CrearTurnoResponse.fromJson(data);
  }

  String? _parseMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>?;
      final msg = json?['message'] ?? json?['error'];
      if (msg is String) return msg;
      if (msg is List) return msg.join('\n');
      return null;
    } catch (_) {
      return null;
    }
  }
}
