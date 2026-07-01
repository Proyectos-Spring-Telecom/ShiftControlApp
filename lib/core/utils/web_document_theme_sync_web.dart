import 'dart:html' as html;

import 'package:flutter/material.dart';

/// Alinea `color-scheme` y fondo del documento HTML con el [ThemeData] activo de Flutter.
void syncWebDocumentTheme(ThemeData theme) {
  final brightness = theme.brightness;
  final background = _toCssColor(theme.scaffoldBackgroundColor);
  final colorScheme = brightness == Brightness.dark ? 'dark' : 'light';

  final documentElement = html.document.documentElement;
  if (documentElement != null) {
    documentElement.style.setProperty('color-scheme', colorScheme);
    documentElement.style.backgroundColor = background;
  }

  final body = html.document.body;
  if (body != null) {
    body.style.setProperty('color-scheme', colorScheme);
    body.style.backgroundColor = background;
  }

  for (final host in html.document.querySelectorAll('flt-glass-pane, flt-scene-host')) {
    host.style.backgroundColor = background;
  }
}

String _toCssColor(Color color) {
  final rgb = color.value & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}
