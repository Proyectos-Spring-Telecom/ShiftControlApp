import 'package:flutter_test/flutter_test.dart';
import 'package:turnos_spring/data/models/informacion_general_response.dart';

void main() {
  group('InformacionGeneralResponse', () {
    test('mapea estadoVehiculo dinámicamente incluyendo niveles del vehículo', () {
      final response = InformacionGeneralResponse.fromJson({
        'informacionGeneral': {
          'vehiculo': {'titulo': 'ABC-123', 'subtitulo': 'Ford Transit'},
          'operador': {'nombre': 'Juan Pérez', 'id': 'OP-1'},
          'estadoVehiculo': [
            {'etiqueta': 'Estado de la carrocería', 'valor': 'Bueno'},
            {'etiqueta': 'Estado de indicadores', 'valor': 'Bueno'},
            {'etiqueta': 'Nivel de gasolina', 'valor': '95 %'},
            {'etiqueta': 'Estado de los niveles del vehículo', 'valor': 'Bueno'},
            {'etiqueta': 'Estado de las luces', 'valor': 'Bueno'},
            {'etiqueta': 'Estado de accesorios', 'valor': 'Bueno'},
            {'etiqueta': 'Documentación', 'valor': 'En regla'},
          ],
          'metricasIniciales': [],
        },
      });

      final items = response.informacionGeneral.estadoVehiculo;

      expect(items, hasLength(7));
      expect(
        items[3].etiqueta,
        'Estado de los niveles del vehículo',
      );
      expect(items[3].valor, 'Bueno');
    });

    test('coerce valor numérico a string para compatibilidad futura', () {
      final item = EstadoVehiculoItem.fromJson({
        'etiqueta': 'Nivel de gasolina',
        'valor': 95,
      });

      expect(item.valor, '95');
    });

    test('omite entradas inválidas del arreglo estadoVehiculo', () {
      final response = InformacionGeneralResponse.fromJson({
        'estadoVehiculo': [
          {'etiqueta': 'Estado del motor', 'valor': 'Bueno'},
          'entrada-invalida',
          null,
        ],
      });

      expect(response.informacionGeneral.estadoVehiculo, hasLength(1));
      expect(
        response.informacionGeneral.estadoVehiculo.first.etiqueta,
        'Estado del motor',
      );
    });
  });
}
