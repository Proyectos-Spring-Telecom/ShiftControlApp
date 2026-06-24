import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../../data/datasources/remote/face_auth_remote_datasource.dart';
import '../../../data/models/afiliar_rostro_request.dart';
import '../../../data/models/afiliar_rostro_response.dart';
import '../../../data/datasources/remote/afiliar_rostro_remote_datasource.dart';

/// Orquesta validación de liveness y afiliación de rostro.
class AfiliarRostroService {
  AfiliarRostroService({
    required FaceAuthRemoteDatasource faceAuthDatasource,
    required AfiliarRostroRemoteDatasource afiliarDatasource,
  })  : _faceAuthDatasource = faceAuthDatasource,
        _afiliarDatasource = afiliarDatasource;

  final FaceAuthRemoteDatasource _faceAuthDatasource;
  final AfiliarRostroRemoteDatasource _afiliarDatasource;

  Future<void> validarCapturas({
    required Uint8List foto1,
    required Uint8List foto2,
  }) async {
    final embedJwt = await _faceAuthDatasource.obtainEmbedServiceJwt();
    final liveness = await _faceAuthDatasource.livenessCheck(
      embedJwt,
      foto1.toList(),
      foto2.toList(),
    );
    if (!liveness.passed) {
      throw AuthException(
        liveness.reason ?? 'La validación facial no fue exitosa.',
        'liveness_failed',
      );
    }
  }

  Future<AfiliarRostroResponse> afiliarRostro({
    required String idUsuario,
    required Uint8List foto1,
    required Uint8List foto2,
  }) {
    return _afiliarDatasource.afiliar(
      request: AfiliarRostroRequest(
        idUsuario: idUsuario,
        foto1: foto1.toList(),
        foto2: foto2.toList(),
      ),
    );
  }
}
