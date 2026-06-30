import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/models/enviar_reporte_turno_response.dart';
import '../../../data/models/reporte_turno_pdf_result.dart';
import '../../../domain/repositories/reportes_repository.dart';

/// Servicio de reportes de turno.
class ReportesService {
  ReportesService(this._repository);

  final ReportesRepository _repository;

  /// GET /api/reportes/turno/{turnoId} — PDF binario.
  Future<ReporteTurnoPdfResult> descargarReporteTurnoPdf({
    required int turnoId,
  }) async {
    debugPrint('ReportesService: descargarReporteTurnoPdf turnoId=$turnoId');
    try {
      final result = await _repository.descargarReporteTurnoPdf(turnoId: turnoId);
      debugPrint(
        'ReportesService: PDF descargado — ${result.fileName} (${result.bytes.length} bytes)',
      );
      return result;
    } on AuthException catch (e) {
      debugPrint('ReportesService: AuthException ${e.code}: ${e.message}');
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('ReportesService: NetworkException ${e.code}: ${e.message}');
      rethrow;
    }
  }

  /// POST /api/reportes/turno/{turnoId}/enviar
  Future<EnviarReporteTurnoResponse> enviarReporteTurno({
    required int turnoId,
    required String destinatario,
    String? asunto,
  }) async {
    debugPrint(
      'ReportesService: enviarReporteTurno turnoId=$turnoId destinatario=$destinatario',
    );
    try {
      final response = await _repository.enviarReporteTurno(
        turnoId: turnoId,
        destinatario: destinatario,
        asunto: asunto,
      );
      debugPrint('ReportesService: reporte enviado — ${response.message}');
      return response;
    } on AuthException catch (e) {
      debugPrint('ReportesService: AuthException ${e.code}: ${e.message}');
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('ReportesService: NetworkException ${e.code}: ${e.message}');
      if (e.code == '404') {
        throw NetworkException(
          e.message.isNotEmpty ? e.message : 'Turno no encontrado',
          '404',
        );
      }
      if (e.code == '500') {
        throw NetworkException(
          e.message.isNotEmpty ? e.message : 'No se pudo enviar el reporte',
          '500',
        );
      }
      rethrow;
    }
  }
}
