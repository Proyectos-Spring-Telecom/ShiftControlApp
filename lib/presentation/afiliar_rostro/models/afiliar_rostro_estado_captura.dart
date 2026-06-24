/// Estado visual de la captura facial en Afiliar Rostro.
enum AfiliarRostroEstadoCaptura {
  sinCapturar,
  capturado,
  validado,
}

extension AfiliarRostroEstadoCapturaLabel on AfiliarRostroEstadoCaptura {
  String get label {
    switch (this) {
      case AfiliarRostroEstadoCaptura.sinCapturar:
        return 'Sin capturar';
      case AfiliarRostroEstadoCaptura.capturado:
        return 'Capturado';
      case AfiliarRostroEstadoCaptura.validado:
        return 'Validado';
    }
  }
}
