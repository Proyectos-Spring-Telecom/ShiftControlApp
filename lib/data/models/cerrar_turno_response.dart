/// Respuesta de PATCH /api/turnos (cierre geográfico).
class CerrarTurnoResponse {
  const CerrarTurnoResponse({
    this.id,
    this.nombre,
    this.idBitacoraCierre,
    this.duracion,
    this.message,
  });

  final int? id;
  final String? nombre;
  final int? idBitacoraCierre;
  final int? duracion;
  final String? message;

  factory CerrarTurnoResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CerrarTurnoResponse(
      id: (data['id'] as num?)?.toInt(),
      nombre: data['nombre'] as String?,
      idBitacoraCierre: (data['idBitacoraCierre'] as num?)?.toInt(),
      duracion: (data['duracion'] as num?)?.toInt(),
      message: json['message'] as String?,
    );
  }
}
