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

**Implementación:** `HttpApiClient` usa `AppEnvironmentConfig.baseUrl`, headers `Content-Type`/`Accept` JSON. Recibe: `getToken` (callback para obtener el access token), `refreshToken` (callback `Future<String?> Function()` para renovar token) y `onSessionExpired` (callback void). En paths que contienen `"login"` o `"refresh"` no se envía Authorization. Ante 401 o 403 en una request protegida, se intenta una vez `refreshToken()`; si retorna un token se reintenta la request original; si falla o lanza se llama `onSessionExpired()` y se lanza. Solo un refresh en vuelo (Completer) para evitar bucles. Ver **14-plan-refresh-token-implementacion.md**.

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
| `AppEnvironmentConfig.faceAuthBaseUrl` | `String`: URL base del API Face Auth (BehaviorIQ). Usada por FaceAuthRemoteDatasource para login, auth/me, embed, validateFace. |
| `AppEnvironmentConfig.faceAuthLivenessBaseUrl` | `String?`: URL opcional solo para POST `/embed/liveness-check`. Si no null, se usa en lugar de faceAuthBaseUrl para esa llamada. |

El `ApiClient` (HttpApiClient) usa `baseUrl` para las peticiones principales. Face Auth usa su propio cliente HTTP en `FaceAuthRemoteDatasource` con `faceAuthBaseUrl` y, si aplica, `faceAuthLivenessBaseUrl`.

---

### 2.1.5 AppConstants

**Ubicación:** `lib/core/constants/app_constants.dart`

Claves de persistencia (SharedPreferences) para sesión y tema. Contrato: nombres de keys estables para `TokenStorageService`, `AuthLocalDatasource` y `ThemeController`: `keyAuthToken`, `keyRefreshToken`, `keyUserId`, `keyThemeMode`, etc.

---

### 2.1.6 TokenStorageService

**Ubicación:** `lib/core/auth/token_storage_service.dart`

Servicio central para almacenamiento de access token y refresh token. No se accede a SharedPreferences para tokens desde otras partes del código.

| Método | Firma | Contrato |
|--------|--------|----------|
| saveToken | `Future<void> saveToken(String token)` | Persiste access token. Lanza `StorageException` si falla. |
| getToken | `Future<String?> getToken()` | Devuelve access token o null. |
| saveRefreshToken | `Future<void> saveRefreshToken(String refreshToken)` | Persiste refresh token. |
| getRefreshToken | `Future<String?> getRefreshToken()` | Devuelve refresh token o null. |
| clearTokens | `Future<void> clearTokens()` | Borra token y refreshToken. |

**Implementación:** `TokenStorageServiceImpl(SharedPreferences)` usa `AppConstants.keyAuthToken` y `keyRefreshToken`.

---

### 2.1.7 RefreshTokenRunner

**Ubicación:** `lib/core/auth/refresh_token_runner.dart`

Ejecuta POST /api/auth/refresh usando `package:http` directo (no ApiClient) para evitar ciclos cuando el cliente recibe 401. Depende de `TokenStorageService` y de la baseUrl.

| Método | Firma | Contrato |
|--------|--------|----------|
| run | `Future<String?> run()` | Obtiene refreshToken de TokenStorageService; POST body `{ "refreshToken": "..." }`; si 200 guarda nuevo token y refreshToken y retorna el token; si 401/403 lanza `AuthException`; en otro error retorna null. No imprime tokens completos en logs. |

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
| login | `Future<LoginResult> login(String email, String password)` | POST al endpoint de login. Retorna `LoginResult(user, token, refreshToken?)`. Si el backend envía `refreshToken` en la respuesta, se incluye en el resultado. |
| refreshToken | `Future<RefreshResult> refreshToken(String refreshToken)` | POST `/api/auth/refresh` con body `{ "refreshToken": "..." }` (path sin Authorization). Retorna `RefreshResult(token, refreshToken)`. 401/403 → AuthException. |
| recuperarAcceso | `Future<void> recuperarAcceso({required String userName})` | POST con body `{ "userName": userName }`. Éxito 201. |
| cambiarContrasenaDesdeRecuperacion | `Future<void> cambiarContrasenaDesdeRecuperacion({required String token, required String passwordNueva, required String passwordConfirmacion})` | POST con header `Authorization: Bearer token` y body `{ "passwordNueva", "passwordConfirmacion" }`. Éxito 201. |

