import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/route_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/network/http_api_client.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_auth_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/profile/services/profile_service.dart';
import '../widgets/app_alert_banner.dart';

/// Inyectado en main tras obtener SharedPreferences.getInstance().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'SharedPreferences debe overridearse en main con el valor de getInstance()',
  );
});

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthLocalDatasourceImpl(prefs);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final local = ref.watch(authLocalDatasourceProvider);
  return HttpApiClient(getToken: () => local.getStoredToken());
});

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasourceReal(ref.watch(apiClientProvider));
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(apiClientProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(apiClientProvider),
    ref.watch(authLocalDatasourceProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDatasourceProvider),
    ref.watch(authLocalDatasourceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final checkAuthUseCaseProvider = Provider<CheckAuthUseCase>((ref) {
  return CheckAuthUseCase(ref.watch(authRepositoryProvider));
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(
    this._loginUseCase,
    this._logoutUseCase,
    this._getCurrentUser,
    this._checkAuth,
    this._authService,
    this._authRepository,
  ) : super(const AuthState()) {
    checkAuth();
  }

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUser;
  final CheckAuthUseCase _checkAuth;
  final AuthService _authService;
  final AuthRepository _authRepository;

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    final isLoggedIn = await _checkAuth();
    if (isLoggedIn) {
      final user = await _getCurrentUser();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _loginUseCase(email, password);
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error al iniciar sesión',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } on NetworkException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e, st) {
      debugPrint('! AuthController login error: $e\n$st');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'No se pudo conectar. Revisa tu internet e intenta de nuevo.',
      );
      return false;
    }
  }

  Future<bool> loginWithNip(String userName, String codigo) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authService.loginWithNip(userName, codigo);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } on NetworkException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e, st) {
      debugPrint('! AuthController loginWithNip error: $e\n$st');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'No se pudo conectar. Intenta de nuevo.',
      );
      return false;
    }
  }


  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _logoutUseCase();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Recuperar acceso: envía correo con instrucciones. Muestra banner y navega a login si éxito.
  Future<void> recuperarAcceso({
    required BuildContext context,
    required String userName,
  }) async {
    final trimmed = userName.trim();
    if (trimmed.isEmpty) {
      debugPrint('! AuthController recuperarAcceso: userName vacío');
      if (context.mounted) {
        showAppAlertBanner(
          context,
          type: AppAlertType.error,
          title: 'Error',
          message: 'El correo electrónico es obligatorio.',
        );
      }
      return;
    }

    try {
      await _authRepository.recuperarAcceso(trimmed);
      if (!context.mounted) return;
      debugPrint('AuthController recuperarAcceso: correo de recuperación enviado correctamente');
      showAppAlertBanner(
        context,
        type: AppAlertType.success,
        title: 'Correo enviado',
        message: 'Se han enviado las instrucciones a tu correo electrónico.',
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteConstants.login,
        (route) => false,
      );
      debugPrint('AuthController recuperarAcceso: navegación a login realizada');
    } on AuthException catch (e) {
      debugPrint('! AuthController recuperarAcceso AuthException: $e');
      if (context.mounted) {
        showAppAlertBanner(
          context,
          type: AppAlertType.error,
          title: 'Error',
          message: e.message,
        );
      }
    } on NetworkException catch (e) {
      debugPrint('! AuthController recuperarAcceso NetworkException: $e');
      if (context.mounted) {
        showAppAlertBanner(
          context,
          type: AppAlertType.error,
          title: 'Error',
          message: e.message,
        );
      }
    } catch (e, st) {
      debugPrint('! AuthController recuperarAcceso error: $e\n$st');
      if (context.mounted) {
        showAppAlertBanner(
          context,
          type: AppAlertType.error,
          title: 'Error',
          message: 'No fue posible enviar el correo de recuperación. Verifica tu información.',
        );
      }
    }
  }

  /// Cambiar contraseña desde link de recuperación (token en URL). Muestra banner y navega a login si éxito.
  Future<void> cambiarContrasenaDesdeRecuperacion({
    required BuildContext context,
    required String token,
    required String passwordNueva,
    required String passwordConfirmacion,
  }) async {
    final p1 = passwordNueva.trim();
    final p2 = passwordConfirmacion.trim();

    if (token.isEmpty) {
      debugPrint('! AuthController cambiarContrasenaDesdeRecuperacion: token vacío');
      if (context.mounted) {
        showAppAlertBanner(
          context,
          type: AppAlertType.error,
          title: 'Error',
          message: 'Token inválido o no proporcionado.',
        );
      }
      return;
    }
    if (p1.isEmpty || p2.isEmpty) {
      debugPrint('! AuthController cambiarContrasenaDesdeRecuperacion: contraseñas vacías');
      if (context.mounted) {
        showAppAlertBanner(
          context,
          type: AppAlertType.error,
          title: 'Error',
          message: 'La contraseña y su confirmación son obligatorias.',
        );
      }
      return;
    }
    if (p1 != p2) {
      debugPrint('! AuthController cambiarContrasenaDesdeRecuperacion: contraseñas no coinciden');
      if (context.mounted) {
        showAppAlertBanner(
          context,
          type: AppAlertType.error,
          title: 'Error',
          message: 'Las contraseñas no coinciden.',
        );
      }
      return;
    }

    try {
      await _authRepository.cambiarContrasenaDesdeRecuperacion(
        token: token,
        passwordNueva: p1,
        passwordConfirmacion: p2,
      );
      if (!context.mounted) return;
      debugPrint('AuthController cambiarContrasenaDesdeRecuperacion: contraseña actualizada correctamente.');
      showAppAlertBanner(
        context,
        type: AppAlertType.success,
        title: 'Contraseña actualizada',
        message: 'Tu contraseña ha sido actualizada exitosamente.',
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteConstants.login,
        (route) => false,
      );
      debugPrint('AuthController cambiarContrasenaDesdeRecuperacion: navegación a login realizada');
    } on AuthException catch (e) {
      debugPrint('! AuthController cambiarContrasenaDesdeRecuperacion AuthException: $e');
      if (context.mounted) {
        final message = e.code == '400'
            ? 'La nueva contraseña no puede ser igual a la anterior.'
            : e.message;
        showAppAlertBanner(
          context,
          type: AppAlertType.error,
          title: 'Error',
          message: message,
        );
      }
    } on NetworkException catch (e) {
      debugPrint('! AuthController cambiarContrasenaDesdeRecuperacion NetworkException: $e');
      if (context.mounted) {
        showAppAlertBanner(
          context,
          type: AppAlertType.error,
          title: 'Error',
          message: e.message,
        );
      }
    } catch (e, st) {
      debugPrint('! AuthController cambiarContrasenaDesdeRecuperacion error: $e\n$st');
      if (context.mounted) {
        showAppAlertBanner(
          context,
          type: AppAlertType.error,
          title: 'Error',
          message: 'No fue posible actualizar la contraseña. Intenta nuevamente.',
        );
      }
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(loginUseCaseProvider),
    ref.watch(logoutUseCaseProvider),
    ref.watch(getCurrentUserUseCaseProvider),
    ref.watch(checkAuthUseCaseProvider),
    ref.watch(authServiceProvider),
    ref.watch(authRepositoryProvider),
  );
});
