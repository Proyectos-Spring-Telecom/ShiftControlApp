/// Payload de POST /api/turnos/testigos.
/// Siempre incluye los 12 indicadores (0 = apagado, 1 = encendido).
class RegistrarTestigosRequest {
  const RegistrarTestigosRequest({
    required this.idBitacoraVehiculo,
    required this.abs,
    required this.potencia,
    required this.cinturonSeguridad,
    required this.luces,
    required this.presionAceite,
    required this.bateria,
    required this.checkEngine,
    required this.airbag,
    required this.presionNeumatico,
    required this.sistemaFrenos,
    required this.temperaturaMotor,
    required this.fallaDireccionAsistida,
  });

  final int idBitacoraVehiculo;
  final int abs;
  final int potencia;
  final int cinturonSeguridad;
  final int luces;
  final int presionAceite;
  final int bateria;
  final int checkEngine;
  final int airbag;
  final int presionNeumatico;
  final int sistemaFrenos;
  final int temperaturaMotor;
  final int fallaDireccionAsistida;

  /// Mapeo ID UI local → campo backend.
  static const Map<String, String> uiIdToApiField = {
    'abs': 'abs',
    'epc': 'potencia',
    'cinturon': 'cinturonSeguridad',
    'luces': 'luces',
    'aceite': 'presionAceite',
    'bateria': 'bateria',
    'motor': 'checkEngine',
    'airbag': 'airbag',
    'llantas': 'presionNeumatico',
    'frenos': 'sistemaFrenos',
    'temperatura': 'temperaturaMotor',
    'direccion': 'fallaDireccionAsistida',
  };

  factory RegistrarTestigosRequest.fromSeleccion({
    required int idBitacoraVehiculo,
    required Set<String> selectedUiIds,
  }) {
    final valores = <String, int>{
      'abs': 0,
      'potencia': 0,
      'cinturonSeguridad': 0,
      'luces': 0,
      'presionAceite': 0,
      'bateria': 0,
      'checkEngine': 0,
      'airbag': 0,
      'presionNeumatico': 0,
      'sistemaFrenos': 0,
      'temperaturaMotor': 0,
      'fallaDireccionAsistida': 0,
    };

    for (final uiId in selectedUiIds) {
      final apiField = uiIdToApiField[uiId];
      if (apiField != null) {
        valores[apiField] = 1;
      }
    }

    return RegistrarTestigosRequest(
      idBitacoraVehiculo: idBitacoraVehiculo,
      abs: valores['abs']!,
      potencia: valores['potencia']!,
      cinturonSeguridad: valores['cinturonSeguridad']!,
      luces: valores['luces']!,
      presionAceite: valores['presionAceite']!,
      bateria: valores['bateria']!,
      checkEngine: valores['checkEngine']!,
      airbag: valores['airbag']!,
      presionNeumatico: valores['presionNeumatico']!,
      sistemaFrenos: valores['sistemaFrenos']!,
      temperaturaMotor: valores['temperaturaMotor']!,
      fallaDireccionAsistida: valores['fallaDireccionAsistida']!,
    );
  }

  Map<String, dynamic> toJson() => {
        'idBitacoraVehiculo': idBitacoraVehiculo,
        'abs': abs,
        'potencia': potencia,
        'cinturonSeguridad': cinturonSeguridad,
        'luces': luces,
        'presionAceite': presionAceite,
        'bateria': bateria,
        'checkEngine': checkEngine,
        'airbag': airbag,
        'presionNeumatico': presionNeumatico,
        'sistemaFrenos': sistemaFrenos,
        'temperaturaMotor': temperaturaMotor,
        'fallaDireccionAsistida': fallaDireccionAsistida,
      };
}
