import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/remote/registro_vehiculo_remote_datasource.dart';
import '../../../data/repositories/registro_vehiculo_repository_impl.dart';
import '../../../domain/repositories/registro_vehiculo_repository.dart';
import '../../controllers/auth_controller.dart';
import 'models/registro_vehiculo_form_data.dart';

final registroVehiculoRemoteDatasourceProvider =
    Provider<RegistroVehiculoRemoteDatasource>(
  (ref) => RegistroVehiculoRemoteDatasourceImpl(
    ref.watch(apiClientProvider),
  ),
);

final registroVehiculoRepositoryProvider = Provider<RegistroVehiculoRepository>(
  (ref) => RegistroVehiculoRepositoryImpl(
    ref.watch(registroVehiculoRemoteDatasourceProvider),
  ),
);

/// Último formulario enviado correctamente (persistencia en memoria de sesión).
final registroVehiculoEnviadoProvider =
    StateProvider<RegistroVehiculoFormData?>((ref) => null);
