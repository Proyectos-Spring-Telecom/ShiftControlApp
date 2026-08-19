import 'dart:io';

import 'package:flutter/foundation.dart';

/// Acceso real a Internet vía resolución DNS (no usa el cliente HTTP de la app).
Future<bool> hasInternetAccess() async {
  try {
    final result = await InternetAddress.lookup('one.one.one.one')
        .timeout(const Duration(seconds: 3));
    final ok = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    if (!ok) {
      debugPrint('InternetConnection(io): lookup vacío');
    }
    return ok;
  } on SocketException catch (e) {
    debugPrint('InternetConnection(io): SocketException $e');
    return false;
  } catch (e) {
    debugPrint('InternetConnection(io): $e');
    return false;
  }
}
