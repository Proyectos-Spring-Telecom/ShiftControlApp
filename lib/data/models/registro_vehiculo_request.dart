/// DTO para futuro registro de vehículo en el BFF.
class RegistroVehiculoRequest {
  const RegistroVehiculoRequest({
    required this.numeroPlaca,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.color,
    required this.numeroEconomico,
  });

  final String numeroPlaca;
  final String marca;
  final String modelo;
  final int anio;
  final String color;
  final String numeroEconomico;

  Map<String, dynamic> toJson() => {
        'numeroPlaca': numeroPlaca,
        'marca': marca,
        'modelo': modelo,
        'anio': anio,
        'color': color,
        'economico': numeroEconomico,
      };
}
