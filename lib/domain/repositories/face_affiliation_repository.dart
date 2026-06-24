import '../../data/models/face_affiliation_request.dart';
import '../../data/models/face_affiliation_response.dart';

/// Contrato de repositorio para afiliación facial con embeddings.
abstract class FaceAffiliationRepository {
  Future<List<double>> validarPoseYGenerarEmbedding({
    required int sampleIndex,
    required String filename,
    required List<int> imageBytes,
  });

  Future<FaceAffiliationResponse> registrarRostro({
    required FaceAffiliationRequest request,
  });
}
