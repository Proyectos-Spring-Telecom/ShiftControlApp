import 'package:flutter/material.dart';

/// Colores de la pantalla de login con soporte para tema claro y oscuro.
///
/// En apariencia clara la referencia usa hero claro + card oscura glass
/// (no card blanca).
class LoginColors {
  LoginColors._();

  /// Azul de acción (tabs / botón primario en oscuro).
  static const Color accentBlue = Color(0xFF1B5FD9);

  /// Azul navy institucional.
  static const Color navy = Color(0xFF001C6A);

  static const Color button = accentBlue;

  static const Color _glassDark = Color(0xCC121F35);
  static const Color _glassLightOverHero = Color(0xB3142238);
  static const Color _inputDark = Color(0xFF0D1A2E);
  static const Color _tabTrackDark = Color(0xFF0A1524);

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A1628)
          : const Color(0xFFD6E4F5);

  static Color cardBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _glassDark
          : _glassLightOverHero;

  static Color cardBorder(BuildContext context) =>
      Colors.white.withValues(alpha: 0.16);

  static Color inputBackground(BuildContext context) => _inputDark;

  static Color inputBorder(BuildContext context) =>
      Colors.white.withValues(alpha: 0.20);

  /// Texto sobre card glass / hero del Login (siempre claro).
  static Color onCardPrimary(BuildContext context) => Colors.white;

  static Color onCardSecondary(BuildContext context) =>
      Colors.white.withValues(alpha: 0.82);

  static Color onCardPlaceholder(BuildContext context) =>
      const Color(0xFF8B9BB0);

  /// Texto general (otras pantallas de auth que reutilizan LoginColors).
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF1A1A2E);

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.78)
          : const Color(0xFF5A5A72);

  static Color placeholder(BuildContext context) =>
      onCardPlaceholder(context);

  static Color focusBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? accentBlue
          : Colors.white.withValues(alpha: 0.55);

  static Color tabTrack(BuildContext context) => _tabTrackDark;

  static Color tabSelected(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? accentBlue
          : Colors.white;

  static Color tabSelectedForeground(BuildContext context) =>
      const Color(0xFF0A1628);

  static Color tabUnselectedForeground(BuildContext context) =>
      Colors.white.withValues(alpha: 0.78);

  /// Botón primario "Iniciar Sesión".
  static Color primaryButtonBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? accentBlue
          : Colors.white;

  static Color primaryButtonForeground(BuildContext context) =>
      const Color(0xFF0A1628);

  /// Botón secundario "Reconocimiento facial" (outlined).
  static Color secondaryButtonBackground(BuildContext context) =>
      Colors.transparent;

  static Color secondaryButtonForeground(BuildContext context) => Colors.white;

  static Color secondaryButtonBorder(BuildContext context) =>
      Colors.white.withValues(alpha: 0.90);

  /// @deprecated Usar [primaryButtonBackground] / [secondaryButtonBackground].
  static Color buttonOutlineBackground(BuildContext context) =>
      secondaryButtonBackground(context);

  /// @deprecated Usar [secondaryButtonForeground].
  static Color buttonOutlineForeground(BuildContext context) =>
      secondaryButtonForeground(context);
}
