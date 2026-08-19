import 'internet_connection_service_stub.dart'
    if (dart.library.io) 'internet_connection_service_io.dart'
    if (dart.library.html) 'internet_connection_service_web.dart' as impl;

/// Comprueba acceso real a Internet (no solo Wi‑Fi/red local).
///
/// La comprobación usa un cliente HTTP independiente y no pasa por [AppHttp],
/// para evitar recursión con la validación previa a cada API.
abstract final class InternetConnectionService {
  InternetConnectionService._();

  static Future<bool> hasInternetAccess() => impl.hasInternetAccess();
}
