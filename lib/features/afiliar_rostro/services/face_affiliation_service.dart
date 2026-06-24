import '../../../core/errors/app_exception.dart';
import '../../../data/datasources/remote/face_affiliation_remote_datasource.dart';
import '../../../data/datasources/remote/face_auth_remote_datasource.dart';
import '../../../data/models/face_affiliation_request.dart';
import '../../../data/models/face_affiliation_response.dart';

/// Orquesta validate-pose, embed (mismo mecanismo que login) y POST /api/rostros.
class FaceAffiliationService {
  FaceAffiliationService({
    required FaceAffiliationRemoteDatasource affiliationDatasource,
    required FaceAuthRemoteDatasource faceAuthDatasource,
  })  : _affiliationDatasource = affiliationDatasource,
        _faceAuthDatasource = faceAuthDatasource;

  final FaceAffiliationRemoteDatasource _affiliationDatasource;
  final FaceAuthRemoteDatasource _faceAuthDatasource;

  Future<List<double>> validarPoseYGenerarEmbedding({
    required int sampleIndex,
    required String filename,
    required List<int> imageBytes,
  }) async {
    final pose = await _affiliationDatasource.validatePose(
      sampleIndex: sampleIndex,
      imageBytes: imageBytes,
      filename: filename,
    );

    if (!pose.valid) {
      throw AuthException(
        pose.message?.isNotEmpty == true
            ? pose.message!
            : 'La pose del rostro no es válida. Intente nuevamente.',
        'pose_invalid',
      );
    }

    final embedJwt = await _faceAuthDatasource.obtainEmbedServiceJwt();
    final embedding = await _faceAuthDatasource.embed(embedJwt, imageBytes);

    if (embedding.length != 512) {
      throw AuthException(
        'El embedding debe tener 512 elementos, se recibieron ${embedding.length}.',
        '400',
      );
    }

    return embedding;
  }

  Future<FaceAffiliationResponse> registrarRostro({
    required FaceAffiliationRequest request,
  }) async {
    _validarDatosPersonales(
      nombre: request.nombre,
      paterno: request.paterno,
      materno: request.materno,
      telefono: request.telefono,
    );

    if (request.embeddingsList.length != 3) {
      throw const AuthException(
        'Se requieren exactamente 3 embeddings para afiliar el rostro.',
        '400',
      );
    }

    for (var i = 0; i < request.embeddingsList.length; i++) {
      final embedding = request.embeddingsList[i];
      if (embedding.length != 512) {
        throw AuthException(
          'El embedding ${i + 1} debe tener 512 elementos, se recibieron ${embedding.length}.',
          '400',
        );
      }
    }

    return _affiliationDatasource.registrarRostro(request: request);
  }

  void _validarDatosPersonales({
    required String nombre,
    required String paterno,
    required String materno,
    required String telefono,
  }) {
    if (nombre.trim().isEmpty) {
      throw const AuthException('El nombre es obligatorio.', '400');
    }
    if (paterno.trim().isEmpty) {
      throw const AuthException('El apellido paterno es obligatorio.', '400');
    }
    if (materno.trim().isEmpty) {
      throw const AuthException('El apellido materno es obligatorio.', '400');
    }
    final tel = telefono.trim();
    if (tel.isEmpty) {
      throw const AuthException('El teléfono es obligatorio.', '400');
    }
    if (!RegExp(r'^\d{10}$').hasMatch(tel)) {
      throw const AuthException(
        'El teléfono debe contener exactamente 10 dígitos.',
        '400',
      );
    }
  }
}
