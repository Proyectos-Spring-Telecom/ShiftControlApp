/// Respuesta de POST /api/turnos/tablero.
class RegistrarTableroResponse {
  const RegistrarTableroResponse({
    this.id,
    this.idBitacoraVehiculo,
    this.message,
  });

  final int? id;
  final int? idBitacoraVehiculo;
  final String? message;

  factory RegistrarTableroResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return RegistrarTableroResponse(
      id: (data['id'] as num?)?.toInt(),
      idBitacoraVehiculo: (data['idBitacoraVehiculo'] as num?)?.toInt(),
      message: json['message'] as String?,
    );
  }
}
