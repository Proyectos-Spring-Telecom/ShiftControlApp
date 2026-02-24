import 'package:flutter/material.dart';

/// Clase base para colores temáticos que soporta modo claro y oscuro.
/// Cada pantalla puede extender esta clase o usar los colores directamente.
abstract final class AppColors {
  // ============================================================
  // COLORES BASE - MODO OSCURO
  // ============================================================
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkCardBackground = Color(0xFF232338);
  static const Color darkInputBackground = Color(0xFF1A1A2E);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFB0B0C0);
  static const Color darkDivider = Color(0xFF38384A);
  static const Color darkProgressUnfilled = Color(0xFF3A3A50);
  static const Color darkDisabled = Color(0xFF4A4A5A);

  // ============================================================
  // COLORES BASE - MODO CLARO
  // ============================================================
  static const Color lightBackground = Color(0xFFF5F5F8);
  static const Color lightCardBackground = Colors.white;
  static const Color lightInputBackground = Color(0xFFF0F0F5);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B80);
  static const Color lightDivider = Color(0xFFE0E0E8);
  static const Color lightProgressUnfilled = Color(0xFFE0E0E8);
  static const Color lightDisabled = Color(0xFFB0B0C0);

  // ============================================================
  // COLORES DE ACENTO (IGUALES EN AMBOS MODOS)
  // ============================================================
  static const Color accent = Color(0xFFEE5D88);
  static const Color accentWine = Color(0xFF681330);
  static const Color accentBlue = Color(0xFF001C6A);
  static const Color infoIcon = Color(0xFF48CAE4);
  static const Color iconGreen = Color(0xFF4CAF50);
  static const Color iconOrange = Color(0xFFFF9800);
  static const Color iconCyan = Color(0xFF48CAE4);

  // ============================================================
  // COLORES DE ESTADO - EN TURNO (verde)
  // ============================================================
  static const Color statusPillBackgroundDark = Color(0xFF385C51);
  static const Color statusPillForegroundDark = Color(0xFF60D680);
  static const Color statusPillBackgroundLight = Color(0xFFE8F5E9);
  static const Color statusPillForegroundLight = Color(0xFF2E7D32);

  // ============================================================
  // COLORES DE ESTADO - TURNO CERRADO (azul)
  // ============================================================
  static const Color statusClosedPillBackgroundDark = Color(0xFF2A3055);
  static const Color statusClosedPillForegroundDark = Color(0xFF7EB8E8);
  static const Color statusClosedPillBackgroundLight = Color(0xFFE3F2FD);
  static const Color statusClosedPillForegroundLight = Color(0xFF1565C0);

  // ============================================================
  // MÉTODOS HELPER PARA OBTENER COLORES SEGÚN EL TEMA
  // ============================================================
  
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardBackground
        : lightCardBackground;
  }

  static Color inputBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkInputBackground
        : lightInputBackground;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : lightTextPrimary;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkDivider
        : lightDivider;
  }

  static Color progressUnfilled(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkProgressUnfilled
        : lightProgressUnfilled;
  }

  static Color disabled(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkDisabled
        : lightDisabled;
  }

  static Color statusPillBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? statusPillBackgroundDark
        : statusPillBackgroundLight;
  }

  static Color statusPillForeground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? statusPillForegroundDark
        : statusPillForegroundLight;
  }

  static Color statusClosedPillBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? statusClosedPillBackgroundDark
        : statusClosedPillBackgroundLight;
  }

  static Color statusClosedPillForeground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? statusClosedPillForegroundDark
        : statusClosedPillForegroundLight;
  }
}
