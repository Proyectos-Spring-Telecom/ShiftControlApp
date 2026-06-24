import 'login_me_response.dart';

/// Datos del operador para la pantalla Afiliar Rostro (GET /api/login/me).
class AfiliarRostroOperadorInfo {
  const AfiliarRostroOperadorInfo({
    required this.idUsuario,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.telefono,
  });

  final String idUsuario;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String telefono;

  factory AfiliarRostroOperadorInfo.fromLoginMeJson(Map<String, dynamic> json) {
    final me = LoginMeResponse.fromJson(json);

    return AfiliarRostroOperadorInfo(
      idUsuario: me.id?.toString() ?? me.userName,
      nombre: me.nombre,
      apellidoPaterno: me.apellidoPaterno,
      apellidoMaterno: me.apellidoMaterno,
      telefono: me.telefono,
    );
  }
}
