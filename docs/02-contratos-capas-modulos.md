# 2. Contratos por capas y módulos

Este documento define los contratos (interfaces, firmas y convenciones) que deben cumplir las distintas capas y módulos de la aplicación, alineados con la implementación actual contra el **BFF ShiftControl**.

---

## 2.1 Core

### 2.1.1 ApiClient

**Ubicación:** `lib/core/network/api_client.dart`

Contrato del cliente HTTP. Las respuestas 2xx se consideran éxito; en 4xx/5xx la implementación debe lanzar `AuthException` o `NetworkException`.

| Método | Firma | Notas |
|--------|--------|--------|
| get | `Future<Map<String, dynamic>> get(String path, {Map<String, String>? headers})` | Cuerpo vacío → `{}`. |
| post | `Future<Map<String, dynamic>> post(String path, {dynamic body, Map<String, String>? headers})` | Body típicamente `Map`; JSON. |
| put | `Future<Map<String, dynamic>> put(String path, {dynamic body, Map<String, String>? headers})` | Idem. |
| patch | `Future<Map<String, dynamic>> patch(String path, {dynamic body, Map<String, String>? headers})` | Idem. |
| delete | `Future<Map<String, dynamic>> delete(String path, {Map<String, String>? headers})` | Idem. |

**Implementación:** `HttpApiClient` usa `AppEnvironmentConfig.baseUrl`. Recibe `getToken`, `refreshToken` y `onSessionExpired`. En paths que contienen `"login"` o `"refresh"` no se envía `Authorization` automático (salvo que se pase explícitamente en `headers`). Ante 401/403 intenta un refresh; si falla llama `onSessionExpired()`.

---

### 2.1.2 AppException y subclases

**Ubicación:** `lib/core/errors/app_exception.dart`

| Tipo | Uso |
|------|-----|
| `AppException` (sealed) | Base: `message`, `code` opcional. |
| `AuthException` | Credenciales, token, 401, 400, liveness fallido. |
| `NetworkException` | Errores de red, 404, 500, 503, timeout. |
| `StorageException` | Fallos de persistencia local. |

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

---

### 2.1.4 AppEnvironmentConfig

**Ubicación:** `lib/config/app_environment.dart`

| Elemento | Contrato |
|----------|----------|
| `AppEnvironment` | enum: `dev`, `qa`, `prod`. |
| `current` | Variable global que fija el ambiente activo. |
| `AppEnvironmentConfig.baseUrl` | getter `String`: URL base del BFF ShiftControl. QA concatena segmento `/qa`. |

**Nota:** No existen `faceAuthBaseUrl` ni URLs BehaviorIQ. Todos los datasources remotos (auth vía ApiClient, face auth, placas, plate read) usan `baseUrl`.

---

### 2.1.5 AppConstants

**Ubicación:** `lib/core/constants/app_constants.dart`

Claves de persistencia estables: `keyAuthToken`, `keyRefreshToken`, `keyTokenExpiresIn`, `keyTokenExpiresAt`, datos de usuario, checklist, tema, etc.

---

### 2.1.6 TokenStorageService

**Ubicación:** `lib/core/auth/token_storage_service.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| saveToken | `Future<void> saveToken(String token)` | Persiste access token. |
| getToken | `Future<String?> getToken()` | Access token o null. |
| saveRefreshToken | `Future<void> saveRefreshToken(String refreshToken)` | Persiste refresh token. |
| getRefreshToken | `Future<String?> getRefreshToken()` | Refresh token o null. |
| saveTokenExpiry | `Future<void> saveTokenExpiry({int? expiresInSeconds})` | Guarda `expiresIn` y calcula `expiresAt`. |
| getTokenExpiresIn | `Future<int?> getTokenExpiresIn()` | Segundos de validez guardados. |
| getTokenExpiresAt | `Future<int?> getTokenExpiresAt()` | Epoch de expiración. |
| clearTokens | `Future<void> clearTokens()` | Borra token, refresh y expiración. |

---

### 2.1.7 RefreshTokenRunner

**Ubicación:** `lib/core/auth/refresh_token_runner.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| run | `Future<String?> run()` | `POST /api/login/refresh` con `http` directo. Body `{ refreshToken }`. Si 200 guarda token, refreshToken y expiresIn; retorna access token. 401/403 → `AuthException`. |

---

## 2.2 Capa de dominio

### 2.2.1 AuthRepository

