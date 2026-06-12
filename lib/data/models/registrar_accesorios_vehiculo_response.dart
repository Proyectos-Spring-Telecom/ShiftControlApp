/// Respuesta de POST /api/turnos/accesorios-vehiculo.
class RegistrarAccesoriosVehiculoResponse {
  const RegistrarAccesoriosVehiculoResponse({
    this.id,
    this.nombre,
    this.idBitacoraVehiculo,
    this.message,
  });

  final int? id;
  final String? nombre;
  final int? idBitacoraVehiculo;
  final String? message;

  factory RegistrarAccesoriosVehiculoResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return RegistrarAccesoriosVehiculoResponse(
      id: (data['id'] as num?)?.toInt(),
      nombre: data['nombre'] as String?,
      idBitacoraVehiculo: (data['idBitacoraVehiculo'] as num?)?.toInt(),
      message: json['message'] as String?,
    );
  }
}
