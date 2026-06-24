import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../models/registro_vehiculo_request.dart';
import '../../models/registro_vehiculo_response.dart';

/// Datasource remoto para registro de vehículos (POST /api/placas).
abstract class RegistroVehiculoRemoteDatasource {
  Future<RegistroVehiculoResponse> registrar({required RegistroVehiculoRequest request});
}

class RegistroVehiculoRemoteDatasourceImpl implements RegistroVehiculoRemoteDatasource {
  RegistroVehiculoRemoteDatasourceImpl(this._client);

  final ApiClient _client;

  static const _path = '/api/placas';

  @override
  Future<RegistroVehiculoResponse> registrar({
    required RegistroVehiculoRequest request,
  }) async {
    debugPrint('RegistroVehiculoRemoteDatasource: POST $_path placa=${request.numeroPlaca}');

    try {
      final data = await _client.post(_path, body: request.toJson());
      return RegistroVehiculoResponse.fromJson(data);
    } on AuthException catch (e) {
      debugPrint(
        'RegistroVehiculoRemoteDatasource: AuthException ${e.code}: ${e.message}',
      );
      if (e.code == '401') {
        throw AuthException('Tu sesión ha expirado.', e.code);
      }
      if (e.code == '400') {
        throw const NetworkException(
          'No existe un vehículo registrado para esta placa.',
          '400',
        );
      }
      rethrow;
    } on NetworkException catch (e) {
      debugPrint(
        'RegistroVehiculoRemoteDatasource: NetworkException ${e.code}: ${e.message}',
      );
      switch (e.code) {
        case '409':
          throw const NetworkException(
            'La placa ya se encuentra afiliada.',
            '409',
          );
        case '500':
        case '503':
          throw const NetworkException(
            'No fue posible registrar el vehículo.\nIntenta nuevamente.',
            '500',
          );
        default:
          rethrow;
      }
    }
  }
}
