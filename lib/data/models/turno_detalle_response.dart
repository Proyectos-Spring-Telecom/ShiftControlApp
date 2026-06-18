import 'informacion_general_response.dart';

/// Respuesta de GET /api/turnos/{id}.
class TurnoDetalleResponse {
  const TurnoDetalleResponse({required this.data});

  final TurnoDetalle data;

  factory TurnoDetalleResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    if (raw is Map<String, dynamic>) {
      final merged = Map<String, dynamic>.from(raw);
      _copyIfMap(json, merged, 'vehiculoPlaca');
      _copyIfMap(json, merged, 'usuarioDetalle');
      _copyIfMap(json, merged, 'bitacoraResumen');
      return TurnoDetalleResponse(data: TurnoDetalle.fromJson(merged));
    }
    return TurnoDetalleResponse(data: TurnoDetalle.fromJson(json));
  }

  static void _copyIfMap(
    Map<String, dynamic> source,
    Map<String, dynamic> target,
    String key,
  ) {
    final value = source[key];
    if (value is Map<String, dynamic>) {
      target[key] = value;
    }
  }
}

class TurnoDetalle {
  const TurnoDetalle({
    required this.id,
    this.vehiculo,
    this.vehiculoPlaca,
    this.usuarioDetalle,
    this.estatusTurno,
    this.fechaApertura,
    this.fechaCierre,
    this.duracion,
    this.evidenciaApertura,
    this.evidenciaCierre,
    this.bitacoraResumen,
    this.incidenciasGasolina = const [],
    this.incidenciasAccidente = const [],
  });

  final int id;
  final String? vehiculo;
  final VehiculoPlacaDetalle? vehiculoPlaca;
  final UsuarioDetalle? usuarioDetalle;
  final EstatusTurnoDetalle? estatusTurno;
  final DateTime? fechaApertura;
  final DateTime? fechaCierre;
  final String? duracion;
  final String? evidenciaApertura;
  final String? evidenciaCierre;
  final BitacoraResumenDetalle? bitacoraResumen;
  final List<IncidenciaGasolinaItem> incidenciasGasolina;
  final List<IncidenciaAccidenteItem> incidenciasAccidente;

  factory TurnoDetalle.fromJson(Map<String, dynamic> json) {
    return TurnoDetalle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      vehiculo: _parseVehiculoString(json['vehiculo']),
      vehiculoPlaca: json['vehiculoPlaca'] is Map<String, dynamic>
          ? VehiculoPlacaDetalle.fromJson(
              json['vehiculoPlaca'] as Map<String, dynamic>,
            )
          : null,
      usuarioDetalle: json['usuarioDetalle'] is Map<String, dynamic>
          ? UsuarioDetalle.fromJson(
              json['usuarioDetalle'] as Map<String, dynamic>,
            )
          : null,
      estatusTurno: json['estatusTurno'] is Map<String, dynamic>
          ? EstatusTurnoDetalle.fromJson(
              json['estatusTurno'] as Map<String, dynamic>,
            )
          : null,
      fechaApertura: _parseDateTime(json['fechaApertura']),
      fechaCierre: _parseDateTime(json['fechaCierre']),
      duracion: json['duracion'] as String?,
      evidenciaApertura: json['evidenciaApertura'] as String?,
      evidenciaCierre: json['evidenciaCierre'] as String?,
      bitacoraResumen: json['bitacoraResumen'] is Map<String, dynamic>
          ? BitacoraResumenDetalle.fromJson(
              json['bitacoraResumen'] as Map<String, dynamic>,
            )
          : null,
      incidenciasGasolina: _parseIncidenciasGasolina(json['incidenciasGasolina']),
      incidenciasAccidente:
          _parseIncidenciasAccidente(json['incidenciasAccidente']),
    );
  }

  static List<IncidenciaGasolinaItem> _parseIncidenciasGasolina(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(IncidenciaGasolinaItem.fromJson)
        .toList();
  }

  static List<IncidenciaAccidenteItem> _parseIncidenciasAccidente(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(IncidenciaAccidenteItem.fromJson)
        .toList();
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.parse(raw).toLocal();
  }

  static String? _parseVehiculoString(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw is Map<String, dynamic>) {
      final marca = raw['marca'] as String?;
      final modelo = raw['modelo'] as String?;
      final partes = [marca, modelo]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (partes.isNotEmpty) return partes.join(' ');
      final placas = raw['placas'] as String?;
      if (placas != null && placas.trim().isNotEmpty) return placas.trim();
    }
    return null;
  }
}

