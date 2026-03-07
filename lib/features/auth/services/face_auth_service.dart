import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/datasources/remote/face_auth_remote_datasource.dart';

/// Resultado de los pasos 1 y 2 (login + me).
class FaceAuthCredentialsResult {
  const FaceAuthCredentialsResult({
    required this.token,
    required this.idCliente,
    this.usuario,
  });
  final String token;
  final String idCliente;
  /// Usuario/correo del /auth/me (para guardar en sesión).
  final String? usuario;
}

/// Servicio que orquesta los 6 pasos del flujo Face Auth.
class FaceAuthService {
  FaceAuthService(this._datasource);

  final FaceAuthRemoteDatasource _datasource;

  /// Pasos 1 y 2: login y obtener idCliente.
  Future<FaceAuthCredentialsResult> loginAndGetIdCliente(String usuario, String contrasena) async {
    if (usuario.trim().isEmpty || contrasena.isEmpty) {
      throw const AuthException('Usuario y contraseña son obligatorios.');
    }
    final loginResult = await _datasource.login(usuario.trim(), contrasena);
    final meResult = await _datasource.me(loginResult.accessToken);
    return FaceAuthCredentialsResult(
      token: loginResult.accessToken,
      idCliente: meResult.idCliente,
      usuario: meResult.usuario,
    );
  }

  /// Pasos 4, 5 y 6: liveness-check → embed → validateFace.
  /// [capture1] y [capture2] son las dos imágenes en bytes.
  Future<FaceAuthValidateResult> livenessEmbedAndValidateFace({
    required String token,
    required String idCliente,
    required Uint8List capture1,
    required Uint8List capture2,
  }) async {
    final liveness = await _datasource.livenessCheck(
      token,
      capture1.toList(),
      capture2.toList(),
    );
    if (!liveness.passed) {
      throw AuthException(
        liveness.reason ?? 'Prueba de vida no superada.',
        'liveness_failed',
      );
    }
    final embedding = await _datasource.embed(token, capture2.toList());
    if (embedding.length != 512) {
      debugPrint('! FaceAuthService: embedding length ${embedding.length}, expected 512');
    }
    return _datasource.validateFace(token, idCliente, embedding);
  }
}
