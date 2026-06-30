import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/content_disposition_utils.dart';
import '../../models/reporte_turno_pdf_result.dart';

/// Fuente de datos remota para reportes de turno.
abstract interface class ReportesRemoteDatasource {
  Future<Map<String, dynamic>> enviarReporteTurno({
    required int turnoId,
    required String destinatario,
    String? asunto,
  });

  Future<ReporteTurnoPdfResult> descargarReporteTurnoPdf({required int turnoId});
}

class ReportesRemoteDatasourceImpl implements ReportesRemoteDatasource {
  ReportesRemoteDatasourceImpl(this._client);

  final ApiClient _client;

  static const _enviarTimeout = Duration(seconds: 30);
  static const _descargarTimeout = Duration(seconds: 60);

  Never _rethrowDescargaPdf(AppException e) {
    switch (e.code) {
      case '401':
        throw const AuthException('La sesión ha expirado.', '401');
      case '403':
        throw const AuthException(
          'No tienes permisos para descargar este reporte.',
          '403',
        );
      case '404':
        throw const NetworkException(
          'No fue posible encontrar el reporte del turno.',
          '404',
        );
      case '500':
        throw const NetworkException(
          'No fue posible generar el reporte.',
          '500',
        );
      default:
        throw e;
    }
  }

  @override
  Future<ReporteTurnoPdfResult> descargarReporteTurnoPdf({
    required int turnoId,
  }) async {
    final path = '/api/reportes/turno/$turnoId';
    debugPrint('ReportesRemoteDatasource: GET $path (PDF)');

    try {
      final response = await _client
          .getBytes(path)
          .timeout(
            _descargarTimeout,
            onTimeout: () {
              throw const NetworkException(
                'La solicitud tardó demasiado. Intenta nuevamente.',
                '408',
              );
            },
          );

      final fileName = fileNameFromContentDisposition(
        response.headers['content-disposition'],
      );

      return ReporteTurnoPdfResult(
        bytes: Uint8List.fromList(response.bytes),
        fileName: fileName,
      );
    } on AuthException catch (e) {
      debugPrint(
        'ReportesRemoteDatasource: AuthException ${e.code}: ${e.message}',
      );
      _rethrowDescargaPdf(e);
    } on NetworkException catch (e) {
      debugPrint(
        'ReportesRemoteDatasource: NetworkException ${e.code}: ${e.message}',
      );
      _rethrowDescargaPdf(e);
    }
  }

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
