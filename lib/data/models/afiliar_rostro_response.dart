/// Respuesta de afiliación de rostro.
class AfiliarRostroResponse {
  const AfiliarRostroResponse({
    required this.message,
    this.fechaAfiliacion,
  });

  final String message;
  final DateTime? fechaAfiliacion;

  factory AfiliarRostroResponse.fromJson(Map<String, dynamic> json) {
    final fechaRaw = json['fechaAfiliacion'] as String?;
    return AfiliarRostroResponse(
      message: json['message'] as String? ?? 'Rostro afiliado correctamente',
      fechaAfiliacion: fechaRaw != null ? DateTime.tryParse(fechaRaw) : null,
    );
  }
}
