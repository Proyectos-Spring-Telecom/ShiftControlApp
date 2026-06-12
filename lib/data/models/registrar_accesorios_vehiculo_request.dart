/// Payload de POST /api/turnos/accesorios-vehiculo.
/// Siempre incluye los 9 accesorios (0 = no presente, 1 = presente).
class RegistrarAccesoriosVehiculoRequest {
  const RegistrarAccesoriosVehiculoRequest({
    required this.idBitacoraVehiculo,
    required this.limpiaparabrisas,
    required this.aguas,
    required this.extintor,
    required this.tringulosSeguridad,
    required this.stereo,
    required this.tapetes,
    required this.herramienta,
    required this.refaccion,
    required this.impermeable,
  });

  final int idBitacoraVehiculo;
  final int limpiaparabrisas;
  final int aguas;
  final int extintor;
  final int tringulosSeguridad;
  final int stereo;
  final int tapetes;
  final int herramienta;
  final int refaccion;
  final int impermeable;

  /// Convierte estado UI (true = presente) a valores backend 0/1.
  factory RegistrarAccesoriosVehiculoRequest.fromEstadoUi({
    required int idBitacoraVehiculo,
    required Map<String, bool> accesoriosUi,
  }) {
    int valor(String uiKey) => (accesoriosUi[uiKey] ?? false) ? 1 : 0;

    return RegistrarAccesoriosVehiculoRequest(
      idBitacoraVehiculo: idBitacoraVehiculo,
      limpiaparabrisas: valor('limpiadores'),
      aguas: valor('aguas'),
      extintor: valor('extintor'),
      tringulosSeguridad: valor('triangulos'),
      stereo: valor('radio'),
      tapetes: valor('tapetes'),
      herramienta: valor('herramientas'),
      refaccion: valor('llanta_refaccion'),
      impermeable: valor('impermeable'),
    );
  }

  Map<String, dynamic> toJson() => {
        'idBitacoraVehiculo': idBitacoraVehiculo,
        'limpiaparabrisas': limpiaparabrisas,
        'aguas': aguas,
        'extintor': extintor,
        'tringulosSeguridad': tringulosSeguridad,
        'stereo': stereo,
        'tapetes': tapetes,
        'herramienta': herramienta,
        'refaccion': refaccion,
        'impermeable': impermeable,
      };
}
