/// Payload para afiliación de rostro del operador.
class AfiliarRostroRequest {
  const AfiliarRostroRequest({
    required this.idUsuario,
    required this.foto1,
    required this.foto2,
  });

  final String idUsuario;
  final List<int> foto1;
  final List<int> foto2;
}
