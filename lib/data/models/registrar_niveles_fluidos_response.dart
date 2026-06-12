/// Respuesta de POST /api/turnos/niveles-fluidos.
class RegistrarNivelesFluidosResponse {
  const RegistrarNivelesFluidosResponse({
    this.id,
    this.nombre,
    this.idBitacoraVehiculo,
    this.message,
  });

  final int? id;
  final String? nombre;
  final int? idBitacoraVehiculo;
  final String? message;

  factory RegistrarNivelesFluidosResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return RegistrarNivelesFluidosResponse(
      id: (data['id'] as num?)?.toInt(),
      nombre: data['nombre'] as String?,
      idBitacoraVehiculo: (data['idBitacoraVehiculo'] as num?)?.toInt(),
      message: json['message'] as String?,
    );
  }
}
