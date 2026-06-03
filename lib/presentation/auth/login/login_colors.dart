import 'package:flutter/material.dart';

/// Colores de la pantalla de login con soporte para tema claro y oscuro.
class LoginColors {
  LoginColors._();

  static const Color button = Color(0xFF001C6A);

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0E1A)
          : const Color(0xFFF5F5F8);

  static Color inputBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF38384A)
          : const Color(0xFFF0F0F5);

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF1A1A2E);

  static Color placeholder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF8B8B9E)
          : const Color(0xFF6B6B80);

  static Color focusBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF8B8B9E)
          : const Color(0xFFCCCCDD);

  /// Fondo del botón "Iniciar Sesión" (outline): blanco en tema claro, transparente en oscuro.
  static Color buttonOutlineBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.transparent
          : Colors.white;

  /// Texto y borde del botón "Iniciar Sesión" (outline): blanco en oscuro, azul en claro.
  static Color buttonOutlineForeground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : button;
}
