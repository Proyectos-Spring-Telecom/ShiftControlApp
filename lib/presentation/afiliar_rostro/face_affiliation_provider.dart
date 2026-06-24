import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/face_affiliation_remote_datasource.dart';
import '../../data/repositories/face_affiliation_repository_impl.dart';
import '../../domain/repositories/face_affiliation_repository.dart';
import '../../features/afiliar_rostro/services/face_affiliation_service.dart';
import '../controllers/auth_controller.dart';

final faceAffiliationRemoteDatasourceProvider =
    Provider<FaceAffiliationRemoteDatasource>(
  (ref) => FaceAffiliationRemoteDatasourceImpl(
    tokenStorage: ref.watch(tokenStorageServiceProvider),
  ),
);

final faceAffiliationServiceProvider = Provider<FaceAffiliationService>(
  (ref) => FaceAffiliationService(
    affiliationDatasource: ref.watch(faceAffiliationRemoteDatasourceProvider),
    faceAuthDatasource: ref.watch(faceAuthRemoteDatasourceProvider),
  ),
);

final faceAffiliationRepositoryProvider = Provider<FaceAffiliationRepository>(
  (ref) => FaceAffiliationRepositoryImpl(
    service: ref.watch(faceAffiliationServiceProvider),
  ),
);
