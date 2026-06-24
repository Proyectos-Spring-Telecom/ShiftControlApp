import '../../domain/repositories/registro_vehiculo_repository.dart';
import '../datasources/remote/registro_vehiculo_remote_datasource.dart';
import '../models/registro_vehiculo_request.dart';

class RegistroVehiculoRepositoryImpl implements RegistroVehiculoRepository {
  RegistroVehiculoRepositoryImpl(this._remoteDatasource);

  final RegistroVehiculoRemoteDatasource _remoteDatasource;

  @override
  Future<void> registrar({required RegistroVehiculoRequest request}) {
    return _remoteDatasource.registrar(request: request);
  }
}
