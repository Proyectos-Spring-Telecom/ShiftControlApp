import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/remote/reportes_remote_datasource.dart';
import '../../../data/repositories/reportes_repository_impl.dart';
import '../../../domain/repositories/reportes_repository.dart';
import '../../../features/reportes/services/reportes_service.dart';
import '../../controllers/auth_controller.dart';

final reportesRemoteDatasourceProvider = Provider<ReportesRemoteDatasource>((ref) {
  return ReportesRemoteDatasourceImpl(ref.watch(apiClientProvider));
});

final reportesRepositoryProvider = Provider<ReportesRepository>((ref) {
  return ReportesRepositoryImpl(ref.watch(reportesRemoteDatasourceProvider));
});

final reportesServiceProvider = Provider<ReportesService>((ref) {
  return ReportesService(ref.watch(reportesRepositoryProvider));
});
