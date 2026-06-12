import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/checklist_type.dart';
import 'turno_apertura_provider.dart';
import 'turno_cierre_provider.dart';

/// Id de bitácora según el tipo de checklist (apertura o cierre).
int? idBitacoraVehiculoParaChecklist(WidgetRef ref, ChecklistType checklistType) {
  if (checklistType == ChecklistType.cierre) {
    return ref.read(turnoCierreProvider).idBitacoraCierre;
  }
  return ref.read(turnoAperturaProvider).idBitacoraApertura;
}
