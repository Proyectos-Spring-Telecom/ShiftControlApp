/// Respuesta de POST /api/turnos/luces-vehiculo.
class RegistrarLucesVehiculoResponse {
  const RegistrarLucesVehiculoResponse({
    this.id,
    this.nombre,
    this.idBitacoraVehiculo,
    this.message,
  });

  final int? id;
  final String? nombre;
  final int? idBitacoraVehiculo;
  final String? message;

  factory RegistrarLucesVehiculoResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return RegistrarLucesVehiculoResponse(
      id: (data['id'] as num?)?.toInt(),
      nombre: data['nombre'] as String?,
      idBitacoraVehiculo: (data['idBitacoraVehiculo'] as num?)?.toInt(),
      message: json['message'] as String?,
    );
  }
}