**Ubicación:** `lib/domain/repositories/auth_repository.dart`

| Método | Firma | Comportamiento |
|--------|--------|----------------|
| login | `Future<UserEntity?> login(String email, String password)` | Login 2 pasos; persiste sesión. |
| logout | `Future<void> logout()` | Logout remoto optimista + clear local. |
| getCurrentUser | `Future<UserEntity?> getCurrentUser()` | Usuario almacenado o null. |
| isLoggedIn | `Future<bool> isLoggedIn()` | Hay sesión válida. |
| saveSession | `Future<void> saveSession(UserEntity user, String token, {String? refreshToken, int? expiresIn})` | Persiste sesión sin llamar API (Face Auth, etc.). |
| recuperarAcceso | `Future<void> recuperarAcceso(String userName)` | Correo de recuperación. |
| cambiarContrasenaDesdeRecuperacion | `Future<void> cambiarContrasenaDesdeRecuperacion({...})` | Cambio con token de URL. |

---

### 2.2.2 ReportesRepository

**Ubicación:** `lib/domain/repositories/reportes_repository.dart`

| Método | Firma | Comportamiento |
|--------|--------|----------------|
| enviarReporteTurno | `Future<Map<String, dynamic>> enviarReporteTurno({required int turnoId, required String destinatario, String? asunto})` | Delega en datasource remoto. |

---

### 2.2.3 UserEntity

**Ubicación:** `lib/domain/entities/user_entity.dart`

Campos requeridos: `id`, `email`, `name`. Opcionales: `roleName`, `apellidoPaterno`, `apellidoMaterno`, `telefono`, `userName`, `fotoPerfil`. Inmutable.

---

### 2.2.4 Casos de uso

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

| Método | Firma | Contrato |
|--------|--------|----------|
| login | `Future<LoginResult> login(String email, String password)` | `POST /api/login` → tokens → `GET /api/login/me` → `LoginResult(user, token, refreshToken?, expiresIn?)`. |
| loginWithNip | `Future<LoginResult> loginWithNip(String userName, String codigo)` | `POST /api/login/operador/accesso/nip` → tokens → `/me`. |
| refreshToken | `Future<RefreshResult> refreshToken(String refreshToken)` | `POST /api/login/refresh`. |
| recuperarAcceso | `Future<void> recuperarAcceso({required String userName})` | `POST /api/login/usuario/solicitud/recuperacion`. |
| cambiarContrasenaDesdeRecuperacion | `Future<void> cambiarContrasenaDesdeRecuperacion({...})` | `POST /api/login/cambiar/accesso` + Bearer token URL. |
| remoteLogout | `Future<void> remoteLogout(String token)` | `POST /api/login/logout` + Bearer. Errores ignorados (logout optimista). |

**Modelos:** `LoginTokensResponse`, `LoginMeResponse` → `UserModel` vía `toUserModel()`.

---

### 2.3.2 AuthLocalDatasource

**Ubicación:** `lib/data/datasources/local/auth_local_datasource.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| saveSession | `Future<void> saveSession(UserModel user, String token, {String? refreshToken, int? expiresIn})` | Token/refresh/expiry vía `TokenStorageService`; usuario en SharedPreferences. |
| clearSession | `Future<void> clearSession()` | `clearTokens` + borra usuario y flags de checklist. |
| getStoredUser | `Future<UserModel?> getStoredUser()` | Usuario guardado. |
| getStoredToken | `Future<String?> getStoredToken()` | Delega en `TokenStorageService`. |
| hasSession | `Future<bool> hasSession()` | Flag `keyIsLoggedIn`. |
| saveLastLoginEmail / getLastLoginEmail | — | Correo para login NIP. |

---

### 2.3.3 AuthRepositoryImpl

**Ubicación:** `lib/data/repositories/auth_repository_impl.dart`

Implementa `AuthRepository`. `login` delega en remote + `saveSession` local con refresh y expiresIn. `logout` llama `remoteLogout` si hay token y luego `clearSession`.

---

### 2.3.4 FaceAuthRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/face_auth_remote_datasource.dart`

Fuente remota Face Auth vía **BFF ShiftControl** (`baseUrl`). Usa `package:http` directo (multipart). **No** usa `ApiClient`.

