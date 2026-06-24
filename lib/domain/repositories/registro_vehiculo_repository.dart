import '../../data/models/registro_vehiculo_request.dart';

/// Contrato de persistencia remota para registro de vehículos.
abstract class RegistroVehiculoRepository {
  Future<void> registrar({required RegistroVehiculoRequest request});
}
