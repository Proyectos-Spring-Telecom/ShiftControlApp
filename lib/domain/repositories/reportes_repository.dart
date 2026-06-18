import '../../data/models/enviar_reporte_turno_response.dart';

/// Contrato del repositorio de reportes.
abstract interface class ReportesRepository {
  Future<EnviarReporteTurnoResponse> enviarReporteTurno({
    required int turnoId,
    required String destinatario,
    String? asunto,
  });
}