| Método | Firma | Contrato |
|--------|--------|----------|
| obtainEmbedServiceJwt | `Future<String> obtainEmbedServiceJwt()` | `POST /api/login?Nombres=SIT` con credenciales de servicio internas → JWT para liveness/embed. |
| livenessCheck | `Future<FaceAuthLivenessResult> livenessCheck(String jwt, List<int> image1, List<int> image2)` | `POST /api/embed/liveness-check` multipart `files` (captura1.jpg, captura2.jpg), Bearer JWT. → `passed`, `reason?`, `score?`. |
| embed | `Future<List<double>> embed(String jwt, List<int> imageBytes)` | `POST /api/embed` multipart `file` (capture.jpg), Bearer JWT. → `embedding` array 512D. |
| validateFace | `Future<FaceAuthValidateSessionResult> validateFace(List<double> embedding, {double? latitud, double? longitud})` | `POST /api/auth/validateFace` JSON `{ embeddings, latitud?, longitud? }`. Sin Bearer BehaviorIQ. → `token`, `refreshToken?`, `expiresIn?`. |
| fetchLoginMe | `Future<UserModel> fetchLoginMe(String sessionToken)` | `GET /api/login/me` Bearer token de validateFace. |

**Tipos:** `FaceAuthLivenessResult`, `FaceAuthValidateSessionResult`.

**Errores HTTP:** 400/401/403/404 → `AuthException`; 429/500/503 → `NetworkException`; timeout 30 s.

---

### 2.3.5 PlateReadRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/plate_read_remote_datasource.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| readPlate | `Future<PlateReadResult> readPlate(String token, List<int> imageBytes)` | `POST /api/plate/read` multipart `file` (JPEG), Bearer token sesión. → `plateNumber`, `confidence?`. |

Usa `AppEnvironmentConfig.baseUrl`.

---

### 2.3.6 PlacasValidarRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/placas_validar_remote_datasource.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| validar | `Future<PlacasValidarResult> validar(String token, String numeroPlaca, {int? idCliente, int? idSolucion, double? latitud, double? longitud})` | `GET /api/placas/validar` query params, Bearer token sesión. |

**PlacasValidarResult:** `registered`, `idPlaca`, `placa`, `marca`, `modelo`, `anio`, `color`, `economico`.

---

### 2.3.7 ReportesRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/reportes_remote_datasource.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| enviarReporteTurno | `Future<Map<String, dynamic>> enviarReporteTurno({required int turnoId, required String destinatario, String? asunto})` | `POST /api/reportes/turno/{turnoId}/enviar` vía `ApiClient`. Body `{ destinatario, asunto? }`. Timeout 30 s. |

---

### 2.3.8 TurnosService

**Ubicación:** `lib/features/turnos/services/turnos_service.dart`

Servicio de dominio de turnos. Usa `ApiClient` y `http` multipart según el endpoint. Contratos principales documentados en **01-contexto.md** §1.4 (crear/cerrar turno, checklist, historial, detalle, incidentes, combustible).

---

## 2.4 Presentación

### 2.4.1 AppRouter

**Ubicación:** `lib/presentation/app_router.dart`

- `onGenerateRouteStatic(RouteSettings settings)`: normaliza path/query; `login` → `LoginPage`; `home` → `MainShell`; `nuevaContrasena` → `NuevaContrasenaPage(token)`.

---

### 2.4.2 AuthController (contrato público)

**Ubicación:** `lib/presentation/controllers/auth_controller.dart`

Estado: `AuthState(status, user, errorMessage)`. Estados: `initial`, `loading`, `authenticated`, `unauthenticated`, `error`.

| Método | Firma | Contrato |
|--------|--------|----------|
| checkAuth | `Future<void> checkAuth()` | Restaura sesión al iniciar app. |
| login | `Future<bool> login(String email, String password)` | LoginUseCase; actualiza state. |
| loginWithNip | `Future<bool> loginWithNip(String userName, String codigo)` | AuthService; actualiza state. |
| setSessionFromFaceAuth | `Future<void> setSessionFromFaceAuth(UserEntity user, String token)` | saveSession + state authenticated (disponible; Face Auth actual usa `saveSession` + `checkAuth` directamente). |
| logout | `Future<void> logout()` | LogoutUseCase + unauthenticated. |
| recuperarAcceso | `Future<void> recuperarAcceso({required BuildContext context, required String userName})` | Banner + navegación a login. |
| cambiarContrasenaDesdeRecuperacion | `Future<void> cambiarContrasenaDesdeRecuperacion({...})` | Banner + navegación a login. |

---

