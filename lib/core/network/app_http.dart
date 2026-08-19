import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';
import 'internet_connection_service.dart';
import 'no_internet_alert_dispatcher.dart';

/// Cliente HTTP central de la app.
///
/// Valida acceso real a Internet **antes** de cualquier GET/POST/PUT/PATCH/DELETE
/// o envío multipart. Si no hay Internet: notifica la alerta global y lanza
/// [NoInternetException] sin abrir la conexión hacia la API.
abstract final class AppHttp {
  AppHttp._();

  /// Comprueba Internet; si falla, emite alerta global y lanza.
  static Future<void> ensureOnline() async {
    final hasInternet = await InternetConnectionService.hasInternetAccess();
    if (!hasInternet) {
      NoInternetAlertDispatcher.notify();
      throw const NoInternetException();
    }
  }

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    await ensureOnline();
    return http.get(url, headers: headers);
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    await ensureOnline();
    return http.post(url, headers: headers, body: body, encoding: encoding);
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    await ensureOnline();
    return http.put(url, headers: headers, body: body, encoding: encoding);
  }

  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    await ensureOnline();
    return http.patch(url, headers: headers, body: body, encoding: encoding);
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    await ensureOnline();
    return http.delete(url, headers: headers, body: body, encoding: encoding);
  }

  /// Envío de [http.MultipartRequest] u otros [http.BaseRequest].
  static Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await ensureOnline();
    return request.send();
  }
}
