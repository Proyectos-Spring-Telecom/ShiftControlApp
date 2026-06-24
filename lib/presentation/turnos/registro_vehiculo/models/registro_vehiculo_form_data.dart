/// Datos del formulario de registro de vehículo listos para futura integración API.
class RegistroVehiculoFormData {
  const RegistroVehiculoFormData({
    required this.numeroPlaca,
    required this.marcaModelo,
    required this.anio,
    required this.color,
    required this.numeroEconomico,
  });

  final String numeroPlaca;
  final String marcaModelo;
  final String anio;
  final String color;
  final String numeroEconomico;
}
