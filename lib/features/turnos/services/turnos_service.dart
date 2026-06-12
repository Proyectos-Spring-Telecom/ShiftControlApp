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
import '../../../data/models/informacion_general_response.dart';
import '../../../data/models/mi_turno_activo_response.dart';
import '../../../data/models/registrar_inspeccion_vehiculo_ex_response.dart';
import '../../../data/models/registrar_tablero_response.dart';
import '../../../data/models/registrar_accesorios_vehiculo_request.dart';
import '../../../data/models/registrar_accesorios_vehiculo_response.dart';
import '../../../data/models/registrar_documentacion_vehiculo_request.dart';
import '../../../data/models/registrar_documentacion_vehiculo_response.dart';
import '../../../data/models/registrar_luces_vehiculo_request.dart';
import '../../../data/models/registrar_luces_vehiculo_response.dart';
import '../../../data/models/registrar_niveles_fluidos_request.dart';
import '../../../data/models/registrar_niveles_fluidos_response.dart';
import '../../../data/models/registrar_testigos_request.dart';
import '../../../data/models/registrar_testigos_response.dart';
import '../../../data/models/ubicacion_reverse_result.dart';

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

  /// GET /api/bitacora-vehicular/informacion-general
  Future<InformacionGeneralResponse> obtenerInformacionGeneral({
    required int idBitacoraVehiculo,
  }) async {
    debugPrint(
      'TurnosService: GET /api/bitacora-vehicular/informacion-general '
      'idBitacoraVehiculo=$idBitacoraVehiculo',
    );
    try {
      final data = await _client.get(
        '/api/bitacora-vehicular/informacion-general?idBitacoraVehiculo=$idBitacoraVehiculo',
      );
      debugPrint('TurnosService: informacion-general obtenida');
      return InformacionGeneralResponse.fromJson(data);
    } on AuthException catch (e) {
      debugPrint(
        'TurnosService: informacion-general AuthException ${e.code}: ${e.message}',
      );
      rethrow;
    } on NetworkException catch (e) {
      debugPrint(
        'TurnosService: informacion-general NetworkException ${e.code}: ${e.message}',
      );
      rethrow;
    }
  }

  /// GET /api/ubicacion/reverse — dirección a partir de coordenadas GPS.
  Future<UbicacionReverseResult> obtenerDireccion({
    required double lat,
    required double lon,
  }) async {
    debugPrint('TurnosService: GET /api/ubicacion/reverse lat=$lat, lon=$lon');
    try {
      final data = await _client.get('/api/ubicacion/reverse?lat=$lat&lon=$lon');
      debugPrint('TurnosService: ubicación obtenida: ${data['displayName']}');
      return UbicacionReverseResult.fromJson(data);
    } on AuthException catch (e) {
      debugPrint('TurnosService: ubicación AuthException ${e.code}: ${e.message}');
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('TurnosService: ubicación NetworkException ${e.code}: ${e.message}');
      rethrow;
    }
  }

  /// Crea un turno de apertura con foto + ubicación GPS.
  /// POST /api/turnos (multipart/form-data)
  Future<CrearTurnoResponse> crearTurno({
    required String placa,
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

    request.fields['placa'] = placa;
    request.fields['latitud'] = latitud.toString();
    request.fields['longitud'] = longitud.toString();

    request.files.add(http.MultipartFile.fromBytes(
      'evidenciaApertura',
      Uint8List.fromList(evidenciaBytes),
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
    ));

    debugPrint(
      'TurnosService: POST /api/turnos (multipart) placa=$placa, lat=$latitud, lng=$longitud, foto=${evidenciaBytes.length} bytes',
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

  /// Registra foto de tablero y kilometraje de apertura.
  /// POST /api/turnos/tablero (multipart/form-data)
  Future<RegistrarTableroResponse> registrarTablero({
    required int idBitacoraVehiculo,
    required String kilometraje,
    required List<int> fotoTableroBytes,
    String filename = 'tablero.jpeg',
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Sesión expirada. Inicia sesión de nuevo.', '401');
    }

    final base = AppEnvironmentConfig.baseUrl.endsWith('/')
        ? AppEnvironmentConfig.baseUrl
        : '${AppEnvironmentConfig.baseUrl}/';
    final uri = Uri.parse('${base}api/turnos/tablero');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['idBitacoraVehiculo'] = idBitacoraVehiculo.toString();
    request.fields['kilometraje'] = kilometraje;

    request.files.add(http.MultipartFile.fromBytes(
      'fotoTablero',
      Uint8List.fromList(fotoTableroBytes),
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
    ));

    debugPrint(
      'TurnosService: POST /api/turnos/tablero idBitacoraVehiculo=$idBitacoraVehiculo, km=$kilometraje, foto=${fotoTableroBytes.length} bytes',
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint('TurnosService: registrarTablero statusCode=${response.statusCode}');

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
        _parseMessage(response.body) ?? 'Error al registrar tablero (${response.statusCode})',
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('TurnosService: tablero registrado exitosamente');
    return RegistrarTableroResponse.fromJson(data);
  }

  /// Registra un daño en inspección exterior del vehículo.
  /// POST /api/turnos/inspeccion-vehiculo-ex (multipart/form-data)
  Future<RegistrarInspeccionVehiculoExResponse> registrarInspeccionVehiculoEx({
    required int idBitacoraVehiculo,
    required int idCatVistaVehiculo,
    required String partesVehiculoEx,
    required int idCatTipoDano,
    required int idCatGradoSeveridad,
    required List<int> evidenciaFotograficaBytes,
    String filename = 'evidencia.jpg',
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Sesión expirada. Inicia sesión de nuevo.', '401');
    }

    final base = AppEnvironmentConfig.baseUrl.endsWith('/')
        ? AppEnvironmentConfig.baseUrl
        : '${AppEnvironmentConfig.baseUrl}/';
    final uri = Uri.parse('${base}api/turnos/inspeccion-vehiculo-ex');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['idBitacoraVehiculo'] = idBitacoraVehiculo.toString();
    request.fields['idCatVistaVehiculo'] = idCatVistaVehiculo.toString();
    request.fields['partesVehiculoEx'] = partesVehiculoEx;
    request.fields['idCatTipoDano'] = idCatTipoDano.toString();
    request.fields['idCatGradoSeveridad'] = idCatGradoSeveridad.toString();

    final lowerName = filename.toLowerCase();
    final isPng = lowerName.endsWith('.png');
    request.files.add(http.MultipartFile.fromBytes(
      'evidenciaFotografica',
      Uint8List.fromList(evidenciaFotograficaBytes),
      filename: filename,
      contentType: MediaType('image', isPng ? 'png' : 'jpeg'),
    ));

    debugPrint(
      'TurnosService: POST /api/turnos/inspeccion-vehiculo-ex '
      'idBitacoraVehiculo=$idBitacoraVehiculo, vista=$idCatVistaVehiculo, '
      'tipo=$idCatTipoDano, severidad=$idCatGradoSeveridad, '
      'parte=$partesVehiculoEx, foto=${evidenciaFotograficaBytes.length} bytes',
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint(
      'TurnosService: registrarInspeccionVehiculoEx statusCode=${response.statusCode}',
    );

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
        _parseMessage(response.body) ??
            'Error al registrar inspección exterior (${response.statusCode})',
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('TurnosService: inspección exterior registrada exitosamente');
    return RegistrarInspeccionVehiculoExResponse.fromJson(data);
  }

  /// Registra indicadores testigo del tablero.
  /// POST /api/turnos/testigos (application/json)
  Future<RegistrarTestigosResponse> registrarTestigos(
    RegistrarTestigosRequest request,
  ) async {
    debugPrint(
      'TurnosService: POST /api/turnos/testigos idBitacoraVehiculo=${request.idBitacoraVehiculo}',
    );
    try {
      final data = await _client.post('/api/turnos/testigos', body: request.toJson());
      debugPrint('TurnosService: testigos registrados exitosamente');
      return RegistrarTestigosResponse.fromJson(data);
    } on AuthException catch (e) {
      debugPrint('TurnosService: registrarTestigos AuthException ${e.code}: ${e.message}');
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('TurnosService: registrarTestigos NetworkException ${e.code}: ${e.message}');
      rethrow;
    }
  }

  /// Registra niveles de fluidos del vehículo.
  /// POST /api/turnos/niveles-fluidos (application/json)
  Future<RegistrarNivelesFluidosResponse> registrarNivelesFluidos(
    RegistrarNivelesFluidosRequest request,
  ) async {
    debugPrint(
      'TurnosService: POST /api/turnos/niveles-fluidos '
      'idBitacoraVehiculo=${request.idBitacoraVehiculo}',
    );
    try {
      final data = await _client.post('/api/turnos/niveles-fluidos', body: request.toJson());
      debugPrint('TurnosService: niveles de fluidos registrados exitosamente');
      return RegistrarNivelesFluidosResponse.fromJson(data);
    } on AuthException catch (e) {
      debugPrint(
        'TurnosService: registrarNivelesFluidos AuthException ${e.code}: ${e.message}',
      );
      rethrow;
    } on NetworkException catch (e) {
      debugPrint(
        'TurnosService: registrarNivelesFluidos NetworkException ${e.code}: ${e.message}',
      );
      rethrow;
    }
  }

  /// Registra estado de luces del vehículo.
  /// POST /api/turnos/luces-vehiculo (application/json)
  Future<RegistrarLucesVehiculoResponse> registrarLucesVehiculo(
    RegistrarLucesVehiculoRequest request,
  ) async {
    debugPrint(
      'TurnosService: POST /api/turnos/luces-vehiculo '
      'idBitacoraVehiculo=${request.idBitacoraVehiculo}',
    );
    try {
      final data = await _client.post('/api/turnos/luces-vehiculo', body: request.toJson());
      debugPrint('TurnosService: luces del vehículo registradas exitosamente');
      return RegistrarLucesVehiculoResponse.fromJson(data);
    } on AuthException catch (e) {
      debugPrint(
        'TurnosService: registrarLucesVehiculo AuthException ${e.code}: ${e.message}',
      );
      rethrow;
    } on NetworkException catch (e) {
      debugPrint(
        'TurnosService: registrarLucesVehiculo NetworkException ${e.code}: ${e.message}',
      );
      rethrow;
    }
  }

  /// Registra accesorios del vehículo.
  /// POST /api/turnos/accesorios-vehiculo (application/json)
  Future<RegistrarAccesoriosVehiculoResponse> registrarAccesoriosVehiculo(
    RegistrarAccesoriosVehiculoRequest request,
  ) async {
    debugPrint(
      'TurnosService: POST /api/turnos/accesorios-vehiculo '
      'idBitacoraVehiculo=${request.idBitacoraVehiculo}',
    );
    try {
      final data = await _client.post('/api/turnos/accesorios-vehiculo', body: request.toJson());
      debugPrint('TurnosService: accesorios del vehículo registrados exitosamente');
      return RegistrarAccesoriosVehiculoResponse.fromJson(data);
    } on AuthException catch (e) {
      debugPrint(
        'TurnosService: registrarAccesoriosVehiculo AuthException ${e.code}: ${e.message}',
      );
      rethrow;
    } on NetworkException catch (e) {
      debugPrint(
        'TurnosService: registrarAccesoriosVehiculo NetworkException ${e.code}: ${e.message}',
      );
      rethrow;
    }
  }

  /// Registra documentación del vehículo.
  /// POST /api/turnos/documentacion-vehiculo (application/json)
  Future<RegistrarDocumentacionVehiculoResponse> registrarDocumentacionVehiculo(
    RegistrarDocumentacionVehiculoRequest request,
  ) async {
    debugPrint(
      'TurnosService: POST /api/turnos/documentacion-vehiculo '
      'idBitacoraVehiculo=${request.idBitacoraVehiculo}',
    );
    try {
      final data = await _client.post(
        '/api/turnos/documentacion-vehiculo',
        body: request.toJson(),
      );
      debugPrint('TurnosService: documentación del vehículo registrada exitosamente');
      return RegistrarDocumentacionVehiculoResponse.fromJson(data);
    } on AuthException catch (e) {
      debugPrint(
        'TurnosService: registrarDocumentacionVehiculo AuthException ${e.code}: ${e.message}',
      );
      rethrow;
    } on NetworkException catch (e) {
      debugPrint(
        'TurnosService: registrarDocumentacionVehiculo NetworkException ${e.code}: ${e.message}',
      );
      rethrow;
    }
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
