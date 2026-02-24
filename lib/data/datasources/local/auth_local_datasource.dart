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
      await _prefs.setBool(AppConstants.keyIsLoggedIn, true);
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
    return UserModel(id: id, email: email, name: name);
  }

  @override
  Future<String?> getStoredToken() async {
    return _prefs.getString(AppConstants.keyAuthToken);
  }

  @override
  Future<bool> hasSession() async {
    return _prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }
}
