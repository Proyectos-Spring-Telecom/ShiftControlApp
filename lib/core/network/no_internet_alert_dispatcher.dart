import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bus de eventos para mostrar una sola alerta de "Sin conexión a Internet".
///
/// La capa HTTP notifica aquí; la UI (MaterialApp) escucha y muestra
/// [AppAlertBanner] sin acoplar BuildContext al cliente HTTP.
abstract final class NoInternetAlertDispatcher {
  NoInternetAlertDispatcher._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static bool _isAlertVisible = false;
  static Timer? _resetTimer;

  /// Duración alineada con [_bannerVisibilityDuration] de AppAlertBanner.
  static const Duration alertVisibilityDuration = Duration(seconds: 3);

  /// Notifica a la UI. Ignora llamadas mientras la alerta ya está visible.
  static void notify() {
    if (_isAlertVisible) {
      debugPrint('NoInternetAlert: omitida (ya visible)');
      return;
    }
    _isAlertVisible = true;
    _controller.add(null);
    _resetTimer?.cancel();
    _resetTimer = Timer(alertVisibilityDuration, () {
      _isAlertVisible = false;
    });
  }

  @visibleForTesting
  static void resetForTests() {
    _resetTimer?.cancel();
    _isAlertVisible = false;
  }
}
