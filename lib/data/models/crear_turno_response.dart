/// Respuesta de POST /api/turnos.
class CrearTurnoResponse {
  const CrearTurnoResponse({
    required this.idTurno,
    required this.idBitacoraApertura,
    this.nombre,
    this.message,
    this.placa,
    this.numeroEconomico,
    this.anio,
    this.marcaNombre,
    this.modeloNombre,
  });

  final int idTurno;
  final int idBitacoraApertura;
  final String? nombre;
  final String? message;
  final String? placa;
  final String? numeroEconomico;
  final int? anio;
  final String? marcaNombre;
  final String? modeloNombre;

  static Map<String, dynamic>? _vehiculoFromData(Map<String, dynamic> data) {
    final vehiculoPorPlaca = data['vehiculoPorPlaca'];
    if (vehiculoPorPlaca is Map<String, dynamic>) {
      final vehiculoData = vehiculoPorPlaca['data'];
      if (vehiculoData is Map<String, dynamic>) {
        final vehicle = vehiculoData['data'];
        if (vehicle is Map<String, dynamic>) return vehicle;
      }
    }

    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      final inner = nested['data'];
      if (inner is Map<String, dynamic>) {
        if (inner.containsKey('placa') || inner.containsKey('marcaNombre')) {
          return inner;
        }
        final vehicle = inner['data'];
        if (vehicle is Map<String, dynamic>) return vehicle;
      }
      if (nested.containsKey('placa') || nested.containsKey('marcaNombre')) {
        return nested;
      }
    }

    return null;
  }

  factory CrearTurnoResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final vehicle = _vehiculoFromData(data);

    return CrearTurnoResponse(
      idTurno: data['idTurno'] as int? ?? data['id'] as int? ?? 0,
      idBitacoraApertura: data['idBitacoraApertura'] as int? ?? 0,
      nombre: data['nombre'] as String?,
      message: json['message'] as String?,
      placa: vehicle?['placa'] as String?,
      numeroEconomico: vehicle?['numeroEconomico']?.toString(),
      anio: (vehicle?['anio'] as num?)?.toInt(),
      marcaNombre: vehicle?['marcaNombre'] as String?,
      modeloNombre: vehicle?['modeloNombre'] as String?,
    );
  }
}
