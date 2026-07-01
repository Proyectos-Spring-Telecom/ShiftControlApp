import 'package:flutter/foundation.dart';

import 'models/damage_point_model.dart';

/// Rutas de assets del vehículo en Inspección Exterior.
abstract final class VehicleInspectionAssets {
  VehicleInspectionAssets._();

  static String pathFor(VehicleView view, Brightness brightness) {
    if (kIsWeb) {
      return _webPathFor(view, brightness);
    }
    return _nativePathFor(view);
  }

  static String _nativePathFor(VehicleView view) {
    switch (view) {
      case VehicleView.lateralIzquierdo:
        return 'assets/images/vehicle_lateral_izquierdo.png';
      case VehicleView.lateralDerecho:
        return 'assets/images/vehicle_lateral_derecho.png';
      case VehicleView.frontal:
        return 'assets/images/vehicle_frontal.png';
      case VehicleView.trasera:
        return 'assets/images/vehicle_trasera.png';
    }
  }

  static String _webPathFor(VehicleView view, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (view) {
      case VehicleView.lateralIzquierdo:
        return isDark
            ? 'assets/images/vehicle_lateral_izquierdo_blanco.webp'
            : 'assets/images/vehicle_lateral_izquierdo.webp';
      case VehicleView.lateralDerecho:
        return isDark
            ? 'assets/images/vehicle_lateral_derecho_blanco.webp'
            : 'assets/images/vehicle_lateral_derecho.webp';
      case VehicleView.frontal:
        return isDark
            ? 'assets/images/vehicle_frontal_Blanco.webp'
            : 'assets/images/vehicle_frontal.webp';
      case VehicleView.trasera:
        return isDark
            ? 'assets/images/vehicle_trasera_blanco.webp'
            : 'assets/images/vehicle_trasera.webp';
    }
  }
}
