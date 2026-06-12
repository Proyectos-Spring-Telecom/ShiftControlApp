/// Respuesta de PATCH /api/turnos/bitacora/cierre.
class CerrarBitacoraResponse {
  const CerrarBitacoraResponse({
    this.status,
    this.message,
    this.flujo,
  });

  final String? status;
  final String? message;
  final String? flujo;

  factory CerrarBitacoraResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return CerrarBitacoraResponse(
      status: json['status'] as String?,
      message: json['message'] as String?,
      flujo: data['flujo'] as String?,
    );
  }
}
