/// Respuesta de POST /api/placas.
class RegistroVehiculoResponse {
  const RegistroVehiculoResponse({
    required this.idPlaca,
    required this.numeroPlaca,
    required this.economico,
  });

  final int idPlaca;
  final String numeroPlaca;
  final String economico;

  factory RegistroVehiculoResponse.fromJson(Map<String, dynamic> json) {
    return RegistroVehiculoResponse(
      idPlaca: (json['idPlaca'] as num).toInt(),
      numeroPlaca: json['numeroPlaca'] as String,
      economico: json['economico'] as String,
    );
  }
}
