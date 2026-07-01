import 'dart:html' as html;

const _viewportContent =
    'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, viewport-fit=cover, interactive-widget=overlays-content';

/// Reaplica el meta viewport tras solicitudes de cámara (getUserMedia).
void lockWebViewportAfterCameraPermission() {
  final meta = html.document.querySelector('meta[name="viewport"]');
  meta?.setAttribute('content', _viewportContent);
}
