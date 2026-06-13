import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selección de tipo de incidencia para el futuro endpoint de reporte.
class ReporteIncidenteSeleccionState {
  const ReporteIncidenteSeleccionState({
    this.idTipoIncidencia,
    this.tipoIncidencia,
  });

  final int? idTipoIncidencia;
  final String? tipoIncidencia;
}

final reporteIncidenteSeleccionProvider =
    StateProvider<ReporteIncidenteSeleccionState>(
  (ref) => const ReporteIncidenteSeleccionState(
    idTipoIncidencia: 1,
    tipoIncidencia: 'Accidente',
  ),
);

/// Id de la última incidencia registrada desde Reportar Incidencia.
final reporteIncidenteRegistradaProvider = StateProvider<int?>((ref) => null);
