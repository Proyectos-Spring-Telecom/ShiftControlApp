import '../../core/utils/duracion_parser.dart';

class UltimoTurno {
  const UltimoTurno({
    this.fechaCierre,
    this.placa,
    this.marca,
    this.modelo,
    this.duracion,
  });

  final DateTime? fechaCierre;
  final String? placa;
  final String? marca;
  final String? modelo;
  final int? duracion;

  String get vehiculoDisplay {
    final parts = [marca, modelo].whereType<String>().where((s) => s.isNotEmpty);
    if (parts.isNotEmpty) return parts.join(' ');
    if (placa != null && placa!.isNotEmpty) return placa!;
    return '—';
  }

  factory UltimoTurno.fromJson(Map<String, dynamic> json) {
    final fechaRaw = json['fechaCierre'] as String?;
    return UltimoTurno(
      fechaCierre: fechaRaw != null ? DateTime.parse(fechaRaw).toLocal() : null,
      placa: json['placa'] as String?,
      marca: json['marca'] as String?,
      modelo: json['modelo'] as String?,
      duracion: parseDuracionSegundos(json['duracion']),
    );
  }

  UltimoTurno copyWith({
    DateTime? fechaCierre,
    String? placa,
    String? marca,
    String? modelo,
    int? duracion,
  }) {
    return UltimoTurno(
      fechaCierre: fechaCierre ?? this.fechaCierre,
      placa: placa ?? this.placa,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      duracion: duracion ?? this.duracion,
    );
  }
}

class UltimaIncidenciaGasolina {
  const UltimaIncidenciaGasolina({
    this.fechaRegistro,
    this.litrosCargados,
  });

  final DateTime? fechaRegistro;
  final double? litrosCargados;

  factory UltimaIncidenciaGasolina.fromJson(Map<String, dynamic> json) {
    final fechaRaw = json['fechaRegistro'] as String?;
    final litros = json['litrosCargados'];
    return UltimaIncidenciaGasolina(
      fechaRegistro:
          fechaRaw != null ? DateTime.parse(fechaRaw).toLocal() : null,
      litrosCargados: litros == null
          ? null
          : (litros is int ? litros.toDouble() : litros as num).toDouble(),
    );
  }

  UltimaIncidenciaGasolina copyWith({
    DateTime? fechaRegistro,
    double? litrosCargados,
  }) {
    return UltimaIncidenciaGasolina(
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      litrosCargados: litrosCargados ?? this.litrosCargados,
    );
  }
}

class UltimaIncidenciaAccidente {
  const UltimaIncidenciaAccidente({
    this.fechaRegistro,
    this.descripcion,
  });

  final DateTime? fechaRegistro;
  final String? descripcion;

  factory UltimaIncidenciaAccidente.fromJson(Map<String, dynamic> json) {
    final fechaRaw = json['fechaRegistro'] as String?;
    return UltimaIncidenciaAccidente(
      fechaRegistro:
          fechaRaw != null ? DateTime.parse(fechaRaw).toLocal() : null,
      descripcion: json['descripcion'] as String?,
    );
  }

  UltimaIncidenciaAccidente copyWith({
    DateTime? fechaRegistro,
    String? descripcion,
  }) {
    return UltimaIncidenciaAccidente(
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      descripcion: descripcion ?? this.descripcion,
    );
  }
}

class MiTurnoVehiculoDetalle {
  const MiTurnoVehiculoDetalle({
    this.marca,
    this.modelo,
    this.tipoVehiculo,
    this.combustible,
    this.anio,
    this.color,
    this.km,
    this.numeroEconomico,
  });

  final String? marca;
  final String? modelo;
  final String? tipoVehiculo;
  final String? combustible;
  final int? anio;
  final String? color;
  final int? km;
  final String? numeroEconomico;

  factory MiTurnoVehiculoDetalle.fromJson(Map<String, dynamic> json) {
    return MiTurnoVehiculoDetalle(
      marca: json['marcaNombre'] as String?,
      modelo: json['modeloNombre'] as String?,
      tipoVehiculo: json['tipoVehiculoNombre'] as String?,
      combustible: json['combustibleNombre'] as String?,
      anio: json['anio'] as int?,
      color: json['color'] as String?,
      km: json['km'] as int?,
      numeroEconomico: json['numeroEconomico'] as String?,
    );
  }
}