`LoginResult`: `user: UserModel`, `token: String`, `refreshToken: String?`. `RefreshResult`: `token: String`, `refreshToken: String`.

---

### 2.3.2 AuthLocalDatasource

**Ubicación:** `lib/data/datasources/local/auth_local_datasource.dart`

Interfaz de persistencia local de sesión. Depende de **TokenStorageService** para token y refreshToken (no escribe/lee directamente las claves de tokens).

| Método | Firma | Contrato |
|--------|--------|----------|
| saveSession | `Future<void> saveSession(UserModel user, String token, {String? refreshToken})` | Persiste token (y opcional refreshToken) vía TokenStorageService; persiste datos de usuario en SharedPreferences. Lanza `StorageException` si falla. |
| clearSession | `Future<void> clearSession()` | Llama a TokenStorageService.clearTokens() y borra datos de usuario de sesión (no borra último correo NIP). |
| getStoredUser | `Future<UserModel?> getStoredUser()` | Devuelve usuario guardado o null. |
| getStoredToken | `Future<String?> getStoredToken()` | Delega en TokenStorageService.getToken(). |
| hasSession | `Future<bool> hasSession()` | Indica si hay sesión guardada. |
| saveLastLoginEmail | `Future<void> saveLastLoginEmail(String email)` | Guarda último correo (login NIP). |
| getLastLoginEmail | `Future<String?> getLastLoginEmail()` | Recupera último correo. |

---

### 2.3.3 AuthRepositoryImpl

**Ubicación:** `lib/data/repositories/auth_repository_impl.dart`

Implementa `AuthRepository`. Depende de `AuthRemoteDatasource` y `AuthLocalDatasource`. Convierte `UserModel` a `UserEntity` donde corresponda; delega login en remote + saveSession en local; resto de métodos delegan en el datasource correspondiente. Propaga `AppException` sin traducir.

---

### 2.3.4 FaceAuthRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/face_auth_remote_datasource.dart`

Fuente de datos remota para el flujo Face Auth (API BehaviorIQ). Usa `faceAuthBaseUrl` y, para liveness-check, `faceAuthLivenessBaseUrl` si está definida. No usa el ApiClient principal; hace peticiones con `package:http` (multipart para imágenes).

| Método | Firma | Contrato |
|--------|--------|----------|
| login | `Future<FaceAuthLoginResult> login(String usuario, String contrasena)` | POST `auth/login` JSON `{ usuario, contrasena }` → `accessToken`. |
| me | `Future<FaceAuthMeResult> me(String token)` | GET `auth/me` Bearer → `idCliente` (requerido), `idUsuario`, `idSolucion`, `usuario`, `isRoot`, `rol`. Usado en Face Auth y en Inicio de Turno para obtener idCliente/idSolucion antes de GET /placas/validar. |
| livenessCheck | `Future<FaceAuthLivenessResult> livenessCheck(String token, List<int> image1, List<int> image2)` | POST `embed/liveness-check` multipart dos archivos campo `files` (capture_0.jpg, capture_1.jpg, image/jpeg) → `passed`, `reason`, `score?`. |
| embed | `Future<List<double>> embed(String token, List<int> imageBytes)` | POST `embed` multipart un archivo campo `file` (capture.jpg) → array 512D (InsightFace ArcFace). |
| validateFace | `Future<FaceAuthValidateResult> validateFace(String token, String idCliente, List<double> embedding)` | POST `auth/validateFace/{idCliente}` JSON `{ "embeddings": [ 512 números ] }` → `success`, `nombre`, `paterno`, `materno`, `distancia`. 404 → AuthException("404"). |

**FaceAuthMeResult:** `idCliente` (String, requerido), `idUsuario` (int?), `idSolucion` (dynamic), `usuario` (String?), `isRoot` (bool?), `rol` (String?). Contrato detallado en **06-plan-face-auth-api-rest.md** y **11-plan-api-auth-me-integracion.md**.

---

### 2.3.5 PlateReadRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/plate_read_remote_datasource.dart`

Fuente de datos remota para lectura de placa (OCR) en el flujo Inicio de Turno → Seleccionar Vehículo. Usa `faceAuthBaseUrl`. No usa el ApiClient principal; hace peticiones con `package:http` (multipart).

