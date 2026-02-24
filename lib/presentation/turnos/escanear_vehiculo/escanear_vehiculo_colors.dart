import 'package:flutter/material.dart';

/// Colores de la pantalla Escanear Vehículo con soporte para tema claro y oscuro.
class EscanearVehiculoColors {
  EscanearVehiculoColors._();

  // Colores de acento (iguales en ambos temas)
  static const Color qrBorder = Color(0xFFE53E5D);
  static const Color scannerIcon = Color(0xFFE53E5D);

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF5F5F8);
  }

  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF222237)
        : Colors.white;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1A1A2E);
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB0B0C0)
        : const Color(0xFF6B6B80);
  }

  static Color buttonSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF222237)
        : const Color(0xFFF0F0F5);
  }
}
