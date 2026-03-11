import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

/// Servicio central para almacenamiento de access token y refresh token.
/// No acceder a localStorage (SharedPreferences) desde otras partes del código para tokens.
abstract interface class TokenStorageService {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> saveRefreshToken(String refreshToken);
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
}

class TokenStorageServiceImpl implements TokenStorageService {
  TokenStorageServiceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> saveToken(String token) async {
    try {
      await _prefs.setString(AppConstants.keyAuthToken, token);
    } catch (e) {
      throw StorageException('Error al guardar token: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    return _prefs.getString(AppConstants.keyAuthToken);
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _prefs.setString(AppConstants.keyRefreshToken, refreshToken);
    } catch (e) {
      throw StorageException('Error al guardar refresh token: $e');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    return _prefs.getString(AppConstants.keyRefreshToken);
  }

  @override
  Future<void> clearTokens() async {
    try {
      await _prefs.remove(AppConstants.keyAuthToken);
      await _prefs.remove(AppConstants.keyRefreshToken);
    } catch (e) {
      throw StorageException('Error al limpiar tokens: $e');
    }
  }
}