| Método | Firma | Contrato |
|--------|--------|----------|
| readPlate | `Future<PlateReadResult> readPlate(String token, List<int> imageBytes)` | POST `plate/read` multipart/form-data campo `file` (imagen JPEG). Headers: `Accept: application/json`, `Authorization: Bearer $token`. 200/201 → `PlateReadResult(plateNumber, confidence?)`. 400/404 → NetworkException ("No se detectó placa..."); 403 → "Servicio no habilitado"; 503 → "Servicio no disponible"; 401 → AuthException. |

**PlateReadResult:** `plateNumber: String`, `confidence: double?`. Contrato del servicio en **10-plan-api-plate-read-integracion.md**.

---

### 2.3.6 PlacasValidarRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/placas_validar_remote_datasource.dart`

Fuente de datos remota para validar si una placa está registrada en el contexto del usuario (API BehaviorIQ). Usa `faceAuthBaseUrl`. No usa el ApiClient principal; hace peticiones con `package:http`.

| Método | Firma | Contrato |
|--------|--------|----------|
| validar | `Future<PlacasValidarResult> validar(String token, String numeroPlaca, {int? idCliente, int? idSolucion, double? latitud, double? longitud})` | GET `placas/validar` con query params `numeroPlaca` (obligatorio), `idCliente`, `idSolucion`, `latitud`, `longitud` (opcionales). Headers: `Accept: application/json`, `Authorization: Bearer $token`. Respuesta 200 → parseo a `PlacasValidarResult`. 401 → AuthException; 4xx/5xx → NetworkException. |

**PlacasValidarResult:** modelo con `registered: bool`, `idPlaca: int?`, `placa: String?`, `marca: String?`, `modelo: String?`, `anio: int?`, `color: String?`, `economico: String?`. Contrato del servicio en **12-plan-api-placas-validar-integracion.md**.

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
| setSessionFromFaceAuth | `Future<void> setSessionFromFaceAuth(UserEntity user, String token)` | Persiste sesión (saveSession) y actualiza state a authenticated con el user. Usado por FaceAuthFlowPage tras validateFace exitoso. |
| logout | `Future<void> logout()` | Llama LogoutUseCase y pone state en unauthenticated. |
| recuperarAcceso | `Future<void> recuperarAcceso({required BuildContext context, required String userName})` | Valida no vacío; llama repository. Éxito: banner success + pushNamedAndRemoveUntil(login). Error: banner error. Usa context.mounted antes de UI. |
| cambiarContrasenaDesdeRecuperacion | `Future<void> cambiarContrasenaDesdeRecuperacion({required BuildContext context, required String token, required String passwordNueva, required String passwordConfirmacion})` | Valida token y coincidencia de contraseñas; llama repository. Éxito: banner success + pushNamedAndRemoveUntil(login). Error 400 u otros: banner error. |

---

### 2.4.3 Providers (Riverpod)

**Ubicación:** `lib/presentation/controllers/auth_controller.dart` (y main)

