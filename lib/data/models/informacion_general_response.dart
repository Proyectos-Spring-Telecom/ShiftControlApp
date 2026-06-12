/// Respuesta de GET /api/bitacora-vehicular/informacion-general.
class InformacionGeneralResponse {
  const InformacionGeneralResponse({
    required this.informacionGeneral,
  });

  final InformacionGeneral informacionGeneral;

  factory InformacionGeneralResponse.fromJson(Map<String, dynamic> json) {
    final data = json['informacionGeneral'] as Map<String, dynamic>? ?? json;
    return InformacionGeneralResponse(
      informacionGeneral: InformacionGeneral.fromJson(data),
    );
  }
}

class InformacionGeneral {
  const InformacionGeneral({
    required this.vehiculo,
    required this.operador,
    required this.estadoVehiculo,
    required this.metricasIniciales,
    this.ubicacion,
  });

  final VehiculoResumen vehiculo;
  final OperadorResumen operador;
  final List<EstadoVehiculoItem> estadoVehiculo;
  final List<MetricaInicialItem> metricasIniciales;
  final String? ubicacion;

  factory InformacionGeneral.fromJson(Map<String, dynamic> json) {
    final estadoList = json['estadoVehiculo'] as List<dynamic>? ?? [];
    final metricasList = json['metricasIniciales'] as List<dynamic>? ?? [];

    return InformacionGeneral(
      vehiculo: VehiculoResumen.fromJson(
        json['vehiculo'] as Map<String, dynamic>? ?? {},
      ),
      operador: OperadorResumen.fromJson(
        json['operador'] as Map<String, dynamic>? ?? {},
      ),
      estadoVehiculo: estadoList
          .map((e) => EstadoVehiculoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      metricasIniciales: metricasList
          .map((e) => MetricaInicialItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      ubicacion: json['ubicacion'] as String?,
    );
  }
}

class VehiculoResumen {
  const VehiculoResumen({
    this.titulo,
    this.subtitulo,
  });

  final String? titulo;
  final String? subtitulo;

  factory VehiculoResumen.fromJson(Map<String, dynamic> json) {
    return VehiculoResumen(
      titulo: json['titulo'] as String?,
      subtitulo: json['subtitulo'] as String?,
    );
  }
}

class OperadorResumen {
  const OperadorResumen({
    this.nombre,
    this.id,
  });

  final String? nombre;
  final String? id;

  factory OperadorResumen.fromJson(Map<String, dynamic> json) {
    return OperadorResumen(
      nombre: json['nombre'] as String?,
      id: json['id'] as String?,
    );
  }
}

class EstadoVehiculoItem {
  const EstadoVehiculoItem({
    this.etiqueta,
    this.valor,
  });

  final String? etiqueta;
  final String? valor;

  factory EstadoVehiculoItem.fromJson(Map<String, dynamic> json) {
    return EstadoVehiculoItem(
      etiqueta: json['etiqueta'] as String?,
      valor: json['valor'] as String?,
    );
  }
}

class MetricaInicialItem {
  const MetricaInicialItem({
    this.etiqueta,
    this.valor,
  });

  final String? etiqueta;
  final String? valor;

  factory MetricaInicialItem.fromJson(Map<String, dynamic> json) {
    return MetricaInicialItem(
      etiqueta: json['etiqueta'] as String?,
      valor: json['valor'] as String?,
    );
  }
}
