/// Respuesta de POST /api/turnos/inspeccion-vehiculo-ex.
class RegistrarInspeccionVehiculoExResponse {
  const RegistrarInspeccionVehiculoExResponse({
    this.id,
    this.nombre,
    this.idInspeccionVehiculoEx,
    this.idBitacoraVehiculo,
    this.idTurno,
    this.idVehiculo,
    this.message,
  });

  final int? id;
  final String? nombre;
  final int? idInspeccionVehiculoEx;
  final int? idBitacoraVehiculo;
  final int? idTurno;
  final int? idVehiculo;
  final String? message;

  factory RegistrarInspeccionVehiculoExResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return RegistrarInspeccionVehiculoExResponse(
      id: (data['id'] as num?)?.toInt(),
      nombre: data['nombre'] as String?,
      idInspeccionVehiculoEx: (data['idInspeccionVehiculoEx'] as num?)?.toInt(),
      idBitacoraVehiculo: (data['idBitacoraVehiculo'] as num?)?.toInt(),
      idTurno: (data['idTurno'] as num?)?.toInt(),
      idVehiculo: (data['idVehiculo'] as num?)?.toInt(),
      message: json['message'] as String?,
    );
  }
}
