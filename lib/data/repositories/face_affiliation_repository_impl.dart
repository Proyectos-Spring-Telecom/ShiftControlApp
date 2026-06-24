import '../../domain/repositories/face_affiliation_repository.dart';
import '../../features/afiliar_rostro/services/face_affiliation_service.dart';
import '../models/face_affiliation_request.dart';
import '../models/face_affiliation_response.dart';

class FaceAffiliationRepositoryImpl implements FaceAffiliationRepository {
  FaceAffiliationRepositoryImpl({required FaceAffiliationService service})
      : _service = service;

  final FaceAffiliationService _service;

  @override
  Future<List<double>> validarPoseYGenerarEmbedding({
    required int sampleIndex,
    required String filename,
    required List<int> imageBytes,
  }) {
    return _service.validarPoseYGenerarEmbedding(
      sampleIndex: sampleIndex,
      filename: filename,
      imageBytes: imageBytes,
    );
  }

  @override
  Future<FaceAffiliationResponse> registrarRostro({
    required FaceAffiliationRequest request,
  }) {
    return _service.registrarRostro(request: request);
  }
}