class VehiculoPlacaDetalle {
  const VehiculoPlacaDetalle({
    this.marcaNombre,
    this.modeloNombre,
    this.anio,
    this.placa,
    this.numeroEconomico,
  });

  final String? marcaNombre;
  final String? modeloNombre;
  final int? anio;
  final String? placa;
  final String? numeroEconomico;

  factory VehiculoPlacaDetalle.fromJson(Map<String, dynamic> json) {
    return VehiculoPlacaDetalle(
      marcaNombre: json['marcaNombre'] as String?,
      modeloNombre: json['modeloNombre'] as String?,
      anio: (json['anio'] as num?)?.toInt(),
      placa: json['placa'] as String?,
      numeroEconomico: json['numeroEconomico']?.toString(),
    );
  }
}

class UsuarioDetalle {
  const UsuarioDetalle({
    this.id,
    this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
  });

  final int? id;
  final String? nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;

  factory UsuarioDetalle.fromJson(Map<String, dynamic> json) {
    return UsuarioDetalle(
      id: (json['id'] as num?)?.toInt(),
      nombre: json['nombre'] as String?,
      apellidoPaterno: json['apellidoPaterno'] as String?,
      apellidoMaterno: json['apellidoMaterno'] as String?,
    );
  }
}

class EstatusTurnoDetalle {
  const EstatusTurnoDetalle({this.nombre});

  final String? nombre;

  factory EstatusTurnoDetalle.fromJson(Map<String, dynamic> json) {
    return EstatusTurnoDetalle(nombre: json['nombre'] as String?);
  }
}

class BitacoraResumenDetalle {
  const BitacoraResumenDetalle({this.inicio, this.fin});

  final BitacoraResumenEtapaDetalle? inicio;
  final BitacoraResumenEtapaDetalle? fin;

