/// Payload de POST /api/turnos/luces-vehiculo.
/// Siempre incluye las 9 luces (0 = no funciona, 1 = funciona).
class RegistrarLucesVehiculoRequest {
  const RegistrarLucesVehiculoRequest({
    required this.idBitacoraVehiculo,
    required this.altas,
    required this.cortas,
    required this.intermitentesDelanteras,
    required this.direccionalesDelanteras,
    required this.intermitentesLaterales,
    required this.intermitentesTraseras,
    required this.direccionalesTraseras,
    required this.reversa,
    required this.freno,
  });

  final int idBitacoraVehiculo;
  final int altas;
  final int cortas;
  final int intermitentesDelanteras;
  final int direccionalesDelanteras;
  final int intermitentesLaterales;
  final int intermitentesTraseras;
  final int direccionalesTraseras;
  final int reversa;
  final int freno;

  /// Convierte estado UI (true = funciona) a valores backend 0/1.
  factory RegistrarLucesVehiculoRequest.fromEstadoUi({
    required int idBitacoraVehiculo,
    required Map<String, bool> lucesUi,
  }) {
    int valor(String uiKey) => (lucesUi[uiKey] ?? false) ? 1 : 0;

    return RegistrarLucesVehiculoRequest(
      idBitacoraVehiculo: idBitacoraVehiculo,
      altas: valor('carretera'),
      cortas: valor('cruce'),
      intermitentesDelanteras: valor('intermitentes_delanteras'),
      direccionalesDelanteras: valor('direccionales_delanteras'),
      intermitentesLaterales: valor('intermitentes_laterales'),
      intermitentesTraseras: valor('intermitentes_traseras'),
      direccionalesTraseras: valor('direccionales_traseras'),
      reversa: valor('reversa'),
      freno: valor('freno'),
    );
  }

  Map<String, dynamic> toJson() => {
        'idBitacoraVehiculo': idBitacoraVehiculo,
        'altas': altas,
        'cortas': cortas,
        'intermitentesDelanteras': intermitentesDelanteras,
        'direccionalesDelanteras': direccionalesDelanteras,
        'intermitentesLaterales': intermitentesLaterales,
        'intermitentesTraseras': intermitentesTraseras,
        'direccionalesTraseras': direccionalesTraseras,
        'reversa': reversa,
        'freno': freno,
      };
}
