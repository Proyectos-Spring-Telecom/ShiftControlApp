import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_environment.dart';

/// En Web: `navigator.onLine` como señal rápida + probe al host de la API
/// (ya con CORS permitido). Cliente HTTP crudo — no pasa por [AppHttp].
Future<bool> hasInternetAccess() async {
  final online = html.window.navigator.onLine;
  if (online == false) {
    debugPrint('InternetConnection(web): navigator.onLine=false');
    return false;
  }

  try {
    final base = AppEnvironmentConfig.baseUrl;
    final uri = Uri.parse(base.endsWith('/') ? base : '$base/');
    final response = await http
        .get(
          uri,
          headers: const {'Accept': '*/*'},
        )
        .timeout(const Duration(seconds: 3));
    // Cualquier respuesta HTTP implica ruta de red hacia el servidor.
    debugPrint(
      'InternetConnection(web): probe status=${response.statusCode}',
    );
    return true;
  } catch (e) {
    debugPrint('InternetConnection(web): probe falló: $e');
    return false;
  }
}
