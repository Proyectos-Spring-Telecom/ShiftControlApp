import 'permiso_model.dart';
import 'rol_model.dart';

/// Modelo de la respuesta de POST /api/login.
/// Incluye token, rol, permisos y datos del usuario.
class LoginResponseModel {
  const LoginResponseModel({
    required this.token,
    this.refreshToken,
    this.rol,
    this.permisos = const [],
    this.id,
    this.userName,
    this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.telefono,
    this.email,
    this.fotoPerfil,
  });

  final String token;
  final String? refreshToken;
  final RolModel? rol;
  final List<PermisoModel> permisos;
  final String? id;
  final String? userName;
  final String? nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? telefono;
  final String? email;
  final String? fotoPerfil;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    RolModel? rol;
    if (json['rol'] is Map<String, dynamic>) {
      rol = RolModel.fromJson(json['rol'] as Map<String, dynamic>);
    }

    List<PermisoModel> permisos = [];
    if (json['permisos'] is List) {
      for (final e in json['permisos'] as List) {
        if (e is Map<String, dynamic>) {
          permisos.add(PermisoModel.fromJson(e));
        }
      }
    }

    // Usuario puede venir en raíz o en "usuario"
    final userMap = json['usuario'] is Map<String, dynamic>
        ? json['usuario'] as Map<String, dynamic>
        : json;

    String? id;
    if (userMap['id'] != null) id = userMap['id'].toString();
    final userName = userMap['userName'] as String?;
    final nombre = userMap['nombre'] as String?;
    final apellidoPaterno = userMap['apellidoPaterno'] as String?;
    final apellidoMaterno = userMap['apellidoMaterno'] as String?;
    final telefono = userMap['telefono'] as String?;
    final email = userMap['email'] as String? ?? userName;
    final fotoPerfil = userMap['fotoPerfil'] as String?;

    return LoginResponseModel(
      token: (json['token'] as String?) ?? '',
      refreshToken: json['refreshToken'] as String?,
      rol: rol,
      permisos: permisos,
      id: id,
      userName: userName,
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      telefono: telefono,
      email: email,
      fotoPerfil: fotoPerfil,
    );
  }
}