| Provider | Tipo | Contrato |
|----------|------|----------|
| sharedPreferencesProvider | `Provider<SharedPreferences>` | Debe overridearse en main con el valor de `SharedPreferences.getInstance()`. |
| tokenStorageServiceProvider | `Provider<TokenStorageService>` | TokenStorageServiceImpl(sharedPreferencesProvider). |
| refreshTokenRunnerProvider | `Provider<RefreshTokenRunner>` | RefreshTokenRunner(tokenStorageService, AppEnvironmentConfig.baseUrl). Usado por HttpApiClient para renovar token ante 401/403. |
| sessionExpiredTriggerProvider | `StateProvider<int>` | Al incrementarse, el listener en la app (p. ej. TurnosSpringApp) ejecuta AuthController.logout() para cerrar sesión automáticamente cuando el refresh falla. |
| authLocalDatasourceProvider | `Provider<AuthLocalDatasource>` | AuthLocalDatasourceImpl(prefs, tokenStorageServiceProvider). |
| apiClientProvider | `Provider<ApiClient>` | HttpApiClient(getToken: tokenStorage.getToken, refreshToken: refreshTokenRunner.run, onSessionExpired: incrementa sessionExpiredTriggerProvider). |
| authRemoteDatasourceProvider | `Provider<AuthRemoteDatasource>` | Devuelve `AuthRemoteDatasourceReal(apiClient)`. |
| authRepositoryProvider | `Provider<AuthRepository>` | Devuelve `AuthRepositoryImpl(remote, local)`. |
| loginUseCaseProvider | `Provider<LoginUseCase>` | Depende de authRepositoryProvider. |
| logoutUseCaseProvider | `Provider<LogoutUseCase>` | Idem. |
| getCurrentUserUseCaseProvider | `Provider<GetCurrentUserUseCase>` | Idem. |
| checkAuthUseCaseProvider | `Provider<CheckAuthUseCase>` | Idem. |
| authServiceProvider | `Provider<AuthService>` | AuthService(apiClient, authLocalDatasource). |
| faceAuthRemoteDatasourceProvider | `Provider<FaceAuthRemoteDatasource>` | FaceAuthRemoteDatasourceImpl() (usa faceAuthBaseUrl y faceAuthLivenessBaseUrl). |
| faceAuthServiceProvider | `Provider<FaceAuthService>` | FaceAuthService(faceAuthRemoteDatasourceProvider). |
| plateReadRemoteDatasourceProvider | `Provider<PlateReadRemoteDatasource>` | PlateReadRemoteDatasourceImpl() (usa faceAuthBaseUrl; POST /plate/read). |
| placasValidarRemoteDatasourceProvider | `Provider<PlacasValidarRemoteDatasource>` | PlacasValidarRemoteDatasourceImpl() (usa faceAuthBaseUrl; GET /placas/validar). |
| placaValidadaProvider | `StateProvider<PlacasValidarResult?>` | Estado global del resultado de GET /placas/validar. Inicio de Turno lo escribe al validar la placa y lo limpia al identificar una nueva; Apertura de Turno (CapturaOdometroPage) y otras pantallas lo leen para mostrar placa, marca, modelo, año y económico. Ubicación: `lib/presentation/turnos/placa_validada_provider.dart`. |
| authControllerProvider | `StateNotifierProvider<AuthController, AuthState>` | AuthController(login, logout, getCurrentUser, checkAuth, authService, authRepository). |

---

### 2.4.4 Rutas y pantallas

- **Login:** `RouteConstants.login` → `LoginPage` (incluye botón "Reconocimiento facial" que abre FaceAuthFlowPage con push).
- **Face Auth:** No es ruta estática; se abre con `Navigator.push(context, MaterialPageRoute(builder: (_) => FaceAuthFlowPage()))` desde LoginPage. Al éxito se llama setSessionFromFaceAuth y pushNamedAndRemoveUntil(home).
- **Home:** `RouteConstants.home` → `MainShell` (drawer + tabs).
- **Nueva contraseña:** `RouteConstants.nuevaContrasena` o ruta con query `?token=...` → `NuevaContrasenaPage(token: queryToken)`.
- **Inicio de Turno:** Tras identificar placa (IdentificarPlacaPage) se llama GET /placas/validar; el resultado se guarda en `placaValidadaProvider`. El **header** muestra solo Folio: Pendiente, Fecha y Lugar (no placa, marca, modelo, año ni económico). El botón **Continuar** se habilita solo cuando `placaValidadaProvider` tiene `registered == true`. Al pulsar Continuar se navega a Captura de odómetro (la pantalla lee del provider).
- **Apertura de Turno (Captura de odómetro):** `CapturaOdometroPage` construye la tarjeta del vehículo con `ref.watch(placaValidadaProvider)`. Orden de datos en la card: Placa, Económico, Año, Marca/Modelo (sin hora). Pill de placa alineado.
- **Cierre de Turno:** No se abre cámara de placa; datos del vehículo desde `placaValidadaProvider`. Info box con texto específico de cierre ("fotografía de resguardo...").
- **Resumen de Turno:** Card "Información General" con vehículo (`placaValidadaProvider`) y operador (`authControllerProvider`).
- **Control de Turnos:** Card "Estado Actual" con datos del vehículo desde `placaValidadaProvider`.
- Navegación post-éxito recuperación/cambio contraseña: `Navigator.pushNamedAndRemoveUntil(context, RouteConstants.login, (route) => false)`.

---

### 2.4.5 Convenciones de UI por flujo

