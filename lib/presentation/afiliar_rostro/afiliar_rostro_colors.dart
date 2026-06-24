import 'package:flutter/material.dart';

/// Colores de la pantalla Afiliar Rostro con soporte para tema claro y oscuro.
class AfiliarRostroColors {
  AfiliarRostroColors._();

  static const Color buttonPrimary = Color(0xFF001C6A);
  static const Color progressFilled = Color(0xFF681330);
  static const Color statusSuccess = Color(0xFF2E7D32);
  static const Color statusWarning = Color(0xFFE65100);

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

  static Color inputBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF0F0F5);
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

  static Color outline(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF434656)
        : const Color(0xFFE0E0E8);
  }

  static Color photoIconLabel(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B6B80);
  }

  static Color infoIcon(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF7EB8E8)
        : const Color(0xFF1565C0);
  }
}
