import 'dart:typed_data';

import '../../data/models/afiliar_rostro_operador_info.dart';
import '../../data/models/afiliar_rostro_response.dart';

/// Contrato de afiliación de rostro.
abstract class AfiliarRostroRepository {
  Future<AfiliarRostroOperadorInfo> obtenerOperadorActual();

  Future<void> validarCapturas({
    required Uint8List foto1,
    required Uint8List foto2,
  });

  Future<AfiliarRostroResponse> afiliarRostro({
    required String idUsuario,
    required Uint8List foto1,
    required Uint8List foto2,
  });
}
