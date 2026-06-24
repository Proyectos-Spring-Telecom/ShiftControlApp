import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../../data/datasources/remote/afiliar_rostro_operador_datasource.dart';
import '../../data/datasources/remote/afiliar_rostro_remote_datasource.dart';
import '../../data/models/afiliar_rostro_operador_info.dart';
import '../../data/repositories/afiliar_rostro_repository_impl.dart';
import '../../domain/repositories/afiliar_rostro_repository.dart';
import '../../features/afiliar_rostro/services/afiliar_rostro_service.dart';

final afiliarRostroOperadorDatasourceProvider =
    Provider<AfiliarRostroOperadorDatasource>(
  (ref) => AfiliarRostroOperadorDatasourceImpl(ref.watch(apiClientProvider)),
);

final afiliarRostroRemoteDatasourceProvider =
    Provider<AfiliarRostroRemoteDatasource>(
  (ref) => AfiliarRostroRemoteDatasourceImpl(
    tokenStorage: ref.watch(tokenStorageServiceProvider),
  ),
);

final afiliarRostroServiceProvider = Provider<AfiliarRostroService>(
  (ref) => AfiliarRostroService(
    faceAuthDatasource: ref.watch(faceAuthRemoteDatasourceProvider),
    afiliarDatasource: ref.watch(afiliarRostroRemoteDatasourceProvider),
  ),
);

final afiliarRostroRepositoryProvider = Provider<AfiliarRostroRepository>(
  (ref) => AfiliarRostroRepositoryImpl(
    operadorDatasource: ref.watch(afiliarRostroOperadorDatasourceProvider),
    service: ref.watch(afiliarRostroServiceProvider),
  ),
);

final afiliarRostroOperadorProvider =
    FutureProvider<AfiliarRostroOperadorInfo>((ref) {
  return ref.watch(afiliarRostroRepositoryProvider).obtenerOperadorActual();
});
