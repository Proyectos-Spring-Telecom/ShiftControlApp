import '../../../core/network/api_client.dart';
import '../../models/afiliar_rostro_operador_info.dart';

/// Fuente remota para datos del operador en Afiliar Rostro.
abstract class AfiliarRostroOperadorDatasource {
  Future<AfiliarRostroOperadorInfo> obtenerOperadorActual();
}

class AfiliarRostroOperadorDatasourceImpl implements AfiliarRostroOperadorDatasource {
  AfiliarRostroOperadorDatasourceImpl(this._client);

  final ApiClient _client;

  static const _pathLoginMe = '/api/login/me';

  @override
  Future<AfiliarRostroOperadorInfo> obtenerOperadorActual() async {
    final data = await _client.get(_pathLoginMe);
    return AfiliarRostroOperadorInfo.fromLoginMeJson(data);
  }
}
