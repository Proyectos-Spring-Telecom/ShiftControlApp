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

  Future<void> _escribirDatosVehiculoEnPrefs({
    String? placa,
    String? numeroEconomico,
    String? modeloNombre,
    String? marcaNombre,
    int? anio,
  }) async {
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

  ChecklistProgress? _leerDatosVehiculoDesdePrefs() {
    final placa = _prefs.getString(AppConstants.keyChecklistPlaca);
    final numeroEconomico =
        _prefs.getString(AppConstants.keyChecklistNumeroEconomico);
    final modeloNombre =
        _prefs.getString(AppConstants.keyChecklistModeloNombre);
    final marcaNombre = _prefs.getString(AppConstants.keyChecklistMarcaNombre);
    final anio = _prefs.getInt(AppConstants.keyChecklistAnio);
    if (placa == null &&
        numeroEconomico == null &&
        modeloNombre == null &&
        marcaNombre == null &&
        anio == null) {
      return null;
    }
    return ChecklistProgress(
      placa: placa,
      numeroEconomico: numeroEconomico,
      modeloNombre: modeloNombre,
      marcaNombre: marcaNombre,
      anio: anio,
    );
  }

  /// Datos del vehículo guardados en apertura (SharedPreferences).
  ChecklistProgress? leerDatosVehiculo() => _leerDatosVehiculoDesdePrefs();

  /// Reutiliza las mismas claves de [guardarInicio] sin crear almacenamiento nuevo.
  Future<void> persistirDatosVehiculo({
    String? placa,
    String? numeroEconomico,
    String? modeloNombre,
    String? marcaNombre,
    int? anio,
  }) =>
      _escribirDatosVehiculoEnPrefs(
        placa: placa,
        numeroEconomico: numeroEconomico,
        modeloNombre: modeloNombre,
        marcaNombre: marcaNombre,
        anio: anio,
      );

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
    await _escribirDatosVehiculoEnPrefs(
      placa: placa,
      numeroEconomico: numeroEconomico,
      modeloNombre: modeloNombre,
      marcaNombre: marcaNombre,
      anio: anio,
    );
  }

  Future<void> actualizarPaso(int paso) async {
    await _prefs.setInt(AppConstants.keyChecklistPasoActual, paso);
  }

  ChecklistProgress? leerProgreso() {
    final idTurno = _prefs.getInt(AppConstants.keyChecklistIdTurno);
    if (idTurno == null) return null;

    final esCierre = _prefs.getBool(AppConstants.keyChecklistEsCierre) ?? false;
    final datosVehiculo = _leerDatosVehiculoDesdePrefs();
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
        placa: datosVehiculo?.placa,
        numeroEconomico: datosVehiculo?.numeroEconomico,
        modeloNombre: datosVehiculo?.modeloNombre,
        marcaNombre: datosVehiculo?.marcaNombre,
        anio: datosVehiculo?.anio,
      );
    }

    final idBitacora = _prefs.getInt(AppConstants.keyChecklistIdBitacoraApertura);
    if (idBitacora == null) return null;

    return ChecklistProgress(
      idTurno: idTurno,
      idBitacoraApertura: idBitacora,
      pasoActual: _prefs.getInt(AppConstants.keyChecklistPasoActual) ?? 1,
      completo: _prefs.getBool(AppConstants.keyChecklistCompleto) ?? false,
      placa: datosVehiculo?.placa,
      numeroEconomico: datosVehiculo?.numeroEconomico,
      modeloNombre: datosVehiculo?.modeloNombre,
      marcaNombre: datosVehiculo?.marcaNombre,
      anio: datosVehiculo?.anio,
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

  Future<void> limpiar({bool preservarDatosVehiculo = false}) async {
    await _prefs.remove(AppConstants.keyChecklistIdTurno);
    await _prefs.remove(AppConstants.keyChecklistIdBitacoraApertura);
    await _prefs.remove(AppConstants.keyChecklistPasoActual);
    await _prefs.remove(AppConstants.keyChecklistCompleto);
    if (!preservarDatosVehiculo) {
      await _prefs.remove(AppConstants.keyChecklistPlaca);
      await _prefs.remove(AppConstants.keyChecklistNumeroEconomico);
      await _prefs.remove(AppConstants.keyChecklistModeloNombre);
      await _prefs.remove(AppConstants.keyChecklistMarcaNombre);
      await _prefs.remove(AppConstants.keyChecklistAnio);
    }
    await _prefs.remove(AppConstants.keyChecklistIdBitacoraCierre);
    await _prefs.remove(AppConstants.keyChecklistDuracionCierre);
    await _prefs.remove(AppConstants.keyChecklistEsCierre);
  }
}
