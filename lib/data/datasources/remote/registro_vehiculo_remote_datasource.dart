import '../../../core/errors/app_exception.dart';
import '../../models/registro_vehiculo_request.dart';

/// Datasource remoto para registro de vehículos.
/// Pendiente de endpoint definitivo en el BFF ShiftControl.
abstract class RegistroVehiculoRemoteDatasource {
  Future<void> registrar({required RegistroVehiculoRequest request});
}

class RegistroVehiculoRemoteDatasourceImpl implements RegistroVehiculoRemoteDatasource {
  @override
  Future<void> registrar({required RegistroVehiculoRequest request}) async {
    throw const NetworkException(
      'El registro de vehículos aún no está disponible en el servidor.',
      'registro_vehiculo_no_disponible',
    );
  }
}
