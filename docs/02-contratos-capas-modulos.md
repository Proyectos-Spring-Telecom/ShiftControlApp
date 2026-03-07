# 2. Contratos por capas y módulos

Este documento define los contratos (interfaces, firmas y convenciones) que deben cumplir las distintas capas y módulos de la aplicación.

---

## 2.1 Core

### 2.1.1 ApiClient

**Ubicación:** `lib/core/network/api_client.dart`

Contrato del cliente HTTP. Las respuestas 2xx se consideran éxito; en 4xx/5xx la implementación debe lanzar `AuthException` o `NetworkException`.

| Método | Firma | Notas |
|--------|--------|--------|
| get | `Future<Map<String, dynamic>> get(String path, {Map<String, String>? headers})` | Cuerpo vacío → `{}`. Errores vía excepción. |
| post | `Future<Map<String, dynamic>> post(String path, {dynamic body, Map<String, String>? headers})` | Body típicamente `Map`; se serializa a JSON. |
| put | `Future<Map<String, dynamic>> put(String path, {dynamic body, Map<String, String>? headers})` | Idem. |
| patch | `Future<Map<String, dynamic>> patch(String path, {dynamic body, Map<String, String>? headers})` | Idem. |
| delete | `Future<Map<String, dynamic>> delete(String path, {Map<String, String>? headers})` | Idem. |

**Implementación:** `HttpApiClient` usa `AppEnvironmentConfig.baseUrl`, headers `Content-Type`/`Accept` JSON y opcionalmente `Authorization: Bearer` desde un callback `getToken`. En paths que contienen `"login"` no se envía Authorization.

---

### 2.1.2 AppException y subclases

**Ubicación:** `lib/core/errors/app_exception.dart`

| Tipo | Uso |
|------|-----|
| `AppException` (sealed) | Base: `message`, `code` opcional. |
| `AuthException` | Credenciales, token, 401, 400. |
| `NetworkException` | Errores de red, 404, 500, etc. |
| `StorageException` | Fallos de persistencia local. |

Ningún contrato devuelve códigos HTTP; la capa de datos traduce a estas excepciones.

---

### 2.1.3 RouteConstants

**Ubicación:** `lib/core/constants/route_constants.dart`

| Constante / método | Valor / comportamiento |
|--------------------|------------------------|
| `login` | `'/login'` |
| `home` | `'/home'` |
| `profile` | `'/profile'` |
| `nuevaContrasena` | `'/nueva-contrasena'` |
| `nuevaContrasenaWithToken(String token)` | `'/nueva-contrasena?token=' + Uri.encodeComponent(token)` |

Las rutas se usan en `MaterialApp.initialRoute`, `Navigator.pushNamed`/`pushNamedAndRemoveUntil` y en `AppRouter.onGenerateRouteStatic` (el `name` puede incluir query; el router normaliza por path).

---

### 2.1.4 AppEnvironmentConfig

**Ubicación:** `lib/config/app_environment.dart`

| Elemento | Contrato |
|----------|----------|
| `AppEnvironment` | enum: `dev`, `qa`, `prod`. |
| `current` | Variable global que fija el ambiente activo. |
| `AppEnvironmentConfig.baseUrl` | getter `String`: URL base del API (puede incluir barra final). Para `qa` se concatena el segmento `/qa` según implementación. |

El `ApiClient` (HttpApiClient) usa esta base para todas las peticiones.

---

### 2.1.5 AppConstants

**Ubicación:** `lib/core/constants/app_constants.dart`

Claves de persistencia (SharedPreferences) para sesión y tema. Contrato: nombres de keys estables para `AuthLocalDatasource` y `ThemeController` (ej. `keyAuthToken`, `keyUserId`, `keyThemeMode`, etc.).

---

## 2.2 Capa de dominio

### 2.2.1 AuthRepository

**Ubicación:** `lib/domain/repositories/auth_repository.dart`

Interfaz del repositorio de autenticación. Retorna entidades de dominio o tipos simples; no expone DTOs ni detalles de red/almacenamiento.

| Método | Firma | Comportamiento |
|--------|--------|----------------|
| login | `Future<UserEntity?> login(String email, String password)` | Login; persiste sesión internamente. Lanza `AppException` en error. |
| logout | `Future<void> logout()` | Borra sesión local. |
| getCurrentUser | `Future<UserEntity?> getCurrentUser()` | Usuario almacenado o null. |
| isLoggedIn | `Future<bool> isLoggedIn()` | Indica si hay sesión válida. |
| recuperarAcceso | `Future<void> recuperarAcceso(String userName)` | Envía correo de recuperación. Lanza en error. |
| cambiarContrasenaDesdeRecuperacion | `Future<void> cambiarContrasenaDesdeRecuperacion({required String token, required String passwordNueva, required String passwordConfirmacion})` | Cambio de contraseña con token JWT; no requiere sesión. Lanza en error. |

