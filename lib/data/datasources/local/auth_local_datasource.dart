import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fuente de datos local para sesión de autenticación.
abstract interface class AuthLocalDatasource {
  Future<void> saveSession(UserModel user, String token);
  Future<void> clearSession();
  Future<UserModel?> getStoredUser();
  Future<String?> getStoredToken();
  Future<bool> hasSession();
  /// Último correo con login exitoso (para login por NIP). No se borra en clearSession.
  Future<void> saveLastLoginEmail(String email);
  Future<String?> getLastLoginEmail();
}

class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  AuthLocalDatasourceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> saveSession(UserModel user, String token) async {
    try {
      await _prefs.setString(AppConstants.keyAuthToken, token);
      await _prefs.setString(AppConstants.keyUserId, user.id);
      await _prefs.setString(AppConstants.keyUserEmail, user.email);
      await _prefs.setString(AppConstants.keyUserName, user.name);
      if (user.roleName != null) {
        await _prefs.setString(AppConstants.keyUserRoleName, user.roleName!);
      }
      if (user.apellidoPaterno != null) {
        await _prefs.setString(AppConstants.keyUserApellidoPaterno, user.apellidoPaterno!);
      }
      if (user.apellidoMaterno != null) {
        await _prefs.setString(AppConstants.keyUserApellidoMaterno, user.apellidoMaterno!);
      }
      if (user.telefono != null) {
        await _prefs.setString(AppConstants.keyUserTelefono, user.telefono!);
      }
      if (user.userName != null) {
        await _prefs.setString(AppConstants.keyUserUserName, user.userName!);
      }
      if (user.fotoPerfil != null) {
        await _prefs.setString(AppConstants.keyUserFotoPerfil, user.fotoPerfil!);
      }
      await _prefs.setBool(AppConstants.keyIsLoggedIn, true);
      final lastEmail = user.userName ?? user.email;
      if (lastEmail.isNotEmpty) {
        await _prefs.setString(AppConstants.keyLastLoginEmail, lastEmail);
      }
    } catch (e) {
      throw StorageException('Error al guardar la sesión: $e');
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _prefs.remove(AppConstants.keyAuthToken);
      await _prefs.remove(AppConstants.keyUserId);
      await _prefs.remove(AppConstants.keyUserEmail);
      await _prefs.remove(AppConstants.keyUserName);
      await _prefs.remove(AppConstants.keyUserRoleName);
      await _prefs.remove(AppConstants.keyUserApellidoPaterno);
      await _prefs.remove(AppConstants.keyUserApellidoMaterno);
      await _prefs.remove(AppConstants.keyUserTelefono);
      await _prefs.remove(AppConstants.keyUserUserName);
      await _prefs.remove(AppConstants.keyUserFotoPerfil);
      await _prefs.setBool(AppConstants.keyIsLoggedIn, false);
    } catch (e) {
      throw StorageException('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<UserModel?> getStoredUser() async {
    final id = _prefs.getString(AppConstants.keyUserId);
    final email = _prefs.getString(AppConstants.keyUserEmail);
    final name = _prefs.getString(AppConstants.keyUserName);
    if (id == null || email == null || name == null) return null;
    return UserModel(
      id: id,
      email: email,
      name: name,
      roleName: _prefs.getString(AppConstants.keyUserRoleName),
      apellidoPaterno: _prefs.getString(AppConstants.keyUserApellidoPaterno),
      apellidoMaterno: _prefs.getString(AppConstants.keyUserApellidoMaterno),
      telefono: _prefs.getString(AppConstants.keyUserTelefono),
      userName: _prefs.getString(AppConstants.keyUserUserName),
      fotoPerfil: _prefs.getString(AppConstants.keyUserFotoPerfil),
    );
  }

  @override
  Future<String?> getStoredToken() async {
    return _prefs.getString(AppConstants.keyAuthToken);
  }

  @override
  Future<bool> hasSession() async {
    return _prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  @override
  Future<void> saveLastLoginEmail(String email) async {
    if (email.isEmpty) return;
    await _prefs.setString(AppConstants.keyLastLoginEmail, email);
  }

  @override
  Future<String?> getLastLoginEmail() async {
    return _prefs.getString(AppConstants.keyLastLoginEmail);
  }
}
