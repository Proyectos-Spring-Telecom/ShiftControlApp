/// Cliente HTTP base preparado para consumo REST.
/// Implementar con dio o http cuando se conecte a API real.
abstract interface class ApiClient {
  Future<Map<String, dynamic>> get(String path, {Map<String, String>? headers});
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  });
  Future<Map<String, dynamic>> put(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  });
  Future<Map<String, dynamic>> delete(String path, {Map<String, String>? headers});
}
