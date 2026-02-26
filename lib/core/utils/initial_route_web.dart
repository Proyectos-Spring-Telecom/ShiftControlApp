import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import '../constants/route_constants.dart';

/// En web: lee el hash desde el navegador (única forma fiable en release).
/// Ej: #/nueva-contrasena?token=... → /nueva-contrasena
String? getInitialRouteFromHash() {
  final hash = html.window.location.hash;
  debugPrint('[initial_route_web] getInitialRouteFromHash: hash="$hash"');

  if (hash.isEmpty) return null;

  final fragment = hash.startsWith('#') ? hash.substring(1) : hash;
  final uri = Uri.parse(fragment);
  debugPrint('[initial_route_web] path="${uri.path}"');

  if (uri.path == RouteConstants.nuevaContrasena) {
    debugPrint('[initial_route_web] → nuevaContrasena');
    return RouteConstants.nuevaContrasena;
  }
  debugPrint('[initial_route_web] → null (path no coincide)');
  return null;
}
