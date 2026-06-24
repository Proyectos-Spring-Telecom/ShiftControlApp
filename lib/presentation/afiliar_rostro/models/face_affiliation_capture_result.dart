/// Resultado del flujo FaceAffiliationCapturePage.
class FaceAffiliationCaptureResult {
  const FaceAffiliationCaptureResult({
    this.rostroId,
    this.yaRegistrado = false,
    this.mensaje,
  });

  final int? rostroId;
  final bool yaRegistrado;
  final String? mensaje;

  factory FaceAffiliationCaptureResult.exitoso({required int rostroId}) {
    return FaceAffiliationCaptureResult(rostroId: rostroId);
  }

  factory FaceAffiliationCaptureResult.conflictoRegistro({String? mensaje}) {
    return FaceAffiliationCaptureResult(yaRegistrado: true, mensaje: mensaje);
  }
}
