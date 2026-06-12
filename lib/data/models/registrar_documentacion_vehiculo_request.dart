/// Payload de POST /api/turnos/documentacion-vehiculo.
/// Siempre incluye los 5 documentos (0 = faltante/vencido, 1 = presente/vigente).
class RegistrarDocumentacionVehiculoRequest {
  const RegistrarDocumentacionVehiculoRequest({
    required this.idBitacoraVehiculo,
    required this.bitacoraVehicular,
    required this.certificadoEcologico,
    required this.polizaSeguro,
    required this.tarjetaCirculacion,
    required this.verificacion,
  });

  final int idBitacoraVehiculo;
  final int bitacoraVehicular;
  final int certificadoEcologico;
  final int polizaSeguro;
  final int tarjetaCirculacion;
  final int verificacion;

  /// Convierte estado UI (true = vigente/presente) a valores backend 0/1.
  factory RegistrarDocumentacionVehiculoRequest.fromEstadoUi({
    required int idBitacoraVehiculo,
    required Map<String, bool> documentosUi,
  }) {
    int valor(String uiKey) => (documentosUi[uiKey] ?? false) ? 1 : 0;

    return RegistrarDocumentacionVehiculoRequest(
      idBitacoraVehiculo: idBitacoraVehiculo,
      bitacoraVehicular: valor('bitacora'),
      certificadoEcologico: valor('certificado_ecologico'),
      polizaSeguro: valor('poliza_seguro'),
      tarjetaCirculacion: valor('tarjeta_circulacion'),
      verificacion: valor('verificacion'),
    );
  }

  Map<String, dynamic> toJson() => {
        'idBitacoraVehiculo': idBitacoraVehiculo,
        'bitacoraVehicular': bitacoraVehicular,
        'certificadoEcologico': certificadoEcologico,
        'polizaSeguro': polizaSeguro,
        'tarjetaCirculacion': tarjetaCirculacion,
        'verificacion': verificacion,
      };
}
