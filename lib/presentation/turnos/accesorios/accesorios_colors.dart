import 'package:flutter/material.dart';

/// Colores de la pantalla Accesorios con soporte para tema claro y oscuro.
class AccesoriosColors {
  AccesoriosColors._();

  // Colores de acento (iguales en ambos temas)
  static const Color switchActive = Color(0xFF681330);
  static const Color buttonPrimary = Color(0xFF681330);

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

  static Color switchTrackInactive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF38384A)
        : const Color(0xFFE0E0E8);
  }

  static Color badgeBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A3055)
        : const Color(0xFFE3F2FD);
  }

  static Color badgeText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF7EB8E8)
        : const Color(0xFF1565C0);
  }

  static Color infoBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF222237)
        : const Color(0xFFF5F5F8);
  }

  static Color infoIcon(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF7EB8E8)
        : const Color(0xFF1565C0);
  }

  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF38384A)
        : const Color(0xFFE0E0E8);
  }

  static Color iconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B6B80);
  }

  static Color sectionHeader(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF6B7280)
        : const Color(0xFF6B6B80);
  }
}
