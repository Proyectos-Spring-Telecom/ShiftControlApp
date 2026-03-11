import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/placas_validar_remote_datasource.dart';

/// Provider global con el resultado de GET /placas/validar.
/// Se actualiza al validar la placa en Inicio de Turno; cualquier pantalla
/// (Apertura de Turno, Cierre de Turno, etc.) puede leerlo para mostrar
/// placa, marca, modelo, año y económico.
final placaValidadaProvider = StateProvider<PlacasValidarResult?>((ref) => null);
