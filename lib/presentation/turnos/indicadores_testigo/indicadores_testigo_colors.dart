import 'package:flutter/material.dart';

/// Colores de la pantalla Indicadores Testigo con soporte para tema claro y oscuro.
class IndicadoresTestigoColors {
  IndicadoresTestigoColors._();

  // Colores de acento (iguales en ambos temas)
  static const Color buttonPrimary = Color(0xFF001C6A);
  static const Color highlightText = Color(0xFFE53E5D);

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

  static Color indicatorActive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF60D680)
        : const Color(0xFF2E7D32);
  }

  static Color indicatorActiveBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF385C51)
        : const Color(0xFFE8F5E9);
  }

  static Color indicatorInactive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF60D680)
        : const Color(0xFF2E7D32);
  }

  static Color indicatorInactiveBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF385C51)
        : const Color(0xFFE8F5E9);
  }

  static Color selectedBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A3055)
        : const Color(0xFFE3F2FD);
  }

  static Color selectedIcon(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF7EB8E8)
        : const Color(0xFF1565C0);
  }
}
