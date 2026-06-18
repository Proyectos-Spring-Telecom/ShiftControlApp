import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';

/// Fuente de datos remota para reportes de turno.
abstract interface class ReportesRemoteDatasource {
  Future<Map<String, dynamic>> enviarReporteTurno({
    required int turnoId,
    required String destinatario,
    String? asunto,
  });
}

class ReportesRemoteDatasourceImpl implements ReportesRemoteDatasource {
  ReportesRemoteDatasourceImpl(this._client);

  final ApiClient _client;

  static const _enviarTimeout = Duration(seconds: 30);

  @override
  Future<Map<String, dynamic>> enviarReporteTurno({
    required int turnoId,
    required String destinatario,
    String? asunto,
  }) async {
    final path = '/api/reportes/turno/$turnoId/enviar';
    final body = <String, dynamic>{'destinatario': destinatario};
    final asuntoLimpio = asunto?.trim();
    if (asuntoLimpio != null && asuntoLimpio.isNotEmpty) {
      body['asunto'] = asuntoLimpio;
    }

    debugPrint('ReportesRemoteDatasource: POST $path destinatario=$destinatario');

    try {
      return await _client
          .post(path, body: body)
          .timeout(
            _enviarTimeout,
            onTimeout: () {
              throw const NetworkException(
                'La solicitud tardó demasiado. Intenta nuevamente.',
                '408',
              );
            },
          );
    } on AuthException catch (e) {
      debugPrint(
        'ReportesRemoteDatasource: AuthException ${e.code}: ${e.message}',
      );
      rethrow;
    } on NetworkException catch (e) {
      debugPrint(
        'ReportesRemoteDatasource: NetworkException ${e.code}: ${e.message}',
      );
      rethrow;
    }
  }
}
