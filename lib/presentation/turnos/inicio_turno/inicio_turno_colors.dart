import 'package:flutter/material.dart';

/// Colores de la pantalla Inicio de Turno con soporte para tema claro y oscuro.
class InicioTurnoColors {
  InicioTurnoColors._();

  // Colores de acento (iguales en ambos temas)
  static const Color accent = Color(0xFF681330);
  static const Color infoIcon = Color(0xFF48CAE4);
  static const Color infoBoxBorder = Color(0xFF5A9FB8);
  static const Color buttonPrimary = Color(0xFF001C6A);
  static const Color progressFilled = Color(0xFF681330);

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

  static Color infoBoxBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2D334F)
        : const Color(0xFFE3F2FD);
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

  static Color placeholder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8B8B9E)
        : const Color(0xFF9E9E9E);
  }

  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF38384A)
        : const Color(0xFFE0E0E8);
  }

  static Color progressUnfilled(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF38384A)
        : const Color(0xFFE0E0E8);
  }
}
