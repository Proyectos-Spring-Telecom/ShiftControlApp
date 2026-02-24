import 'package:flutter/material.dart';

/// Colores de la pantalla Historial de Turnos con soporte para tema claro y oscuro.
class HistorialTurnosColors {
  HistorialTurnosColors._();

  // Colores de acento (iguales en ambos temas)
  static const Color accentWine = Color(0xFF681330);
  static const Color cardBorderAyer = Color(0xFF001C6A);

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

  static Color searchBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF0F0F5);
  }

  static Color searchPlaceholder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8B8B9E)
        : const Color(0xFF9E9E9E);
  }

  static Color iconCircleBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF38384A)
        : const Color(0xFFE0E0E8);
  }
}
