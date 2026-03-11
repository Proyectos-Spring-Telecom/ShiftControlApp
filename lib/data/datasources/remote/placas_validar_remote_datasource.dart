import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/app_environment.dart';
import '../../../core/errors/app_exception.dart';

/// Resultado de GET /placas/validar (comprobar si placa está registrada en contexto del usuario).
class PlacasValidarResult {
  const PlacasValidarResult({
    required this.registered,
    this.idPlaca,
    this.placa,
    this.marca,
    this.modelo,
    this.anio,
    this.color,
    this.economico,
  });
  final bool registered;
  final int? idPlaca;
  final String? placa;
  final String? marca;
  final String? modelo;
  final int? anio;
  final String? color;
  final String? economico;
}

/// Fuente de datos remota para validación de placa (API BehaviorIQ).
abstract interface class PlacasValidarRemoteDatasource {
  Future<PlacasValidarResult> validar(
    String token,
    String numeroPlaca, {
    int? idCliente,
    int? idSolucion,
    double? latitud,
    double? longitud,
  });
}

class PlacasValidarRemoteDatasourceImpl implements PlacasValidarRemoteDatasource {
  PlacasValidarRemoteDatasourceImpl({String? baseUrl})
      : _baseUrl = baseUrl ?? AppEnvironmentConfig.faceAuthBaseUrl;

  final String _baseUrl;

  @override
  Future<PlacasValidarResult> validar(
    String token,
    String numeroPlaca, {
    int? idCliente,
    int? idSolucion,
    double? latitud,
    double? longitud,
  }) async {
    final queryParams = <String, String>{
      'numeroPlaca': numeroPlaca,
    };
    if (idCliente != null) queryParams['idCliente'] = idCliente.toString();
    if (idSolucion != null) queryParams['idSolucion'] = idSolucion.toString();
    if (latitud != null) queryParams['latitud'] = latitud.toString();
    if (longitud != null) queryParams['longitud'] = longitud.toString();

    final uri = Uri.parse('$_baseUrl/placas/validar').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('PlacasValidar API: status=${response.statusCode}, body=${response.body}');

    if (response.statusCode == 401) {
      throw AuthException(
        _parseMessage(response.body) ?? 'Sesión expirada o no autorizado.',
        '401',
      );
    }
    if (response.statusCode >= 400) {
      throw NetworkException(
        _parseMessage(response.body) ?? 'Error ${response.statusCode}',
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final registered = data['registered'] as bool? ?? false;
    final idPlaca = data['idPlaca'] is int ? data['idPlaca'] as int : null;
    final anio = data['anio'] is int ? data['anio'] as int : null;
    return PlacasValidarResult(
      registered: registered,
      idPlaca: idPlaca,
      placa: data['placa'] as String?,
      marca: data['marca'] as String?,
      modelo: data['modelo'] as String?,
      anio: anio,
      color: data['color'] as String?,
      economico: data['economico'] as String?,
    );
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
