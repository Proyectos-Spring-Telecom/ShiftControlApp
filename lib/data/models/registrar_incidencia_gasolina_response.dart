/// Respuesta de POST /api/turnos/incidencias/gasolina.
class RegistrarIncidenciaGasolinaResponse {
  const RegistrarIncidenciaGasolinaResponse({
    this.id,
    this.idTurno,
    this.idVehiculo,
    this.nombre,
    this.message,
  });

  final int? id;
  final int? idTurno;
  final int? idVehiculo;
  final String? nombre;
  final String? message;

  factory RegistrarIncidenciaGasolinaResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return RegistrarIncidenciaGasolinaResponse(
      id: (data['id'] as num?)?.toInt(),
      idTurno: (data['idTurno'] as num?)?.toInt(),
      idVehiculo: (data['idVehiculo'] as num?)?.toInt(),
      nombre: data['nombre'] as String?,
      message: json['message'] as String?,
    );
  }
}