### 2.4.3 Providers (Riverpod)

**Ubicación:** `lib/presentation/controllers/auth_controller.dart`, `mi_turno_provider.dart`, `reportes_provider.dart`, `theme_controller.dart`

| Provider | Tipo | Contrato |
|----------|------|----------|
| sharedPreferencesProvider | `Provider<SharedPreferences>` | Override en `main`. |
| tokenStorageServiceProvider | `Provider<TokenStorageService>` | |
| refreshTokenRunnerProvider | `Provider<RefreshTokenRunner>` | |
| sessionExpiredTriggerProvider | `StateProvider<int>` | Logout automático al fallar refresh. |
| authLocalDatasourceProvider | `Provider<AuthLocalDatasource>` | |
| apiClientProvider | `Provider<ApiClient>` | HttpApiClient con refresh. |
| authRemoteDatasourceProvider | `Provider<AuthRemoteDatasource>` | |
| authRepositoryProvider | `Provider<AuthRepository>` | |
| profileServiceProvider | `Provider<ProfileService>` | ApiClient + TokenStorageService. |
| authServiceProvider | `Provider<AuthService>` | Login NIP. |
| faceAuthRemoteDatasourceProvider | `Provider<FaceAuthRemoteDatasource>` | FaceAuthRemoteDatasourceImpl (baseUrl). |
| faceAuthServiceProvider | `Provider<FaceAuthService>` | |
| plateReadRemoteDatasourceProvider | `Provider<PlateReadRemoteDatasource>` | |
| placasValidarRemoteDatasourceProvider | `Provider<PlacasValidarRemoteDatasource>` | |
| placaValidadaProvider | `StateProvider<PlacasValidarResult?>` | Estado global vehículo validado. |
| authControllerProvider | `StateNotifierProvider<AuthController, AuthState>` | |
| turnosServiceProvider | `Provider<TurnosService>` | |
| miTurnoActivoProvider | `FutureProvider` | Turno activo del operador. |
| turnoDetalleProvider | `FutureProvider.family` | Detalle por `idTurno`. |
| informacionGeneralProvider | `FutureProvider` | Resumen bitácora. |
| checklistProgressServiceProvider | `Provider<ChecklistProgressService>` | |
| registroCombustibleProvider | — | Incidencia gasolina. |
| reporteIncidenteSeleccionProvider / reporteIncidenteRegistradaProvider | — | Flujo incidente. |
| reportesRemoteDatasourceProvider | `Provider<ReportesRemoteDatasource>` | |
| reportesRepositoryProvider | `Provider<ReportesRepository>` | |
| reportesServiceProvider | `Provider<ReportesService>` | |
| themeModePreferenceProvider | `StateNotifierProvider` | Tema claro/oscuro/sistema. |

---

### 2.4.4 Rutas y pantallas

| Ruta / acceso | Pantalla | Notas |
|---------------|----------|-------|
| `/login` | `LoginPage` | Credenciales, NIP, Face Auth (push). |
| push | `FaceAuthFlowPage` | No es ruta estática. |
| `/home` | `MainShell` | Tabs: Home, Turnos, Historial, Perfil. |
| `/nueva-contrasena?token=` | `NuevaContrasenaPage` | Deep link web. |
| Tab Turnos | `ControlTurnosPage` | Navigator anidado para checklist. |
| Tab Historial | `HistorialTurnosPage` | Lista paginada por fecha. |
| push | `DetalleTurnoPage` | Desde historial con `idTurno`. |
| Perfil | `ProfilePage`, `CrearNipPage`, `CambiarContrasenaPage` | |
| Settings | `AppearancePage` | |

---

### 2.4.5 Convenciones de UI por flujo

| Flujo / pantalla | Convención |
|------------------|------------|
| **Face Auth** | Captura doble automática; loading "Verificando tu identidad" / "Analizando...."; éxito con banner; **cualquier error** → banner + `pushNamedAndRemoveUntil(login)`. Embedding solo vía backend (`captura2` → `/api/embed`). |
| **Inicio de Turno** | Card vehículo/operador; placa validada vía `placaValidadaProvider`; Continuar solo con `registered == true`. |
| **Apertura de Turno** | Card: Placa, Económico, Año, Marca/Modelo desde provider. |
| **Cierre de Turno** | Datos desde `placaValidadaProvider`; sin cámara de placa. |
| **Resumen / Control** | Vehículo desde provider; operador desde `authControllerProvider`. |
| **Detalle turno** | Evidencias con `ExpandableNetworkImage` (loading); compartir reporte por sheet. |
| **Historial** | Scroll infinito por día; filtro local y rango de fechas. |

