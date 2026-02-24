import 'package:flutter/material.dart';

/// Colores de la pantalla Registro de Combustible con soporte para tema claro y oscuro.
class RegistroCombustibleColors {
  RegistroCombustibleColors._();

  // Colores de acento (iguales en ambos temas)
  static const Color progressFilled = Color(0xFF681330);
  static const Color accentRed = Color(0xFF681330);
  static const Color buttonSiguiente = Color(0xFF001C6A);
  static const Color warningBoxBorder = Color(0xFFB8860B);
  static const Color warningIconAndText = Color(0xFFFFD700);

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

  static Color progressUnfilled(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF38384A)
        : const Color(0xFFE0E0E8);
  }

  static Color dashedBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF5A6078)
        : const Color(0xFFBDBDBD);
  }

  static Color photoIconLabel(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B6B80);
  }

  static Color warningBoxBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2E2A24)
        : const Color(0xFFFFF8E1);
  }

  static Color infoIcon(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF7EB8E8)
        : const Color(0xFF1565C0);
  }
}
