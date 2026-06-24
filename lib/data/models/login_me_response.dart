import 'permiso_perfil_model.dart';
import 'rol_model.dart';
import 'user_model.dart';

/// Respuesta de GET /api/login/me (objeto plano en la raíz, sin wrapper `data`).
class LoginMeResponse {
  const LoginMeResponse({
    this.message,
    this.id,
    this.nombre = '',
    this.apellidoPaterno = '',
    this.apellidoMaterno = '',
    this.idCliente,
    this.logotipo = '',
    this.ultimoLogin = '',
    this.fotoPerfil = '',
    this.telefono = '',
    this.userName = '',
    this.rol,
    this.permisos = const [],
  });

  final String? message;
  final int? id;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final int? idCliente;
  final String logotipo;
  final String ultimoLogin;
  final String fotoPerfil;
  final String telefono;
  final String userName;
  final RolModel? rol;
  final List<PermisoPerfilModel> permisos;

  /// Compatibilidad con respuestas legacy que envolvían el perfil en `data`.
  static Map<String, dynamic> _resolveRoot(Map<String, dynamic> json) {
    if (json['data'] is Map<String, dynamic>) {
      return json['data'] as Map<String, dynamic>;
    }
    return json;
  }

  static String _stringField(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  factory LoginMeResponse.fromJson(Map<String, dynamic> json) {
    final root = _resolveRoot(json);

    RolModel? rol;
    if (root['rol'] is Map<String, dynamic>) {
      rol = RolModel.fromJson(root['rol'] as Map<String, dynamic>);
    }

    final permisosRaw = root['permisos'];
    final permisos = permisosRaw is List
        ? permisosRaw
            .whereType<Map<String, dynamic>>()
            .map(PermisoPerfilModel.fromJson)
            .toList()
        : <PermisoPerfilModel>[];

    return LoginMeResponse(
      message: _stringField(root['message']).isEmpty ? null : _stringField(root['message']),
      id: (root['id'] as num?)?.toInt(),
      nombre: _stringField(root['nombre']),
      apellidoPaterno: _stringField(root['apellidoPaterno']),
      apellidoMaterno: _stringField(root['apellidoMaterno']),
      idCliente: (root['idCliente'] as num?)?.toInt(),
      logotipo: _stringField(root['logotipo']),
      ultimoLogin: _stringField(root['ultimoLogin']),
      fotoPerfil: _stringField(root['fotoPerfil']),
      telefono: _stringField(root['telefono']),
      userName: _stringField(root['userName']),
      rol: rol,
      permisos: permisos,
    );
  }

  UserModel toUserModel({String fallbackEmail = ''}) {
    final resolvedEmail = userName.isNotEmpty ? userName : fallbackEmail;
    final resolvedName = nombre.isNotEmpty
        ? nombre
        : (userName.isNotEmpty ? userName : resolvedEmail.split('@').first);

    return UserModel(
      id: id?.toString() ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: resolvedEmail,
      name: resolvedName,
      roleName: rol?.nombre.isNotEmpty == true ? rol!.nombre : null,
      apellidoPaterno: apellidoPaterno.isEmpty ? null : apellidoPaterno,
      apellidoMaterno: apellidoMaterno.isEmpty ? null : apellidoMaterno,
      telefono: telefono.isEmpty ? null : telefono,
      userName: userName.isEmpty ? null : userName,
      fotoPerfil: fotoPerfil.isEmpty ? null : fotoPerfil,
    );
  }
}
