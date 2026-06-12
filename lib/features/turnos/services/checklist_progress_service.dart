import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

class ChecklistProgress {
  const ChecklistProgress({
    this.idTurno,
    this.idBitacoraApertura,
    this.pasoActual = 1,
    this.completo = false,
    this.placa,
    this.numeroEconomico,
    this.modeloNombre,
    this.marcaNombre,
    this.anio,
    this.esCierre = false,
    this.idBitacoraCierre,
    this.duracion,
  });

  final int? idTurno;
  final int? idBitacoraApertura;
  final int pasoActual;
  final bool completo;
  final String? placa;
  final String? numeroEconomico;
  final String? modeloNombre;
  final String? marcaNombre;
  final int? anio;
  final bool esCierre;
  final int? idBitacoraCierre;
  final int? duracion;

  bool get tieneProgresoIncompleto {
    if (completo) return false;
    if (esCierre) {
      return idTurno != null && idBitacoraCierre != null;
    }
    return idTurno != null && idBitacoraApertura != null;
  }
}

class ChecklistProgressService {
  ChecklistProgressService(this._prefs);

  final SharedPreferences _prefs;

  Future<void> guardarInicio({
    required int idTurno,
    required int idBitacoraApertura,
    String? placa,
    String? numeroEconomico,
    String? modeloNombre,
    String? marcaNombre,
    int? anio,
  }) async {
    await _prefs.setInt(AppConstants.keyChecklistIdTurno, idTurno);
    await _prefs.setInt(
      AppConstants.keyChecklistIdBitacoraApertura,
      idBitacoraApertura,
    );
    await _prefs.setInt(AppConstants.keyChecklistPasoActual, 2);
    await _prefs.setBool(AppConstants.keyChecklistCompleto, false);
    await _prefs.setBool(AppConstants.keyChecklistEsCierre, false);
    if (placa != null) {
      await _prefs.setString(AppConstants.keyChecklistPlaca, placa);
    }
    if (numeroEconomico != null) {
      await _prefs.setString(
        AppConstants.keyChecklistNumeroEconomico,
        numeroEconomico,
      );
    }
    if (modeloNombre != null) {
      await _prefs.setString(
        AppConstants.keyChecklistModeloNombre,
        modeloNombre,
      );
    }
    if (marcaNombre != null) {
      await _prefs.setString(
        AppConstants.keyChecklistMarcaNombre,
        marcaNombre,
      );
    }
    if (anio != null) {
      await _prefs.setInt(AppConstants.keyChecklistAnio, anio);
    }
  }

  Future<void> actualizarPaso(int paso) async {
    await _prefs.setInt(AppConstants.keyChecklistPasoActual, paso);
  }

  ChecklistProgress? leerProgreso() {
    final idTurno = _prefs.getInt(AppConstants.keyChecklistIdTurno);
    if (idTurno == null) return null;

    final esCierre = _prefs.getBool(AppConstants.keyChecklistEsCierre) ?? false;
    if (esCierre) {
      final idBitacoraCierre =
          _prefs.getInt(AppConstants.keyChecklistIdBitacoraCierre);
      if (idBitacoraCierre == null) return null;

      return ChecklistProgress(
        idTurno: idTurno,
        pasoActual: _prefs.getInt(AppConstants.keyChecklistPasoActual) ?? 1,
        completo: _prefs.getBool(AppConstants.keyChecklistCompleto) ?? false,
        esCierre: true,
        idBitacoraCierre: idBitacoraCierre,
        duracion: _prefs.getInt(AppConstants.keyChecklistDuracionCierre),
      );
    }

    final idBitacora = _prefs.getInt(AppConstants.keyChecklistIdBitacoraApertura);
    if (idBitacora == null) return null;

    return ChecklistProgress(
      idTurno: idTurno,
      idBitacoraApertura: idBitacora,
      pasoActual: _prefs.getInt(AppConstants.keyChecklistPasoActual) ?? 1,
      completo: _prefs.getBool(AppConstants.keyChecklistCompleto) ?? false,
      placa: _prefs.getString(AppConstants.keyChecklistPlaca),
      numeroEconomico: _prefs.getString(AppConstants.keyChecklistNumeroEconomico),
      modeloNombre: _prefs.getString(AppConstants.keyChecklistModeloNombre),
      marcaNombre: _prefs.getString(AppConstants.keyChecklistMarcaNombre),
      anio: _prefs.getInt(AppConstants.keyChecklistAnio),
    );
  }

  /// Persiste datos tras cierre geográfico (PATCH /api/turnos).
  Future<void> guardarCierreGeografico({
    required int idTurno,
    required int idBitacoraCierre,
    required int duracion,
  }) async {
    await _prefs.setInt(AppConstants.keyChecklistIdTurno, idTurno);
    await _prefs.setInt(AppConstants.keyChecklistIdBitacoraCierre, idBitacoraCierre);
    await _prefs.setInt(AppConstants.keyChecklistDuracionCierre, duracion);
    await _prefs.setInt(AppConstants.keyChecklistPasoActual, 2);
    await _prefs.setBool(AppConstants.keyChecklistCompleto, false);
    await _prefs.setBool(AppConstants.keyChecklistEsCierre, true);
  }

  Future<void> limpiar() async {
    await _prefs.remove(AppConstants.keyChecklistIdTurno);
    await _prefs.remove(AppConstants.keyChecklistIdBitacoraApertura);
    await _prefs.remove(AppConstants.keyChecklistPasoActual);
    await _prefs.remove(AppConstants.keyChecklistCompleto);
    await _prefs.remove(AppConstants.keyChecklistPlaca);
    await _prefs.remove(AppConstants.keyChecklistNumeroEconomico);
    await _prefs.remove(AppConstants.keyChecklistModeloNombre);
    await _prefs.remove(AppConstants.keyChecklistMarcaNombre);
    await _prefs.remove(AppConstants.keyChecklistAnio);
    await _prefs.remove(AppConstants.keyChecklistIdBitacoraCierre);
    await _prefs.remove(AppConstants.keyChecklistDuracionCierre);
    await _prefs.remove(AppConstants.keyChecklistEsCierre);
  }
}
