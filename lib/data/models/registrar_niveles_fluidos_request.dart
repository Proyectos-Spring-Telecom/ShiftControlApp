/// Payload de POST /api/turnos/niveles-fluidos.
/// Porcentajes enteros en rango 0–100.
class RegistrarNivelesFluidosRequest {
  const RegistrarNivelesFluidosRequest({
    required this.idBitacoraVehiculo,
    required this.gasolina,
    required this.aceite,
    required this.bateria,
    required this.anticongelante,
    required this.liquidoFrenos,
  });

  final int idBitacoraVehiculo;
  final int gasolina;
  final int aceite;
  final int bateria;
  final int anticongelante;
  final int liquidoFrenos;

  /// Convierte valores UI (0.0–1.0) a porcentajes backend (0–100).
  factory RegistrarNivelesFluidosRequest.fromNivelesUi({
    required int idBitacoraVehiculo,
    required Map<String, double> nivelesUi,
  }) {
    int porcentaje(String uiKey) {
      final fraccion = nivelesUi[uiKey] ?? 0;
      return (fraccion * 100).round().clamp(0, 100);
    }

    return RegistrarNivelesFluidosRequest(
      idBitacoraVehiculo: idBitacoraVehiculo,
      gasolina: porcentaje('gasolina'),
      aceite: porcentaje('aceite'),
      bateria: porcentaje('electrolito'),
      anticongelante: porcentaje('anticongelante'),
      liquidoFrenos: porcentaje('liquido_frenos'),
    );
  }

  Map<String, dynamic> toJson() => {
        'idBitacoraVehiculo': idBitacoraVehiculo,
        'gasolina': gasolina,
        'aceite': aceite,
        'bateria': bateria,
        'anticongelante': anticongelante,
        'liquidoFrenos': liquidoFrenos,
      };
}
