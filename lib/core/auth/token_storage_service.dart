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
  Future<void> saveTokenExpiry({int? expiresInSeconds});
  Future<int?> getTokenExpiresIn();
  Future<int?> getTokenExpiresAt();
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
  Future<void> saveTokenExpiry({int? expiresInSeconds}) async {
    try {
      if (expiresInSeconds == null || expiresInSeconds <= 0) {
        await _prefs.remove(AppConstants.keyTokenExpiresIn);
        await _prefs.remove(AppConstants.keyTokenExpiresAt);
        return;
      }
      final expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresInSeconds;
      await _prefs.setInt(AppConstants.keyTokenExpiresIn, expiresInSeconds);
      await _prefs.setInt(AppConstants.keyTokenExpiresAt, expiresAt);
    } catch (e) {
      throw StorageException('Error al guardar expiración del token: $e');
    }
  }

  @override
  Future<int?> getTokenExpiresIn() async {
    return _prefs.getInt(AppConstants.keyTokenExpiresIn);
  }

  @override
  Future<int?> getTokenExpiresAt() async {
    return _prefs.getInt(AppConstants.keyTokenExpiresAt);
  }

  @override
  Future<void> clearTokens() async {
    try {
      await _prefs.remove(AppConstants.keyAuthToken);
      await _prefs.remove(AppConstants.keyRefreshToken);
      await _prefs.remove(AppConstants.keyTokenExpiresIn);
      await _prefs.remove(AppConstants.keyTokenExpiresAt);
    } catch (e) {
      throw StorageException('Error al limpiar tokens: $e');
    }
  }
}
