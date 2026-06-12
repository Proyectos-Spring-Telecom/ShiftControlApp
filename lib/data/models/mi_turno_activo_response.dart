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
  });

  final bool turnoActivo;
  final int? idTurno;
  final DateTime? fechaInicio;
  final int? duracionSegundos;
  final MiTurnoActivoVehiculo? vehiculo;

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
    );
  }

  /// Duración como Duration para formatear en UI.
  Duration get duracion => Duration(seconds: duracionSegundos ?? 0);
}
