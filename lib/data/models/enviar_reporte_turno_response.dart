/// Respuesta de POST /api/reportes/turno/{id}/enviar.
class EnviarReporteTurnoResponse {
  const EnviarReporteTurnoResponse({
    required this.status,
    required this.message,
  });

  final String status;
  final String message;

  factory EnviarReporteTurnoResponse.fromJson(Map<String, dynamic> json) {
    return EnviarReporteTurnoResponse(
      status: json['status'] as String? ?? 'success',
      message: json['message'] as String? ?? 'Reporte enviado correctamente.',
    );
  }
}
