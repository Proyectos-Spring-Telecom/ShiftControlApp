import 'dart:typed_data';

import '../../domain/repositories/afiliar_rostro_repository.dart';
import '../../features/afiliar_rostro/services/afiliar_rostro_service.dart';
import '../datasources/remote/afiliar_rostro_operador_datasource.dart';
import '../models/afiliar_rostro_operador_info.dart';
import '../models/afiliar_rostro_response.dart';

class AfiliarRostroRepositoryImpl implements AfiliarRostroRepository {
  AfiliarRostroRepositoryImpl({
    required AfiliarRostroOperadorDatasource operadorDatasource,
    required AfiliarRostroService service,
  })  : _operadorDatasource = operadorDatasource,
        _service = service;

  final AfiliarRostroOperadorDatasource _operadorDatasource;
  final AfiliarRostroService _service;

  @override
  Future<AfiliarRostroOperadorInfo> obtenerOperadorActual() {
    return _operadorDatasource.obtenerOperadorActual();
  }

  @override
  Future<void> validarCapturas({
    required Uint8List foto1,
    required Uint8List foto2,
  }) {
    return _service.validarCapturas(foto1: foto1, foto2: foto2);
  }

  @override
  Future<AfiliarRostroResponse> afiliarRostro({
    required String idUsuario,
    required Uint8List foto1,
    required Uint8List foto2,
  }) {
    return _service.afiliarRostro(
      idUsuario: idUsuario,
      foto1: foto1,
      foto2: foto2,
    );
  }
}