---

### 2.4.6 Widgets reutilizables

**Ubicación:** `lib/presentation/widgets/`

| Widget | Uso |
|--------|-----|
| `AppAlertBanner` / `showAppAlertBanner` | Banners éxito/error/info. |
| `LoadingOverlay` | Overlay de carga en formularios. |
| `CustomTextField` | Campos de texto estilizados. |
| `ExpandableNetworkImage` | Imagen remota expandible con loading. |
| `CapturedEvidenceImage` / `NetworkImagePreview` | Evidencias en checklist. |

---

## 2.5 Features (servicios transversales)

### 2.5.1 AuthService

**Ubicación:** `lib/features/auth/services/auth_service.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| loginWithNip | `Future<UserModel> loginWithNip(String userName, String codigo)` | POST NIP + saveSession local. |

---

### 2.5.2 FaceAuthService

**Ubicación:** `lib/features/auth/services/face_auth_service.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| livenessEmbedAndValidateFace | `Future<({FaceAuthValidateSessionResult session, UserModel user})> livenessEmbedAndValidateFace({required Uint8List capture1, required Uint8List capture2, double? latitud, double? longitud})` | JWT servicio → liveness (captura1+2) → embed (**solo captura2**) → validateFace → fetchLoginMe. Valida embedding vacío o `length != 512`. Lanza `AuthException` si liveness `passed == false`. |

---

### 2.5.3 ProfileService

**Ubicación:** `lib/features/profile/services/profile_service.dart`

| Método | Endpoint | Contrato |
|--------|----------|----------|
| changePassword | `PATCH /api/login/cambiar/accesso` | Bearer explícito; body `passwordActual`, `passwordNueva`, `passwordNuevaConfirmacion`. |
| updateUserNip | `PATCH /api/login/mi-nip` | Bearer explícito; body `{ pinHash }`. |

---

### 2.5.4 ReportesService

**Ubicación:** `lib/features/reportes/services/reportes_service.dart`

| Método | Contrato |
|--------|----------|
| enviarReporteTurno | Delega en `ReportesRepository`; valida destinatario. |

---

### 2.5.5 ChecklistProgressService

**Ubicación:** `lib/features/turnos/services/checklist_progress_service.dart`

Persiste en SharedPreferences el progreso del checklist (paso actual, ids de bitácora, placa, datos de vehículo) para retomar flujos incompletos.

---

## 2.6 Utilidades y compatibilidad multiplataforma

### 2.6.1 Ruta inicial (Web)

- **Stub:** `getInitialRouteFromHash()` → `null`.
- **Web:** lee `window.location.hash`; si path es `nuevaContrasena` retorna constante.
- Import condicional: `initial_route_stub.dart` / `initial_route_web.dart`.

### 2.6.2 Lectura de bytes de archivo

- **Stub (web):** `readFileBytes` → `null`.
- **IO:** `File(path).readAsBytes()`.

---

## 2.7 Resumen de dependencias entre capas

```
Presentation (UI, Controllers, Router)
    → Domain (Use cases, Entities, Repository interfaces)
        → Data (RepositoryImpl)
            → Data (Remote/Local Datasources)
                → Core (ApiClient, TokenStorageService, AppException, baseUrl)

Features (AuthService, FaceAuthService, ProfileService, TurnosService, ReportesService)
    → ApiClient y/o http directo
    → Datasources / Repositories

Face Auth:
    FaceAuthFlowPage → FaceAuthService → FaceAuthRemoteDatasource → BFF (baseUrl)
    Éxito: AuthRepository.saveSession + AuthController.checkAuth

Turnos:
    UI → TurnosService / Providers → ApiClient o http multipart
    Placa: PlateReadRemoteDatasource, PlacasValidarRemoteDatasource → placaValidadaProvider

Reportes:
    DetalleTurnoPage → ReportesService → ReportesRepository → ReportesRemoteDatasource → ApiClient

Refresh:
    HttpApiClient → RefreshTokenRunner (POST /api/login/refresh) → TokenStorageService
    onSessionExpired → sessionExpiredTriggerProvider → AuthController.logout()
```

Las capas superiores no conocen implementaciones concretas; solo interfaces y contratos descritos en este documento.
