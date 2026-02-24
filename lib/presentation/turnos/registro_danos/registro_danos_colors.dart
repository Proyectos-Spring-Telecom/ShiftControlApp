import 'package:flutter/material.dart';

/// Colores de la pantalla Registro de Daños con soporte para tema claro y oscuro.
class RegistroDanosColors {
  RegistroDanosColors._();

  // Colores de acento (iguales en ambos temas)
  static const Color pointDamaged = Color(0xFF681330);
  static const Color tabSelected = Color(0xFF681330);
  static const Color buttonPrimary = Color(0xFF001C6A);
  static const Color resumenBadge = Color(0xFF681330);
  static const Color severityBaja = Color(0xFF7EB8E8);
  static const Color severityMedia = Color(0xFFD4A017);
  static const Color severityAlta = Color(0xFF681330);

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

  static Color pointNormal(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A4E)
        : const Color(0xFFE0E0E8);
  }

  static Color pointBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF5A5A6E)
        : const Color(0xFFBDBDBD);
  }

  static Color tabUnselected(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A3E)
        : const Color(0xFFE0E0E8);
  }

  static Color resumenBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A3E)
        : const Color(0xFFF5F5F8);
  }

  static Color sheetBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A2E)
        : Colors.white;
  }

  static Color sheetHandle(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4A4A5E)
        : const Color(0xFFBDBDBD);
  }

  static Color inputBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF222237)
        : const Color(0xFFF0F0F5);
  }

  static Color severityBajaBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A3055)
        : const Color(0xFFE3F2FD);
  }

  static Color vehicleOutline(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4A4A5E)
        : const Color(0xFF9E9E9E);
  }

  static Color vehicleOutlineLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A4E)
        : const Color(0xFFBDBDBD);
  }
}
