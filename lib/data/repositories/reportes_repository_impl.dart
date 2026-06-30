import '../../data/models/enviar_reporte_turno_response.dart';
import '../../data/models/reporte_turno_pdf_result.dart';
import '../../domain/repositories/reportes_repository.dart';
import '../datasources/remote/reportes_remote_datasource.dart';

class ReportesRepositoryImpl implements ReportesRepository {
  ReportesRepositoryImpl(this._remote);

  final ReportesRemoteDatasource _remote;

  @override
  Future<EnviarReporteTurnoResponse> enviarReporteTurno({
    required int turnoId,
    required String destinatario,
    String? asunto,
  }) async {
    final data = await _remote.enviarReporteTurno(
      turnoId: turnoId,
      destinatario: destinatario,
      asunto: asunto,
    );
    return EnviarReporteTurnoResponse.fromJson(data);
  }

  @override
  Future<ReporteTurnoPdfResult> descargarReporteTurnoPdf({
    required int turnoId,
  }) {
    return _remote.descargarReporteTurnoPdf(turnoId: turnoId);
  }
}
