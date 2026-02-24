import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado del turno actual (En Turno / Turno Cerrado).
enum TurnoStatus { enTurno, turnoCerrado }

/// Provider global del estado del turno. Al cerrar el turno desde Resumen se pone
/// [TurnoStatus.turnoCerrado]; al iniciar turno (apertura) se pone [TurnoStatus.enTurno].
final turnoStatusProvider = StateProvider<TurnoStatus>((ref) => TurnoStatus.enTurno);