---

### 2.2.2 UserEntity

**Ubicación:** `lib/domain/entities/user_entity.dart`

Entidad de dominio del usuario. Campos: `id`, `email`, `name` (requeridos); `roleName`, `apellidoPaterno`, `apellidoMaterno`, `telefono`, `userName`, `fotoPerfil` (opcionales). Inmutable.

---

### 2.2.3 Casos de uso (Use cases)

Todos reciben el repositorio o dependencias por constructor y exponen un método `call` (o equivalente).

| Caso de uso | Dependencia | Firma `call` |
|-------------|-------------|--------------|
| LoginUseCase | AuthRepository | `Future<UserEntity?> call(String email, String password)` |
| LogoutUseCase | AuthRepository | `Future<void> call()` |
| GetCurrentUserUseCase | AuthRepository | `Future<UserEntity?> call()` |
| CheckAuthUseCase | AuthRepository | `Future<bool> call()` |

---

## 2.3 Capa de datos

### 2.3.1 AuthRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/auth_remote_datasource.dart`

Interfaz de la fuente de datos remota de autenticación. No conoce UI ni navegación; lanza `AuthException`/`NetworkException` en errores HTTP.

| Método | Firma | Contrato |
|--------|--------|----------|
| login | `Future<LoginResult> login(String email, String password)` | POST al endpoint de login. Retorna `LoginResult(user, token)`. |
| recuperarAcceso | `Future<void> recuperarAcceso({required String userName})` | POST con body `{ "userName": userName }`. Éxito 201. |
| cambiarContrasenaDesdeRecuperacion | `Future<void> cambiarContrasenaDesdeRecuperacion({required String token, required String passwordNueva, required String passwordConfirmacion})` | POST con header `Authorization: Bearer token` y body `{ "passwordNueva", "passwordConfirmacion" }`. Éxito 201. |

`LoginResult` es un DTO interno: `user: UserModel`, `token: String`.

---

### 2.3.2 AuthLocalDatasource

**Ubicación:** `lib/data/datasources/local/auth_local_datasource.dart`

Interfaz de persistencia local de sesión (SharedPreferences).

| Método | Firma | Contrato |
|--------|--------|----------|
| saveSession | `Future<void> saveSession(UserModel user, String token)` | Persiste token y datos de usuario. Lanza `StorageException` si falla. |
| clearSession | `Future<void> clearSession()` | Borra token y datos de sesión (no borra último correo NIP). |
| getStoredUser | `Future<UserModel?> getStoredUser()` | Devuelve usuario guardado o null. |
| getStoredToken | `Future<String?> getStoredToken()` | Devuelve token o null. |
| hasSession | `Future<bool> hasSession()` | Indica si hay sesión guardada. |
| saveLastLoginEmail | `Future<void> saveLastLoginEmail(String email)` | Guarda último correo (login NIP). |
| getLastLoginEmail | `Future<String?> getLastLoginEmail()` | Recupera último correo. |

---

### 2.3.3 AuthRepositoryImpl

**Ubicación:** `lib/data/repositories/auth_repository_impl.dart`

Implementa `AuthRepository`. Depende de `AuthRemoteDatasource` y `AuthLocalDatasource`. Convierte `UserModel` a `UserEntity` donde corresponda; delega login en remote + saveSession en local; resto de métodos delegan en el datasource correspondiente. Propaga `AppException` sin traducir.

---

## 2.4 Presentación

### 2.4.1 AppRouter

**Ubicación:** `lib/presentation/app_router.dart`

- **onGenerateRouteStatic(RouteSettings settings):** `Route<dynamic>?`
  - Normaliza `settings.name`: si contiene `?`, extrae `path` y `queryParameters['token']`.
  - Switch por `path`: `RouteConstants.login` → LoginPage; `home` → MainShell; `nuevaContrasena` → NuevaContrasenaPage(token: queryToken). Default → LoginPage.
  - No realiza lógica de negocio; solo construye rutas.

---

### 2.4.2 AuthController (contrato público)

**Ubicación:** `lib/presentation/controllers/auth_controller.dart`

Estado: `AuthState(status, user, errorMessage)`. Estados: `initial`, `loading`, `authenticated`, `unauthenticated`, `error`.

| Método | Firma | Contrato |
|--------|--------|----------|
| login | `Future<bool> login(String email, String password)` | Valida, llama LoginUseCase, actualiza state; retorna true si éxito. En error muestra mensaje en state; no muestra banner (lo hace la UI si lo desea). |
| loginWithNip | `Future<bool> loginWithNip(String userName, String codigo)` | Delega en AuthService; actualiza state. |
| logout | `Future<void> logout()` | Llama LogoutUseCase y pone state en unauthenticated. |
| recuperarAcceso | `Future<void> recuperarAcceso({required BuildContext context, required String userName})` | Valida no vacío; llama repository. Éxito: banner success + pushNamedAndRemoveUntil(login). Error: banner error. Usa context.mounted antes de UI. |
| cambiarContrasenaDesdeRecuperacion | `Future<void> cambiarContrasenaDesdeRecuperacion({required BuildContext context, required String token, required String passwordNueva, required String passwordConfirmacion})` | Valida token y coincidencia de contraseñas; llama repository. Éxito: banner success + pushNamedAndRemoveUntil(login). Error 400 u otros: banner error. |

