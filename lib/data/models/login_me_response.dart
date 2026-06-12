import 'rol_model.dart';
import 'user_model.dart';

/// Respuesta de GET /api/login/me.
class LoginMeResponse {
  const LoginMeResponse({
    this.id,
    this.userName,
    this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.telefono,
    this.email,
    this.fotoPerfil,
    this.idCliente,
    this.idRol,
    this.estatus,
    this.rol,
  });

  final String? id;
  final String? userName;
  final String? nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? telefono;
  final String? email;
  final String? fotoPerfil;
  final int? idCliente;
  final int? idRol;
  final int? estatus;
  final RolModel? rol;

  factory LoginMeResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    RolModel? rol;
    if (data['rol'] is Map<String, dynamic>) {
      rol = RolModel.fromJson(data['rol'] as Map<String, dynamic>);
    }

    return LoginMeResponse(
      id: data['id']?.toString(),
      userName: data['userName'] as String?,
      nombre: data['nombre'] as String?,
      apellidoPaterno: data['apellidoPaterno'] as String?,
      apellidoMaterno: data['apellidoMaterno'] as String?,
      telefono: data['telefono'] as String?,
      email: data['email'] as String?,
      fotoPerfil: data['fotoPerfil'] as String?,
      idCliente: (data['idCliente'] as num?)?.toInt(),
      idRol: (data['idRol'] as num?)?.toInt(),
      estatus: (data['estatus'] as num?)?.toInt(),
      rol: rol,
    );
  }

  UserModel toUserModel({String fallbackEmail = ''}) {
    final resolvedEmail = email ?? userName ?? fallbackEmail;
    final resolvedName = nombre ?? userName ?? resolvedEmail.split('@').first;

    return UserModel(
      id: id ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: resolvedEmail,
      name: resolvedName,
      roleName: rol?.nombre.isNotEmpty == true ? rol!.nombre : null,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      telefono: telefono,
      userName: userName,
      fotoPerfil: fotoPerfil,
    );
  }
}
