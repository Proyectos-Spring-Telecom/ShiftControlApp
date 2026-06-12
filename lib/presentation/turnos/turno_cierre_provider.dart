import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Datos del cierre geográfico del turno (bitácora de cierre e inspección).
class TurnoCierreState {
  const TurnoCierreState({
    this.idTurno,
    this.idBitacoraCierre,
    this.duracion,
  });

  final int? idTurno;
  final int? idBitacoraCierre;
  final int? duracion;
}

final turnoCierreProvider = StateProvider<TurnoCierreState>(
  (ref) => const TurnoCierreState(),
);