Contrato de comportamiento de pantallas para mantener coherencia.

| Flujo / pantalla | Convención |
|------------------|------------|
| **Face Auth** | Mensajes claros de éxito/error; en fallo de verificación pantalla "No pudimos verificar tu rostro" con Reintentar / Volver al login; sin banner duplicado; estados de carga "Verificando tu identidad" y "Analizando..." durante liveness/embed/validateFace. |
| **Inicio de Turno** | Sin card "Asignación Requerida"; card única de vehículo/operador; selector de vehículo con subtítulo "Placa registrada" cuando la placa está validada; header solo Folio, Fecha, Lugar; Continuar habilitado solo con placa registrada. |
| **Apertura de Turno** | Primera card: Placa, Económico, Año, Marca/Modelo (sin hora); pill de placa alineado; datos desde `placaValidadaProvider`. |
| **Cierre de Turno** | Datos desde `placaValidadaProvider`; no cámara de placa; texto del info box específico de cierre. |
| **Resumen de Turno** | Card "Información General": vehículo (`placaValidadaProvider`) y operador (`authControllerProvider`). |
| **Control de Turnos** | Card "Estado Actual": datos del vehículo desde `placaValidadaProvider`. |

---

## 2.5 Features (servicios transversales)

### 2.5.1 AuthService

**Ubicación:** `lib/features/auth/services/auth_service.dart`

Login por NIP. Depende de `ApiClient` y `AuthLocalDatasource`. Método relevante: `Future<UserModel> loginWithNip(String userName, String codigo)`; hace POST y guarda sesión; lanza `AuthException` en error. No maneja UI.

### 2.5.2 FaceAuthService

**Ubicación:** `lib/features/auth/services/face_auth_service.dart`

Orquesta los pasos Face Auth. Depende de `FaceAuthRemoteDatasource`.

| Método | Firma | Contrato |
|--------|--------|----------|
| loginAndGetIdCliente | `Future<FaceAuthCredentialsResult> loginAndGetIdCliente(String usuario, String contrasena)` | Ejecuta login → me; retorna token e idCliente (pasos 1 y 2). |
| livenessEmbedAndValidateFace | `Future<FaceAuthValidateResult> livenessEmbedAndValidateFace({ required String token, required String idCliente, required Uint8List capture1, required Uint8List capture2 })` | livenessCheck(capture1, capture2) → si passed, embed(capture2) → validateFace(idCliente, embedding). Lanza AuthException si liveness no pasa o validateFace 404. |

---

### 2.5.3 ProfileService

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
                → Core (ApiClient, AppException, Constants, TokenStorageService)
Core (HttpApiClient)
    → TokenStorageService (getToken), RefreshTokenRunner (refreshToken callback), sessionExpiredTriggerProvider (onSessionExpired)
Data (AuthLocalDatasourceImpl)
    → TokenStorageService (saveToken, saveRefreshToken, getToken, clearTokens)
Features (AuthService, FaceAuthService, ProfileService)
    → Core (ApiClient), Data (AuthLocalDatasource cuando aplica)
    → Data (FaceAuthRemoteDatasource) → Core (AppException, config faceAuthBaseUrl)

Turnos (Inicio de Turno, Identificar placa, Captura de odómetro):
    → Data (PlateReadRemoteDatasource para POST /plate/read, PlacasValidarRemoteDatasource para GET /placas/validar, FaceAuthRemoteDatasource.me para idCliente/idSolucion)
    → Presentation (placaValidadaProvider: StateProvider<PlacasValidarResult?>)
```

**Refresh token:** HttpApiClient no depende de AuthRepository ni AuthController; recibe callbacks (getToken desde TokenStorageService, refreshToken desde RefreshTokenRunner.run, onSessionExpired que incrementa sessionExpiredTriggerProvider). El listener de sessionExpiredTriggerProvider en la app llama a AuthController.logout(). RefreshTokenRunner usa `http` directo para POST /api/auth/refresh y evita ciclos con ApiClient.

Face Auth: FaceAuthFlowPage usa FaceAuthService; no pasa por AuthRepository para login; al éxito llama AuthController.setSessionFromFaceAuth (que sí usa AuthRepository.saveSession). Las capas superiores no conocen implementaciones concretas de las inferiores; solo interfaces y contratos descritos en este documento.
