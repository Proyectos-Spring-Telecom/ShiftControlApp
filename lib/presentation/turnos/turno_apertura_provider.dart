import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Datos del turno creado en Apertura. Se usan en los pasos siguientes del checklist.
class TurnoAperturaState {
  const TurnoAperturaState({
    this.idTurno,
    this.idBitacoraApertura,
    this.placa,
    this.numeroEconomico,
    this.anio,
    this.modeloNombre,
    this.marcaNombre,
  });

  final int? idTurno;
  final int? idBitacoraApertura;
  final String? placa;
  final String? numeroEconomico;
  final int? anio;
  final String? modeloNombre;
  final String? marcaNombre;
}

final turnoAperturaProvider = StateProvider<TurnoAperturaState>(
  (ref) => const TurnoAperturaState(),
);
