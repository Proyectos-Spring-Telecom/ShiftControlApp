/// DTO para futuro registro de vehículo en el BFF.
class RegistroVehiculoRequest {
  const RegistroVehiculoRequest({
    required this.numeroPlaca,
    required this.marcaModelo,
    required this.anio,
    required this.color,
    required this.numeroEconomico,
  });

  final String numeroPlaca;
  final String marcaModelo;
  final int anio;
  final String color;
  final String numeroEconomico;

  Map<String, dynamic> toJson() => {
        'numeroPlaca': numeroPlaca,
        'placas': numeroPlaca,
        'marcaModelo': marcaModelo,
        'anio': anio,
        'color': color,
        'numeroEconomico': numeroEconomico,
      };
}
