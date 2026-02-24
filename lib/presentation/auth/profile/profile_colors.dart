import 'package:flutter/material.dart';

/// Colores de la pantalla Perfil con soporte para tema claro y oscuro.
class ProfileColors {
  ProfileColors._();

  // Colores de acento (iguales en ambos temas)
  static const Color buttonPrimary = Color(0xFF001C6A);
  static const Color accentWine = Color(0xFF681330);
  static const Color statusActiveBg = Color(0xFF166534);
  static const Color statusActiveFg = Colors.white;

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1A2E)
          : const Color(0xFFF5F5F8);

  static Color cardBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF222237)
          : Colors.white;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF1A1A2E);

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFB0B0C0)
          : const Color(0xFF6B6B80);

  static Color sectionHeading(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF9CA3AF)
          : const Color(0xFF6B6B80);

  static Color inputBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF222237)
          : const Color(0xFFF0F0F5);

  static Color inputBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF38384A)
          : const Color(0xFFE0E0E8);
}
