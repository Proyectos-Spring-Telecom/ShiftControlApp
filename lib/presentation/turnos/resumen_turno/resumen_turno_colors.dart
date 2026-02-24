import 'package:flutter/material.dart';

/// Colores de la pantalla Resumen de Turno con soporte para tema claro y oscuro.
class ResumenTurnoColors {
  ResumenTurnoColors._();

  // Colores de acento (iguales en ambos temas)
  static const Color statusTextGreen = Color(0xFF4ADE80);
  static const Color statusLabelGreen = Color(0xFF86EFAC);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color iconClockBg = Color(0xFF7eb8e8);
  static const Color iconLocationBg = Color(0xFF4CAF50);
  static const Color buttonIniciar = Color(0xFF681330);

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

  static Color sectionHeading(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B6B80);
  }

  static Color statusCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E3A2F)
        : const Color(0xFFE8F5E9);
  }

  static Color statusBoxBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF5A9F7A)
        : const Color(0xFF81C784);
  }
}
