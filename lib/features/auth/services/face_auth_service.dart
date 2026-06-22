import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/datasources/remote/face_auth_remote_datasource.dart';
import '../../../data/models/user_model.dart';

/// Servicio que orquesta el flujo Face Auth vía BFF ShiftControl.
class FaceAuthService {
  FaceAuthService(this._datasource);

  final FaceAuthRemoteDatasource _datasource;

  /// liveness-check → embed (captura2) → validateFace → GET /api/login/me.
  Future<({FaceAuthValidateSessionResult session, UserModel user})>
      livenessEmbedAndValidateFace({
    required Uint8List capture1,
    required Uint8List capture2,
    double? latitud,
    double? longitud,
  }) async {
    final embedJwt = await _datasource.obtainEmbedServiceJwt();

    final liveness = await _datasource.livenessCheck(
      embedJwt,
      capture1.toList(),
      capture2.toList(),
    );
    if (!liveness.passed) {
      throw AuthException(
        liveness.reason ?? 'Prueba de vida no superada.',
        'liveness_failed',
      );
    }

    final embedding = await _datasource.embed(embedJwt, capture2.toList());
    if (embedding.isEmpty) {
      throw const AuthException('El embedding está vacío.', 'invalid_embedding');
    }
    if (embedding.length != 512) {
      debugPrint('Embedding length inválido: ${embedding.length}');
      throw AuthException(
        'El embedding debe tener 512 elementos, se recibieron ${embedding.length}.',
        'invalid_embedding',
      );
    }

    final session = await _datasource.validateFace(
      embedding,
      latitud: latitud,
      longitud: longitud,
    );

    final user = await _datasource.fetchLoginMe(session.token);
    return (session: session, user: user);
  }
}
