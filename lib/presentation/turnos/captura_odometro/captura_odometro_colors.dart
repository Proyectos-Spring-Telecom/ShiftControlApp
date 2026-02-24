import 'package:flutter/material.dart';

/// Colores de la pantalla Captura de Odómetro con soporte para tema claro y oscuro.
class CapturaOdometroColors {
  CapturaOdometroColors._();

  // Colores de acento (iguales en ambos temas)
  static const Color progressFilled = Color(0xFF681330);
  static const Color pillLightBlue = Color(0xFF48CAE4);
  static const Color ocrActiveGreen = Color(0xFF4CAF50);
  static const Color tomarFotoButton = Color(0xFF681330);
  static const Color buttonSiguiente = Color(0xFF001C6A);

  // Colores oscuros (por defecto)
  static const Color _darkBackground = Color(0xFF1A1A2E);
  static const Color _darkCardBackground = Color(0xFF222237);
  static const Color _darkTextPrimary = Colors.white;
  static const Color _darkTextSecondary = Color(0xFFB0B0C0);
  static const Color _darkProgressUnfilled = Color(0xFF38384A);
  static const Color _darkPillT804Background = Color(0xFF2A3055);
  static const Color _darkPillT804Text = Color(0xFF7EB8E8);
  static const Color _darkPillT804Border = Color(0xFF38384A);
  static const Color _darkPillDarkGray = Color(0xFF4A4E65);
  static const Color _darkOcrPillBackground = Color(0xFF385C51);
  static const Color _darkOcrPillForeground = Color(0xFF60D680);
  static const Color _darkPhotoIconLabel = Color(0xFF9CA3AF);
  static const Color _darkDashedBorder = Color(0xFF5A6078);

  // Colores claros
  static const Color _lightBackground = Color(0xFFF5F5F8);
  static const Color _lightCardBackground = Colors.white;
  static const Color _lightTextPrimary = Color(0xFF1A1A2E);
  static const Color _lightTextSecondary = Color(0xFF6B6B80);
  static const Color _lightProgressUnfilled = Color(0xFFE0E0E8);
  static const Color _lightPillT804Background = Color(0xFFE3F2FD);
  static const Color _lightPillT804Text = Color(0xFF1565C0);
  static const Color _lightPillT804Border = Color(0xFFBBDEFB);
  static const Color _lightPillDarkGray = Color(0xFFE0E0E8);
  static const Color _lightOcrPillBackground = Color(0xFFE8F5E9);
  static const Color _lightOcrPillForeground = Color(0xFF2E7D32);
  static const Color _lightPhotoIconLabel = Color(0xFF6B6B80);
  static const Color _lightDashedBorder = Color(0xFFBDBDBD);

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkBackground : _lightBackground;

  static Color cardBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkCardBackground : _lightCardBackground;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkTextPrimary : _lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkTextSecondary : _lightTextSecondary;

  static Color progressUnfilled(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkProgressUnfilled : _lightProgressUnfilled;

  static Color pillT804Background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkPillT804Background : _lightPillT804Background;

  static Color pillT804Text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkPillT804Text : _lightPillT804Text;

  static Color pillT804Border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkPillT804Border : _lightPillT804Border;

  static Color pillDarkGray(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkPillDarkGray : _lightPillDarkGray;

  static Color ocrPillBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkOcrPillBackground : _lightOcrPillBackground;

  static Color ocrPillForeground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkOcrPillForeground : _lightOcrPillForeground;

  static Color photoIconLabel(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkPhotoIconLabel : _lightPhotoIconLabel;

  static Color dashedBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkDashedBorder : _lightDashedBorder;
}