class MiTurnoActivoVehiculo {
  const MiTurnoActivoVehiculo({
    required this.id,
    required this.placas,
    this.fotoFrente,
    required this.idCliente,
    this.detalle,
  });

  final int id;
  final String placas;
  final String? fotoFrente;
  final int idCliente;
  final MiTurnoVehiculoDetalle? detalle;

  /// Título para UI: "Marca Modelo" (ej. "Volkswagen Virtus").
  String get titulo {
    final d = detalle;
    if (d == null) return placas;
    final marca = d.marca ?? '';
    final modelo = d.modelo ?? '';
    final parts = [marca, modelo].where((s) => s.isNotEmpty);
    if (parts.isEmpty) return placas;
    return parts.join(' ');
  }

  factory MiTurnoActivoVehiculo.fromJson(Map<String, dynamic> json) {
    return MiTurnoActivoVehiculo(
      id: json['id'] as int,
      placas: json['placas'] as String,
      fotoFrente: json['fotoFrente'] as String?,
      idCliente: json['idCliente'] as int,
      detalle: json['detalle'] != null
          ? MiTurnoVehiculoDetalle.fromJson(
              json['detalle'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class MiTurnoActivoResponse {
  const MiTurnoActivoResponse({
    required this.turnoActivo,
    this.idTurno,
    this.fechaInicio,
    this.duracionSegundos,
    this.vehiculo,
    this.ultimoTurno,
    this.ultimaIncidenciaGasolina,
    this.ultimaIncidenciaAccidente,
  });

  final bool turnoActivo;
  final int? idTurno;
  final DateTime? fechaInicio;
  final int? duracionSegundos;
  final MiTurnoActivoVehiculo? vehiculo;
  final UltimoTurno? ultimoTurno;
  final UltimaIncidenciaGasolina? ultimaIncidenciaGasolina;
  final UltimaIncidenciaAccidente? ultimaIncidenciaAccidente;

  factory MiTurnoActivoResponse.fromJson(Map<String, dynamic> json) {
    final fechaRaw = json['fechaInicio'] as String?;
    return MiTurnoActivoResponse(
      turnoActivo: json['turnoActivo'] as bool? ?? false,
      idTurno: json['idTurno'] as int?,
      fechaInicio: fechaRaw != null ? DateTime.parse(fechaRaw).toLocal() : null,
      duracionSegundos: json['duracionSegundos'] as int?,
      vehiculo: json['vehiculo'] != null
          ? MiTurnoActivoVehiculo.fromJson(
              json['vehiculo'] as Map<String, dynamic>,
            )
          : null,
      ultimoTurno: json['ultimoTurno'] != null
          ? UltimoTurno.fromJson(json['ultimoTurno'] as Map<String, dynamic>)
          : null,
      ultimaIncidenciaGasolina: json['ultimaIncidenciaGasolina'] != null
          ? UltimaIncidenciaGasolina.fromJson(
              json['ultimaIncidenciaGasolina'] as Map<String, dynamic>,
            )
          : null,
      ultimaIncidenciaAccidente: json['ultimaIncidenciaAccidente'] != null
          ? UltimaIncidenciaAccidente.fromJson(
              json['ultimaIncidenciaAccidente'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  MiTurnoActivoResponse copyWith({
    bool? turnoActivo,
    int? idTurno,
    DateTime? fechaInicio,
    int? duracionSegundos,
    MiTurnoActivoVehiculo? vehiculo,
    UltimoTurno? ultimoTurno,
    UltimaIncidenciaGasolina? ultimaIncidenciaGasolina,
    UltimaIncidenciaAccidente? ultimaIncidenciaAccidente,
  }) {
    return MiTurnoActivoResponse(
      turnoActivo: turnoActivo ?? this.turnoActivo,
      idTurno: idTurno ?? this.idTurno,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      duracionSegundos: duracionSegundos ?? this.duracionSegundos,
      vehiculo: vehiculo ?? this.vehiculo,
      ultimoTurno: ultimoTurno ?? this.ultimoTurno,
      ultimaIncidenciaGasolina:
          ultimaIncidenciaGasolina ?? this.ultimaIncidenciaGasolina,
      ultimaIncidenciaAccidente:
          ultimaIncidenciaAccidente ?? this.ultimaIncidenciaAccidente,
    );
  }

  /// Duración como Duration para formatear en UI.
  Duration get duracion => Duration(seconds: duracionSegundos ?? 0);
}