  factory BitacoraResumenDetalle.fromJson(Map<String, dynamic> json) {
    return BitacoraResumenDetalle(
      inicio: json['inicio'] is Map<String, dynamic>
          ? BitacoraResumenEtapaDetalle.fromJson(
              json['inicio'] as Map<String, dynamic>,
            )
          : null,
      fin: json['fin'] is Map<String, dynamic>
          ? BitacoraResumenEtapaDetalle.fromJson(
              json['fin'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class BitacoraResumenEtapaDetalle {
  const BitacoraResumenEtapaDetalle({
    this.informacionGeneral,
    this.tablero,
  });

  final BitacoraInformacionGeneralDetalle? informacionGeneral;
  final TableroDetalle? tablero;

  factory BitacoraResumenEtapaDetalle.fromJson(Map<String, dynamic> json) {
    return BitacoraResumenEtapaDetalle(
      informacionGeneral: json['informacionGeneral'] is Map<String, dynamic>
          ? BitacoraInformacionGeneralDetalle.fromJson(
              json['informacionGeneral'] as Map<String, dynamic>,
            )
          : null,
      tablero: json['tablero'] is Map<String, dynamic>
          ? TableroDetalle.fromJson(json['tablero'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BitacoraInformacionGeneralDetalle {
  const BitacoraInformacionGeneralDetalle({
    this.ubicacion,
    this.estadoVehiculo = const [],
    this.metricasIniciales = const [],
  });

  final String? ubicacion;
  final List<EstadoVehiculoItem> estadoVehiculo;
  final List<MetricaInicialItem> metricasIniciales;

  factory BitacoraInformacionGeneralDetalle.fromJson(
    Map<String, dynamic> json,
  ) {
    final estadoList = json['estadoVehiculo'] as List<dynamic>? ?? [];
    final metricasList = json['metricasIniciales'] as List<dynamic>? ?? [];

    return BitacoraInformacionGeneralDetalle(
      ubicacion: json['ubicacion'] as String?,
      estadoVehiculo: estadoList
          .whereType<Map<String, dynamic>>()
          .map(EstadoVehiculoItem.fromJson)
          .toList(),
      metricasIniciales: metricasList
          .whereType<Map<String, dynamic>>()
          .map(MetricaInicialItem.fromJson)
          .toList(),
    );
  }
}

class TableroDetalle {
  const TableroDetalle({this.fotoTablero, this.kmActual});

  final String? fotoTablero;
  final num? kmActual;

  factory TableroDetalle.fromJson(Map<String, dynamic> json) {
    return TableroDetalle(
      fotoTablero: json['fotoTablero'] as String?,
      kmActual: json['kmActual'] as num?,
    );
  }
}

class IncidenciaGasolinaItem {
  const IncidenciaGasolinaItem({
    required this.id,
    this.litrosCargados,
    this.totalPagado,
    this.kilometraje,
    this.fotoTableroAntes,
    this.fotoTableroDespues,
    this.fotoBomba,
    this.fechaRegistro,
  });

  final int id;
  final double? litrosCargados;
  final double? totalPagado;
  final int? kilometraje;
  final String? fotoTableroAntes;
  final String? fotoTableroDespues;
  final String? fotoBomba;
  final DateTime? fechaRegistro;

  factory IncidenciaGasolinaItem.fromJson(Map<String, dynamic> json) {
    return IncidenciaGasolinaItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      litrosCargados: (json['litrosCargados'] as num?)?.toDouble(),
      totalPagado: (json['totalPagado'] as num?)?.toDouble(),
      kilometraje: (json['kilometraje'] as num?)?.toInt(),
      fotoTableroAntes: _parseUrl(json['fotoTableroAntes']),
      fotoTableroDespues: _parseUrl(json['fotoTableroDespues']),
      fotoBomba: _parseUrl(json['fotoBomba']),
      fechaRegistro: TurnoDetalle._parseDateTime(json['fechaRegistro']),
    );
  }

  static String? _parseUrl(dynamic raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class IncidenciaAccidenteItem {
  const IncidenciaAccidenteItem({
    required this.id,
    this.descripcion,
    this.fotoEvidencia1,
    this.fotoEvidencia2,
    this.fotoEvidencia3,
    this.fechaRegistro,
    this.catTipoIncidente,
  });

  final int id;
  final String? descripcion;
  final String? fotoEvidencia1;
  final String? fotoEvidencia2;
  final String? fotoEvidencia3;
  final DateTime? fechaRegistro;
  final CatTipoIncidente? catTipoIncidente;

  factory IncidenciaAccidenteItem.fromJson(Map<String, dynamic> json) {
    return IncidenciaAccidenteItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      descripcion: json['descripcion'] as String?,
      fotoEvidencia1: IncidenciaGasolinaItem._parseUrl(json['fotoEvidencia1']),
      fotoEvidencia2: IncidenciaGasolinaItem._parseUrl(json['fotoEvidencia2']),
      fotoEvidencia3: IncidenciaGasolinaItem._parseUrl(json['fotoEvidencia3']),
      fechaRegistro: TurnoDetalle._parseDateTime(json['fechaRegistro']),
      catTipoIncidente: json['catTipoIncidente'] is Map<String, dynamic>
          ? CatTipoIncidente.fromJson(
              json['catTipoIncidente'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class CatTipoIncidente {
  const CatTipoIncidente({this.id, this.nombre});

  final int? id;
  final String? nombre;

  factory CatTipoIncidente.fromJson(Map<String, dynamic> json) {
    return CatTipoIncidente(
      id: (json['id'] as num?)?.toInt(),
      nombre: json['nombre'] as String?,
    );
  }
}
