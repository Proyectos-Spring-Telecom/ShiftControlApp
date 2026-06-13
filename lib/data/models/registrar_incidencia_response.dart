/// Respuesta de POST /api/turnos/incidencias/accidente.
class RegistrarIncidenciaResponse {
  const RegistrarIncidenciaResponse({
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

  factory RegistrarIncidenciaResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return RegistrarIncidenciaResponse(
      id: (data['id'] as num?)?.toInt(),
      idTurno: (data['idTurno'] as num?)?.toInt(),
      idVehiculo: (data['idVehiculo'] as num?)?.toInt(),
      nombre: data['nombre'] as String?,
      message: json['message'] as String?,
    );
  }
}