---

### 2.4.3 Providers (Riverpod)

**Ubicación:** `lib/presentation/controllers/auth_controller.dart` (y main)

| Provider | Tipo | Contrato |
|----------|------|----------|
| sharedPreferencesProvider | `Provider<SharedPreferences>` | Debe overridearse en main con el valor de `SharedPreferences.getInstance()`. |
| authLocalDatasourceProvider | `Provider<AuthLocalDatasource>` | Devuelve `AuthLocalDatasourceImpl(prefs)`. |
| apiClientProvider | `Provider<ApiClient>` | Devuelve `HttpApiClient(getToken: () => local.getStoredToken())`. |
| authRemoteDatasourceProvider | `Provider<AuthRemoteDatasource>` | Devuelve `AuthRemoteDatasourceReal(apiClient)`. |
| authRepositoryProvider | `Provider<AuthRepository>` | Devuelve `AuthRepositoryImpl(remote, local)`. |
| loginUseCaseProvider | `Provider<LoginUseCase>` | Depende de authRepositoryProvider. |
| logoutUseCaseProvider | `Provider<LogoutUseCase>` | Idem. |
| getCurrentUserUseCaseProvider | `Provider<GetCurrentUserUseCase>` | Idem. |
| checkAuthUseCaseProvider | `Provider<CheckAuthUseCase>` | Idem. |
| authServiceProvider | `Provider<AuthService>` | AuthService(apiClient, authLocalDatasource). |
| authControllerProvider | `StateNotifierProvider<AuthController, AuthState>` | AuthController(login, logout, getCurrentUser, checkAuth, authService, authRepository). |

---

### 2.4.4 Rutas y pantallas

- **Login:** `RouteConstants.login` → `LoginPage`.
- **Home:** `RouteConstants.home` → `MainShell` (drawer + tabs).
- **Nueva contraseña:** `RouteConstants.nuevaContrasena` o ruta con query `?token=...` → `NuevaContrasenaPage(token: queryToken)`.
- Navegación post-éxito recuperación/cambio contraseña: `Navigator.pushNamedAndRemoveUntil(context, RouteConstants.login, (route) => false)`.

---

## 2.5 Features (servicios transversales)

### 2.5.1 AuthService

**Ubicación:** `lib/features/auth/services/auth_service.dart`

Login por NIP. Depende de `ApiClient` y `AuthLocalDatasource`. Método relevante: `Future<UserModel> loginWithNip(String userName, String codigo)`; hace POST y guarda sesión; lanza `AuthException` en error. No maneja UI.

### 2.5.2 ProfileService

**Ubicación:** `lib/features/profile/services/profile_service.dart`

Servicios de perfil (cambio de contraseña desde perfil, NIP, etc.) que usan `ApiClient`. Contrato según métodos públicos que expongan (no se detalla aquí cada uno).

---

## 2.6 Utilidades y compatibilidad multiplataforma

### 2.6.1 Ruta inicial (Web)

- **Stub (no web):** `getInitialRouteFromHash()` → `null`.
- **Web:** `getInitialRouteFromHash()` lee `window.location.hash`, parsea path; si es `RouteConstants.nuevaContrasena` retorna esa constante, si no `null`.
- Import condicional: `initial_route_stub.dart` `if (dart.library.html) initial_route_web.dart` as `initial_route`.

### 2.6.2 Lectura de bytes de archivo (path)

- **Stub (web):** `readFileBytes(String path)` → `Future<Uint8List?>.value(null)`.
- **IO (mobile/desktop):** `readFileBytes(String path)` → lee `File(path).readAsBytes()`; en error retorna null.
- Uso: cargar imagen guardada por path en móvil; en web no se puede leer path, se retorna null.

---

## 2.7 Resumen de dependencias entre capas

```
Presentation (UI, Controllers, Router)
    → Domain (Use cases, Entities)
    → Domain (AuthRepository interface)
        → Data (AuthRepositoryImpl)
            → Data (AuthRemoteDatasource, AuthLocalDatasource)
                → Core (ApiClient, AppException, Constants)
Features (AuthService, ProfileService)
    → Core (ApiClient), Data (AuthLocalDatasource cuando aplica)
```

Las capas superiores no conocen implementaciones concretas de las inferiores; solo interfaces y contratos descritos en este documento.
