import 'package:flutter/material.dart';

/// Colores del flujo Face Auth (captura y validación de rostro).
/// Alineados con el estilo login / KYC.
class FaceAuthColors {
  FaceAuthColors._();

  static const Color buttonPrimary = Color(0xFF001C6A);
  static const Color accent = Color(0xFF001C6A);

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0E1A)
          : const Color(0xFFF5F5F8);

  static Color cardBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1A2E)
          : Colors.white;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF1A1A2E);

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFB0B0C0)
          : const Color(0xFF6B6B80);

  static Color placeholder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF8B8B9E)
          : const Color(0xFF9E9E9E);

  /// Borde del marco óvalo (guía de encuadre).
  static Color frameBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF5A9FB8)
          : const Color(0xFF001C6A);

  /// Óvalo verde: borde brillante (estilo reconocimiento facial).
  static const Color ovalBorderGreen = Color(0xFF66BB6A);
  /// Óvalo verde: efecto over / relieve (trazo exterior suave).
  static const Color ovalBorderGreenOver = Color(0xFF4CAF50);
}
