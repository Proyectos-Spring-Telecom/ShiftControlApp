import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../config/app_environment.dart';
import '../../../core/auth/token_storage_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/cerrar_bitacora_response.dart';
import '../../../data/models/cerrar_turno_response.dart';
import '../../../data/models/crear_turno_response.dart';
import '../../../data/models/informacion_general_response.dart';
import '../../../data/models/mi_turno_activo_response.dart';
import '../../../data/models/registrar_inspeccion_vehiculo_ex_response.dart';
import '../../../data/models/registrar_tablero_response.dart';
import '../../../data/models/registrar_accesorios_vehiculo_request.dart';
import '../../../data/models/registrar_accesorios_vehiculo_response.dart';
import '../../../data/models/registrar_documentacion_vehiculo_request.dart';
import '../../../data/models/registrar_documentacion_vehiculo_response.dart';
import '../../../data/models/registrar_incidencia_gasolina_response.dart';
import '../../../data/models/registrar_incidencia_response.dart';
import '../../../data/models/registrar_luces_vehiculo_request.dart';
import '../../../data/models/registrar_luces_vehiculo_response.dart';
import '../../../data/models/registrar_niveles_fluidos_request.dart';
import '../../../data/models/registrar_niveles_fluidos_response.dart';
import '../../../data/models/registrar_testigos_request.dart';
import '../../../data/models/registrar_testigos_response.dart';
import '../../../data/models/turno_list_response.dart';
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

  /// GET /api/ubicacion/reverse ��� direcci?n a partir de coordenadas GPS.
  Future<UbicacionReverseResult> obtenerDireccion({
    required double lat,
    required double lon,
  }) async {
    debugPrint('TurnosService: GET /api/ubicacion/reverse lat=$lat, lon=$lon');
    try {
      final data = await _client.get('/api/ubicacion/reverse?lat=$lat&lon=$lon');
      debugPrint('TurnosService: ubicaci?n obtenida: ${data['displayName']}');
      return UbicacionReverseResult.fromJson(data);
    } on AuthException catch (e) {
      debugPrint('TurnosService: ubicaci?n AuthException ${e.code}: ${e.message}');
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('TurnosService: ubicaci?n NetworkException ${e.code}: ${e.message}');
      rethrow;
    }
  }

  /// Crea un turno de apertura con foto + ubicaci?n GPS.
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
      throw const AuthException('Sesi?n expirada. Inicia sesi?n de nuevo.', '401');
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
        _parseMessage(response.body) ?? 'Sesi?n expirada.',
        '401',
      );
    }
    if (response.statusCode == 400) {
      throw AuthException(
        _parseMessage(response.body) ?? 'Datos inv?lidos.',
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
      throw const AuthException('Sesi?n expirada. Inicia sesi?n de nuevo.', '401');
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
        _parseMessage(response.body) ?? 'Sesi?n expirada.',
        '401',
      );
    }
    if (response.statusCode == 400) {
      throw AuthException(
        _parseMessage(response.body) ?? 'Datos inv?lidos.',
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

  /// Registra un da?o en inspecci?n exterior del veh?culo.
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
      throw const AuthException('Sesi?n expirada. Inicia sesi?n de nuevo.', '401');
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
        _parseMessage(response.body) ?? 'Sesi?n expirada.',
        '401',
      );
    }
    if (response.statusCode == 400) {
      throw AuthException(
        _parseMessage(response.body) ?? 'Datos inv?lidos.',
        '400',
      );
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw NetworkException(
        _parseMessage(response.body) ??
            'Error al registrar inspecci?n exterior (${response.statusCode})',
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('TurnosService: inspecci?n exterior registrada exitosamente');
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

  /// Registra niveles de fluidos del veh?culo.
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

  /// Registra estado de luces del veh?culo.
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
      debugPrint('TurnosService: luces del veh?culo registradas exitosamente');
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

  /// Registra accesorios del veh?culo.
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
      debugPrint('TurnosService: accesorios del veh?culo registrados exitosamente');
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

  /// Registra documentaci?n del veh?culo.
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
      debugPrint('TurnosService: documentaci?n del veh?culo registrada exitosamente');
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

  /// Registra incidencia de gasolina durante turno activo.
  /// POST /api/turnos/incidencias/gasolina (multipart/form-data)
  Future<RegistrarIncidenciaGasolinaResponse> registrarIncidenciaGasolina({
    required int idTurno,
    required double latitud,
    required double longitud,
    required double kilometraje,
    required double litrosCargados,
    required double totalPagado,
    required List<int> fotoTableroAntesBytes,
    required List<int> fotoBombaBytes,
    String fotoTableroFilename = 'tablero_antes.jpg',
    String fotoBombaFilename = 'bomba.jpg',
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Sesi?n expirada. Inicia sesi?n de nuevo.', '401');
    }

    final base = AppEnvironmentConfig.baseUrl.endsWith('/')
        ? AppEnvironmentConfig.baseUrl
        : '${AppEnvironmentConfig.baseUrl}/';
    final uri = Uri.parse('${base}api/turnos/incidencias/gasolina');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['idTurno'] = idTurno.toString();
    request.fields['latitud'] = latitud.toString();
    request.fields['longitud'] = longitud.toString();
    request.fields['kilometraje'] = kilometraje.toString();
    request.fields['litrosCargados'] = litrosCargados.toString();
    request.fields['totalPagado'] = totalPagado.toString();

    request.files.add(http.MultipartFile.fromBytes(
      'fotoTableroAntes',
      Uint8List.fromList(fotoTableroAntesBytes),
      filename: fotoTableroFilename,
      contentType: MediaType('image', 'jpeg'),
    ));
    request.files.add(http.MultipartFile.fromBytes(
      'fotoBomba',
      Uint8List.fromList(fotoBombaBytes),
      filename: fotoBombaFilename,
      contentType: MediaType('image', 'jpeg'),
    ));

    debugPrint(
      'TurnosService: POST /api/turnos/incidencias/gasolina idTurno=$idTurno, '
      'lat=$latitud, lng=$longitud, km=$kilometraje, '
      'litros=$litrosCargados, total=$totalPagado',
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint(
      'TurnosService: registrarIncidenciaGasolina statusCode=${response.statusCode}',
    );

    if (response.statusCode == 401) {
      throw const AuthException('Sesi?n expirada. Inicia sesi?n de nuevo.', '401');
    }
    if (response.statusCode == 403) {
      throw const AuthException('Acceso denegado.', '403');
    }
    if (response.statusCode == 404) {
      throw const NetworkException('Turno no encontrado.', '404');
    }
    if (response.statusCode == 400) {
      throw AuthException(
        _parseMessage(response.body) ?? 'Datos inv?lidos.',
        '400',
      );
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw NetworkException(
        _parseMessage(response.body) ??
            'No fue posible registrar la incidencia de gasolina (${response.statusCode})',
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('TurnosService: incidencia de gasolina registrada exitosamente');
    return RegistrarIncidenciaGasolinaResponse.fromJson(data);
  }

  /// Registra incidencia de accidente durante turno activo.
  /// POST /api/turnos/incidencias/accidente (multipart/form-data)
  Future<RegistrarIncidenciaResponse> registrarIncidencia({
    required int idTurno,
    required String descripcion,
    required double latitud,
    required double longitud,
    required List<int> fotoEvidencia1Bytes,
    int? idCatTipoIncidente,
    List<int>? fotoEvidencia2Bytes,
    List<int>? fotoEvidencia3Bytes,
    String fotoEvidencia1Filename = 'evidencia1.jpg',
    String fotoEvidencia2Filename = 'evidencia2.jpg',
    String fotoEvidencia3Filename = 'evidencia3.jpg',
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Sesi?n expirada. Inicia sesi?n de nuevo.', '401');
    }

    final base = AppEnvironmentConfig.baseUrl.endsWith('/')
        ? AppEnvironmentConfig.baseUrl
        : '${AppEnvironmentConfig.baseUrl}/';
    final uri = Uri.parse('${base}api/turnos/incidencias/accidente');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['idTurno'] = idTurno.toString();
    request.fields['descripcion'] = descripcion;
    request.fields['latitud'] = latitud.toString();
    request.fields['longitud'] = longitud.toString();
    if (idCatTipoIncidente != null) {
      request.fields['idCatTipoIncidente'] = idCatTipoIncidente.toString();
    }

    request.files.add(http.MultipartFile.fromBytes(
      'fotoEvidencia1',
      Uint8List.fromList(fotoEvidencia1Bytes),
      filename: fotoEvidencia1Filename,
      contentType: MediaType('image', 'jpeg'),
    ));

    if (fotoEvidencia2Bytes != null && fotoEvidencia2Bytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'fotoEvidencia2',
        Uint8List.fromList(fotoEvidencia2Bytes),
        filename: fotoEvidencia2Filename,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    if (fotoEvidencia3Bytes != null && fotoEvidencia3Bytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'fotoEvidencia3',
        Uint8List.fromList(fotoEvidencia3Bytes),
        filename: fotoEvidencia3Filename,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    debugPrint(
      'TurnosService: POST /api/turnos/incidencias/accidente idTurno=$idTurno, '
      'idCatTipoIncidente=$idCatTipoIncidente, lat=$latitud, lng=$longitud, '
      'fotos=${1 + (fotoEvidencia2Bytes != null ? 1 : 0) + (fotoEvidencia3Bytes != null ? 1 : 0)}',
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint(
      'TurnosService: registrarIncidencia statusCode=${response.statusCode}',
    );

    if (response.statusCode == 401) {
      throw const AuthException('Sesi?n expirada. Inicia sesi?n de nuevo.', '401');
    }
    if (response.statusCode == 403) {
      throw const AuthException('Acceso denegado.', '403');
    }
    if (response.statusCode == 404) {
      throw const NetworkException('Turno no encontrado.', '404');
    }
    if (response.statusCode == 400) {
      throw AuthException(
        _parseMessage(response.body) ?? 'Datos inv?lidos.',
        '400',
      );
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw NetworkException(
        _parseMessage(response.body) ??
            'No fue posible registrar la incidencia (${response.statusCode})',
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('TurnosService: incidencia registrada exitosamente');
    return RegistrarIncidenciaResponse.fromJson(data);
  }

  /// Cierre geogr?fico del turno.
  /// PATCH /api/turnos (multipart/form-data)
  Future<CerrarTurnoResponse> cerrarTurno({
    required int idTurno,
    required double latitud,
    required double longitud,
    required List<int> evidenciaCierreBytes,
    String filename = 'evidencia_cierre.jpeg',
  }) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Sesi?n expirada. Inicia sesi?n de nuevo.', '401');
    }

    final base = AppEnvironmentConfig.baseUrl.endsWith('/')
        ? AppEnvironmentConfig.baseUrl
        : '${AppEnvironmentConfig.baseUrl}/';
    final uri = Uri.parse('${base}api/turnos');
    final request = http.MultipartRequest('PATCH', uri);
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['idTurno'] = idTurno.toString();
    request.fields['latitud'] = latitud.toString();
    request.fields['longitud'] = longitud.toString();

    request.files.add(http.MultipartFile.fromBytes(
      'evidenciaCierre',
      Uint8List.fromList(evidenciaCierreBytes),
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
    ));

    debugPrint(
      'TurnosService: PATCH /api/turnos (multipart) idTurno=$idTurno, '
      'lat=$latitud, lng=$longitud, foto=${evidenciaCierreBytes.length} bytes',
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint('TurnosService: cerrarTurno statusCode=${response.statusCode}');

    if (response.statusCode == 401) {
      throw const AuthException('Sesi?n expirada. Inicia sesi?n de nuevo.', '401');
    }
    if (response.statusCode == 403) {
      throw const AuthException('Acceso denegado.', '403');
    }
    if (response.statusCode == 404) {
      throw const NetworkException('Turno no encontrado.', '404');
    }
    if (response.statusCode == 400) {
      throw AuthException(
        _parseMessage(response.body) ?? 'Datos inv?lidos.',
        '400',
      );
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw NetworkException(
        _parseMessage(response.body) ??
            'No fue posible cerrar el turno (${response.statusCode})',
        '${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('TurnosService: turno cerrado geogr?ficamente exitosamente');
    return CerrarTurnoResponse.fromJson(data);
  }

  /// Cierra la bit?cora de apertura del turno.
  /// PATCH /api/turnos/bitacora/cierre (application/json)
  Future<CerrarBitacoraResponse> cerrarBitacoraApertura({
    required int idBitacoraVehiculo,
  }) async {
    debugPrint(
      'TurnosService: PATCH /api/turnos/bitacora/cierre '
      'idBitacoraVehiculo=$idBitacoraVehiculo',
    );
    try {
      final data = await _client.patch(
        '/api/turnos/bitacora/cierre',
        body: {'idBitacoraVehiculo': idBitacoraVehiculo},
      );
      debugPrint('TurnosService: bit?cora de apertura cerrada exitosamente');
      return CerrarBitacoraResponse.fromJson(data);
    } on AuthException catch (e) {
      debugPrint(
        'TurnosService: cerrarBitacoraApertura AuthException ${e.code}: ${e.message}',
      );
      if (e.code == '401') {
        throw const AuthException(
          'Tu sesi?n ha expirado. Inicia sesi?n nuevamente.',
          '401',
        );
      }
      rethrow;
    } on NetworkException catch (e) {
      debugPrint(
        'TurnosService: cerrarBitacoraApertura NetworkException ${e.code}: ${e.message}',
      );
      if (e.code == '404') {
        throw const NetworkException('Bit?cora no encontrada.', '404');
      }
      if (e.code == '500') {
        throw const NetworkException(
          'No fue posible cerrar la bit?cora. Intenta nuevamente.',
          '500',
        );
      }
      rethrow;
    }
  }

  static const _pathListarTurnos = '/api/turnos/list';

  /// Lista turnos por rango de fechas (YYYY-MM-DD).
  Future<List<TurnoListItem>> listarTurnos({
    required String fechaDesde,
    required String fechaHasta,
  }) async {
    final path =
        '$_pathListarTurnos?fechaDesde=$fechaDesde&fechaHasta=$fechaHasta';
    debugPrint('TurnosService: GET $path');
    try {
      final data = await _client.get(path);
      final response = TurnoListResponse.fromJson(data);
      debugPrint('TurnosService: listarTurnos ${response.items.length} items');
      return response.items;
    } on AuthException catch (e) {
      debugPrint('TurnosService: listarTurnos AuthException ${e.code}: ${e.message}');
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('TurnosService: listarTurnos NetworkException ${e.code}: ${e.message}');
      rethrow;
    }
  }

  String? _parseMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>?;
      final msg = json?['message'] ?? json?['error'];
      String? base;
      if (msg is String) {
        base = msg;
      } else if (msg is List) {
        base = msg.join('\n');
      }
      final campos = json?['camposFaltantes'];
      if (campos is List && campos.isNotEmpty) {
        final lista = campos.map((e) => e.toString()).join('\nโ�ข ');
        final prefix = base != null ? '$base\n\n' : '';
        return '${prefix}Campos faltantes:\nโ�ข $lista';
      }
      return base;
    } catch (_) {
      return null;
    }
  }
}
