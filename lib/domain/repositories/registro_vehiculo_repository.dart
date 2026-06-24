import '../../data/models/registro_vehiculo_request.dart';
import '../../data/models/registro_vehiculo_response.dart';

/// Contrato de persistencia remota para registro de vehículos.
abstract class RegistroVehiculoRepository {
  Future<RegistroVehiculoResponse> registrar({required RegistroVehiculoRequest request});
}
