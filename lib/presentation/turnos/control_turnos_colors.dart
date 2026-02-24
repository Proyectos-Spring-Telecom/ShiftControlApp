import 'package:flutter/material.dart';

/// Colores de la pantalla Control de Turnos con soporte para tema claro y oscuro.
class ControlTurnosColors {
  ControlTurnosColors._();

  // Colores de acento (iguales en ambos temas)
  static const Color accent = Color(0xFFEE5D88);
  static const Color statusOnShift = Color(0xFF4CAF50);
  static const Color iconCyan = Color(0xFF7eb8e8);
  static const Color iconOrange = Color(0xFFFF9800);
  static const Color iconGreen = Color(0xFF4CAF50);

  // ============================================================
  // MÉTODOS QUE RETORNAN COLORES SEGÚN EL TEMA
  // ============================================================

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF5F5F8);
  }

  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF232338)
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

  static Color statusPillBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF385C51)
        : const Color(0xFFE8F5E9);
  }

  static Color statusPillForeground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF60D680)
        : const Color(0xFF2E7D32);
  }

  static Color statusClosedPillBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A3055)
        : const Color(0xFFE3F2FD);
  }

  static Color statusClosedPillForeground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF7EB8E8)
        : const Color(0xFF1565C0);
  }

  static Color progressUnfilled(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A50)
        : const Color(0xFFE0E0E8);
  }

  static Color disabled(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4A4A5A)
        : const Color(0xFFB0B0C0);
  }

  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF38384A)
        : const Color(0xFFE0E0E8);
  }
}
