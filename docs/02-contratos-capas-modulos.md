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

**Implementación:** `HttpApiClient` usa `AppEnvironmentConfig.baseUrl`. Recibe `getToken`, `refreshToken` y `onSessionExpired`. `_shouldSkipAutoBearer(path)` omite `Authorization` automático **solo** en rutas públicas de login: `/api/login`, `/api/login/refresh`, `/api/login/operador/accesso/nip`, `/api/login/usuario/solicitud/recuperacion`. **`GET /api/login/me` y el resto de endpoints autenticados sí reciben Bearer.** El token se normaliza (`replaceAll(RegExp(r'\s+'), '')`) al construir el header. Ante 401/403 intenta un refresh; si falla llama `onSessionExpired()`.

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

| Constante | Valor | Uso |
|-----------|-------|-----|
| `appBarLeadingWidthWithoutBack` | `56` | Ancho reservado en AppBar de pasos del checklist cuando no hay botón de regreso (equivalente al `leading` del `IconButton` back). |

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

### 2.2.3 RegistroVehiculoRepository

**Ubicación:** `lib/domain/repositories/registro_vehiculo_repository.dart`

| Método | Firma | Comportamiento |
|--------|--------|----------------|
| registrar | `Future<RegistroVehiculoResponse> registrar({required RegistroVehiculoRequest request})` | Delega en datasource remoto; registra placa en ShiftControl. |

---

### 2.2.4 FaceAffiliationRepository

**Ubicación:** `lib/domain/repositories/face_affiliation_repository.dart`

| Método | Firma | Comportamiento |
|--------|--------|----------------|
| validarPoseYGenerarEmbedding | `Future<List<double>> validarPoseYGenerarEmbedding({required int sampleIndex, required String filename, required List<int> imageBytes})` | validate-pose + embed 512D por captura. |
| registrarRostro | `Future<FaceAffiliationResponse> registrarRostro({required FaceAffiliationRequest request})` | `POST /api/rostros` con 3 embeddings. |

---

### 2.2.5 AfiliarRostroRepository

**Ubicación:** `lib/domain/repositories/afiliar_rostro_repository.dart`

| Método | Firma | Comportamiento |
|--------|--------|----------------|
| obtenerOperadorActual | `Future<AfiliarRostroOperadorInfo> obtenerOperadorActual()` | `GET /api/login/me` → datos operador. |
| validarCapturas | `Future<void> validarCapturas({required Uint8List foto1, required Uint8List foto2})` | Liveness legacy (2 fotos). **No usado en UI actual.** |
| afiliarRostro | `Future<AfiliarRostroResponse> afiliarRostro({required String idUsuario, required Uint8List foto1, required Uint8List foto2})` | `POST /api/face-auth/enroll` legacy. **No usado en UI actual.** |

---

### 2.2.6 UserEntity

**Ubicación:** `lib/domain/entities/user_entity.dart`

Campos requeridos: `id`, `email`, `name`. Opcionales: `roleName`, `apellidoPaterno`, `apellidoMaterno`, `telefono`, `userName`, `fotoPerfil`. Inmutable.

---

### 2.2.7 Casos de uso

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

**Modelos:** `LoginTokensResponse`, `LoginMeResponse` → `UserModel` vía `toUserModel(fallbackEmail:)`.

**LoginMeResponse (GET /api/login/me):** objeto plano en raíz (compatibilidad con wrapper legacy `data`). Campos: `message?`, `id?`, `nombre`, `apellidoPaterno`, `apellidoMaterno`, `idCliente?`, `logotipo`, `ultimoLogin`, `fotoPerfil`, `telefono`, `userName`, `rol?` (`RolModel`), `permisos` (`List<PermisoPerfilModel>`).

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

### 2.3.5 FaceAffiliationRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/face_affiliation_remote_datasource.dart`

Fuente remota de afiliación facial vía **BFF ShiftControl** (`baseUrl`). Usa `package:http` directo (multipart y JSON). Bearer JWT de **sesión del operador** (`TokenStorageService`, normalizado).

| Método | Firma | Contrato |
|--------|--------|----------|
| obtenerJwtSesion | `Future<String> obtenerJwtSesion()` | Access token de sesión; lanza `AuthException` si no hay sesión. |
| validatePose | `Future<FaceAffiliationValidatePoseResult> validatePose({required int sampleIndex, required List<int> imageBytes, required String filename})` | `POST /api/embed/validate-pose?sample_index={1\|2\|3}` multipart `file`, Bearer sesión. → `valid`, `message?`. |
| registrarRostro | `Future<FaceAffiliationResponse> registrarRostro({required FaceAffiliationRequest request})` | `POST /api/rostros` JSON `{ nombre, paterno, materno, telefono, embeddingsList }`, Bearer sesión. HTTP **409** → `NetworkException` (rostro ya registrado). |

**Tipos:** `FaceAffiliationValidatePoseResult`, `FaceAffiliationRequest`, `FaceAffiliationResponse`.

---

### 2.3.6 AfiliarRostroOperadorDatasource

**Ubicación:** `lib/data/datasources/remote/afiliar_rostro_operador_datasource.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| obtenerOperadorActual | `Future<AfiliarRostroOperadorInfo> obtenerOperadorActual()` | `GET /api/login/me` vía `ApiClient` (Bearer automático). → `AfiliarRostroOperadorInfo.fromLoginMeJson`. |

**AfiliarRostroOperadorInfo:** `idUsuario`, `nombre`, `apellidoPaterno`, `apellidoMaterno`, `telefono`.

---

### 2.3.7 AfiliarRostroRemoteDatasource (legacy)

**Ubicación:** `lib/data/datasources/remote/afiliar_rostro_remote_datasource.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| afiliar | `Future<AfiliarRostroResponse> afiliar({required AfiliarRostroRequest request})` | `POST /api/face-auth/enroll` multipart `foto1`/`foto2` + `idUsuario`. **No usado en UI actual** (flujo reemplazado por FaceAffiliation). |

---

### 2.3.8 PlateReadRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/plate_read_remote_datasource.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| readPlate | `Future<PlateReadResult> readPlate(String token, List<int> imageBytes)` | `POST /api/plate/read` multipart `file` (JPEG), Bearer token sesión. → `plateNumber`, `confidence?`. |

Usa `AppEnvironmentConfig.baseUrl`.

---

### 2.3.9 PlacasValidarRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/placas_validar_remote_datasource.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| validar | `Future<PlacasValidarResult> validar(String token, String numeroPlaca, {int? idCliente, int? idSolucion, double? latitud, double? longitud})` | `GET /api/placas/validar` query params, Bearer token sesión. |

**PlacasValidarResult:** `registered`, `idPlaca`, `placa`, `marca`, `modelo`, `anio`, `color`, `economico`.

---

### 2.3.10 ReportesRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/reportes_remote_datasource.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| enviarReporteTurno | `Future<Map<String, dynamic>> enviarReporteTurno({required int turnoId, required String destinatario, String? asunto})` | `POST /api/reportes/turno/{turnoId}/enviar` vía `ApiClient`. Body `{ destinatario, asunto? }`. Timeout 30 s. |

---

### 2.3.11 RegistroVehiculoRemoteDatasource

**Ubicación:** `lib/data/datasources/remote/registro_vehiculo_remote_datasource.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| registrar | `Future<RegistroVehiculoResponse> registrar({required RegistroVehiculoRequest request})` | `POST /api/placas` vía `ApiClient`. Body JSON (ver `RegistroVehiculoRequest.toJson()`). Bearer JWT automático. |

**Request (`RegistroVehiculoRequest`):** `numeroPlaca`, `marca`, `modelo`, `anio` (int), `color`, `economico` (mapeo desde número económico en UI).

**Response (`RegistroVehiculoResponse`):** `idPlaca`, `numeroPlaca`, `economico`.

**Errores mapeados en datasource:**

| Código HTTP | Excepción | Mensaje UI |
|-------------|-----------|------------|
| 400 | `NetworkException` | No existe un vehículo registrado para esta placa. |
| 401 | `AuthException` | Tu sesión ha expirado. |
| 409 | `NetworkException` | La placa ya se encuentra afiliada. |
| 500 / 503 | `NetworkException` | No fue posible registrar el vehículo. Intenta nuevamente. |

---

### 2.3.12 RegistroVehiculoRepositoryImpl

**Ubicación:** `lib/data/repositories/registro_vehiculo_repository_impl.dart`

Implementa `RegistroVehiculoRepository`. Delega en `RegistroVehiculoRemoteDatasource`.

---

### 2.3.13 FaceAffiliationRepositoryImpl

**Ubicación:** `lib/data/repositories/face_affiliation_repository_impl.dart`

Implementa `FaceAffiliationRepository`. Delega en `FaceAffiliationService`.

---

### 2.3.14 AfiliarRostroRepositoryImpl

**Ubicación:** `lib/data/repositories/afiliar_rostro_repository_impl.dart`

Implementa `AfiliarRostroRepository`. `obtenerOperadorActual` vía `AfiliarRostroOperadorDatasource`; métodos legacy `validarCapturas` / `afiliarRostro` vía `AfiliarRostroService`.

---

### 2.3.15 TurnosService

**Ubicación:** `lib/features/turnos/services/turnos_service.dart`

Servicio de dominio de turnos. Usa `ApiClient` y `http` multipart según el endpoint.

| Método / acción | Endpoint | Notas |
|-----------------|----------|--------|
| Crear turno (apertura) | `POST /api/turnos` | Multipart: placa, lat, lng, evidencia. |
| Cierre geográfico | `PATCH /api/turnos` | Multipart. |
| Cerrar bitácora | `PATCH /api/turnos/bitacora/cierre` | Cierre definitivo desde resumen. |
| Odómetro / tablero | `POST /api/turnos/tablero` | Foto tablero + kilometraje. |
| Inspección exterior | `POST /api/turnos/inspeccion-vehiculo-ex` | Daños por vista del vehículo. |
| Testigos | `POST /api/turnos/testigos` | |
| Niveles fluido | `POST /api/turnos/niveles-fluidos` | |
| Luces | `POST /api/turnos/luces-vehiculo` | |
| Accesorios | `POST /api/turnos/accesorios-vehiculo` | |
| Documentación | `POST /api/turnos/documentacion-vehiculo` | |
| Información general bitácora | `GET /api/bitacora-vehicular/informacion-general` | Resumen de turno. |
| Mi turno activo | `GET /api/turnos/mi-turno` | Control de turnos. |
| Historial | `GET /api/turnos/list` | Query `fechaDesde`, `fechaHasta`. |
| Detalle turno | `GET /api/turnos/{id}` | `obtenerTurnoDetalle`. |
| Combustible | `POST /api/turnos/incidencias/gasolina` | Multipart. |
| Incidente / accidente | `POST /api/turnos/incidencias/accidente` | Multipart + fotos. |
| Ubicación inversa | `GET /api/ubicacion/reverse` | Reporte de incidente. |

---

### 2.3.16 Modelos — Mi turno activo

**Ubicación:** `lib/data/models/mi_turno_activo_response.dart`

Respuesta de `GET /api/turnos/mi-turno` parseada en `MiTurnoActivoResponse`.

| Modelo / campo | Tipo | Notas |
|----------------|------|--------|
| `turnoActivo` | `bool` | Indica si hay turno en curso. |
| `idTurno` | `int?` | ID del turno activo. |
| `fechaInicio` | `DateTime?` | Inicio del turno activo. |
| `duracionSegundos` | `int?` | Duración del turno activo. |
| `vehiculo` | `MiTurnoActivoVehiculo?` | Placa, foto, detalle marca/modelo. |
| **`turnoActual`** | **`TurnoActual?`** | Último/apertura de turno para tarjeta Historial Reciente. |
| `ultimoTurno` | `UltimoTurno?` | Último cierre (fecha, placa, marca, modelo, duración). |
| `ultimaIncidenciaGasolina` | `UltimaIncidenciaGasolina?` | Último registro de combustible. |
| `ultimaIncidenciaAccidente` | `UltimaIncidenciaAccidente?` | Último incidente reportado. |

**`TurnoActual`:** `etiqueta?`, `idTurno?`, `fechaApertura?` (ISO → local), `enCurso?`.

**`UltimoTurno`:** `fechaCierre?`, `placa?`, `marca?`, `modelo?`, `duracion?`; getter `vehiculoDisplay`.

**Provider:** `miTurnoActivoProvider` (`MiTurnoActivoNotifier` en `mi_turno_provider.dart`).

---

### 2.3.17 Modelos — Información general de bitácora

**Ubicación:** `lib/data/models/informacion_general_response.dart`

Respuesta de `GET /api/bitacora-vehicular/informacion-general?idBitacoraVehiculo=`.

| Modelo | Campos relevantes |
|--------|-------------------|
| `InformacionGeneral` | `vehiculo`, `operador`, **`estadoVehiculo`**, `metricasIniciales`, `ubicacion?` |
| `EstadoVehiculoItem` | `etiqueta?`, `valor?` — `fromJson` con coerción segura de tipos (`_coerceString`) |
| `MetricaInicialItem` | `etiqueta?`, `valor?` |

**Parseo `estadoVehiculo`:** arreglo JSON → `whereType<Map<String, dynamic>>()` → `EstadoVehiculoItem.fromJson`. Sin orden fijo; extensible a nuevas etiquetas del backend.

**Provider:** `informacionGeneralProvider` (`InformacionGeneralNotifier`).

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

**Ubicación:** `lib/presentation/controllers/auth_controller.dart`, `mi_turno_provider.dart`, `reportes_provider.dart`, `registro_vehiculo_provider.dart`, `afiliar_rostro_provider.dart`, `face_affiliation_provider.dart`, `theme_controller.dart`

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
| miTurnoActivoProvider | `StateNotifierProvider<MiTurnoActivoNotifier, AsyncValue<MiTurnoActivoResponse>>` | `GET /api/turnos/mi-turno`; incluye `turnoActual`, `ultimoTurno`, incidencias. |
| turnoDetalleProvider | `FutureProvider.family` | Detalle por `idTurno`. |
| informacionGeneralProvider | `FutureProvider` | Resumen bitácora. |
| checklistProgressServiceProvider | `Provider<ChecklistProgressService>` | |
| registroVehiculoRemoteDatasourceProvider | `Provider<RegistroVehiculoRemoteDatasource>` | `RegistroVehiculoRemoteDatasourceImpl(apiClient)`. |
| registroVehiculoRepositoryProvider | `Provider<RegistroVehiculoRepository>` | |
| registroVehiculoEnviadoProvider | `StateProvider<RegistroVehiculoFormData?>` | Último registro exitoso en sesión. |
| afiliarRostroOperadorDatasourceProvider | `Provider<AfiliarRostroOperadorDatasource>` | `AfiliarRostroOperadorDatasourceImpl(apiClient)`. |
| afiliarRostroRemoteDatasourceProvider | `Provider<AfiliarRostroRemoteDatasource>` | Legacy enroll. |
| afiliarRostroServiceProvider | `Provider<AfiliarRostroService>` | Legacy liveness + enroll. |
| afiliarRostroRepositoryProvider | `Provider<AfiliarRostroRepository>` | Operador + métodos legacy. |
| afiliarRostroOperadorProvider | `FutureProvider<AfiliarRostroOperadorInfo>` | Datos operador para Afiliar Rostro. |
| faceAffiliationRemoteDatasourceProvider | `Provider<FaceAffiliationRemoteDatasource>` | validate-pose + POST /api/rostros. |
| faceAffiliationServiceProvider | `Provider<FaceAffiliationService>` | Orquesta pose + embed + registro. |
| faceAffiliationRepositoryProvider | `Provider<FaceAffiliationRepository>` | Usado por `FaceAffiliationCapturePage`. |
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
| Tab Turnos | `ControlTurnosPage` | Navigator anidado para checklist; retomar progreso incompleto. |
| Checklist apertura/cierre | Ver `ChecklistAperturaPasos` / `ChecklistCierrePasos` | 9 pasos; rutas `/inicio-turno`, `/captura-odometro`, … y `/cierre-*`. |
| push | `IdentificarPlacaPage` | Desde inicio de turno (apertura) o registro de vehículo; OCR + validación; `onRegresar` opcional para pop con estado preservado. |
| push | `RegistroVehiculoPage` | Desde menú lateral (`AppDrawer`); formulario de alta de placa. |
| push | `AfiliarRostroPage` | Desde menú lateral (`AppDrawer`); afiliación facial del operador. |
| push | `FaceAffiliationCapturePage` | Desde `AfiliarRostroPage`; orquesta 3 capturas + APIs. |
| push | `FaceAffiliationSingleCapturePage` | Captura individual con delay post-instrucción (solo afiliación). |
| push | `RegistroCombustiblePage` | `/registro-combustible` desde control de turnos. |
| push | `ReporteIncidentePage` | `/reporte-incidente` desde control de turnos. |
| Tab Historial | `HistorialTurnosPage` | Lista paginada por fecha. |
| push | `DetalleTurnoPage` | Desde historial con `idTurno`. |
| Perfil | `ProfilePage`, `CrearNipPage`, `CambiarContrasenaPage` | |
| Settings | `AppearancePage` | |

---

### 2.4.5 Convenciones de UI por flujo

| Flujo / pantalla | Convención |
|------------------|------------|
| **Face Auth** | Captura doble automática; loading "Verificando tu identidad" / "Analizando...."; éxito con banner; **cualquier error** → banner + `pushNamedAndRemoveUntil(login)`. Embedding solo vía backend (`captura2` → `/api/embed`). |
| **Inicio de Turno (paso 1)** | Card vehículo/operador; placa validada vía `placaValidadaProvider`; Continuar solo con `registered == true`. **Mantiene** flecha de regreso y navegación back normal. AppBar `centerTitle: true`. |
| **Checklist apertura/cierre (encabezados)** | AppBar `centerTitle: true` en las 9 pantallas del flujo (misma tipografía y estilos; solo alineación centrada). |
| **Pasos internos checklist** | `PopScope(canPop: false)` + `automaticallyImplyLeading: false` + `leadingWidth: AppConstants.appBarLeadingWidthWithoutBack` + `centerTitle: true`. Sin regreso a pasos anteriores (botón físico, gesto, AppBar). Pantallas: captura odómetro, indicadores, fluidos, luces, accesorios, documentación, inspección exterior (`RegistroDanosPage`), resumen. |
| **Identificar placa** | `PopScope(canPop: false)`; si `onRegresar != null` muestra flecha AppBar y botón Regresar que hace pop a la pantalla origen. |
| **Registro de vehículo** | Formulario independiente del checklist; campos placa/marca/modelo/año/color/económico; OCR vía `IdentificarPlacaPage`; **año con bottom sheet de lista dinámica** (`RegistroVehiculoAnioPicker.availableYears`, 1980 – año actual + 1); `POST /api/placas`; botón Guardar vehículo con loading y validación de campos obligatorios; feedback `AppAlertBanner`. |
| **Afiliar Rostro** | `GET /api/login/me` → campos operador read-only; botón **Capturar rostro** → 3 capturas (`FaceAffiliationSingleCapturePage`, 3 s post-instrucción) → validate-pose + embed + `POST /api/rostros`; HTTP 409 → alerta info «Rostro registrado»; éxito → banner + botón deshabilitado. **No usa** `FaceAuthCapturePage` ni login facial. |
| **Apertura de Turno** | Card: Placa, Económico, Año, Marca/Modelo desde provider. |
| **Cierre de Turno** | Datos desde `placaValidadaProvider`; sin cámara de placa en paso 1. |
| **Control de Turnos — Historial Reciente** | 4 tarjetas desde `miTurnoActivoProvider`: Cierre (`ultimoTurno`), Incidente (`ultimaIncidenciaAccidente`), **Apertura de turno** (`turnoActual`: `fechaApertura` + `etiqueta`), Combustible (`ultimaIncidenciaGasolina`). `turnoActual == null` → «Sin registros». |
| **Resumen de turno** | `informacionGeneralProvider`; **Estado del Vehículo** dinámico (`estadoVehiculo[].etiqueta` / `.valor`); etiqueta odómetro: **Odómetro Inicial** (apertura) / **Odómetro Final** (cierre) según `ChecklistType`; valor sin cambios desde API. Acción: `GradientSlideToAct`. Errores/éxito: `QuickAlert`. |
| **Registro combustible** | Turno activo requerido; fotos bomba/tablero; `registroCombustibleProvider`. |
| **Reporte incidente** | Tipo, descripción, fotos, GPS; geocodificación inversa; providers de selección/registro. |
| **Detalle turno** | Evidencias con `ExpandableNetworkImage` (loading); compartir reporte por sheet. |
| **Historial** | Scroll infinito por día; filtro local y rango de fechas. |

---

### 2.4.6 Widgets reutilizables

**Ubicación:** `lib/presentation/widgets/`

| Widget | Uso |
|--------|-----|
| `AppAlertBanner` / `showAppAlertBanner` | Banners éxito/error/info. **Contrato:** visible **3 segundos** y se oculta automáticamente (`_bannerVisibilityDuration`). |
| `LoadingOverlay` | Overlay de carga en formularios. |
| `CustomTextField` | Campos de texto estilizados. |
| `ExpandableNetworkImage` | Imagen remota expandible con loading. |
| `CapturedEvidenceImage` / `NetworkImagePreview` | Evidencias en checklist. |

---

### 2.4.7 Modelo de presentación — Registro de vehículo

**Ubicación:** `lib/presentation/turnos/registro_vehiculo/models/registro_vehiculo_form_data.dart`

| Campo | Tipo | Origen UI |
|-------|------|-----------|
| `numeroPlaca` | `String` | Campo placa (manual u OCR) |
| `marca` | `String` | Campo marca |
| `modelo` | `String` | Campo modelo |
| `anio` | `String` | Selector de año (4 dígitos; bottom sheet lista dinámica) |
| `color` | `String` | Campo color |
| `numeroEconomico` | `String` | Campo número económico → API `economico` |

**Colores UI:** `RegistroVehiculoColors` (`lib/presentation/turnos/registro_vehiculo/registro_vehiculo_colors.dart`).

**Constantes selector año:** `RegistroVehiculoAnioPicker` — mínimo 1980, máximo año actual + 1; getter `availableYears` genera lista descendente dinámica.

**Widget selector:** `_RegistroVehiculoAnioPickerSheet` (bottom sheet con `ListView`, año seleccionado resaltado).

---

### 2.4.8 Modelo de presentación — Afiliar Rostro

**Ubicación:** `lib/presentation/afiliar_rostro/`

| Elemento | Contrato |
|----------|----------|
| `AfiliarRostroPage` | Carga operador (`afiliarRostroOperadorProvider`); valida datos (nombre, apellidos, teléfono 10 dígitos); abre `FaceAffiliationCapturePage`. |
| `FaceAffiliationCapturePage` | Orquesta 3 pasos (`sample_index` 1–3); por captura: validate-pose + embed; final: `POST /api/rostros`. |
| `FaceAffiliationSingleCapturePage` | Cámara frontal, óvalo, instrucción fija, countdown **después** de mostrar mensaje (`secondsAfterInstruction`, default 3). |
| `FaceAffiliationCaptureResult` | `exitoso(rostroId)` \| `conflictoRegistro(mensaje?)` para HTTP 409. |

**Colores UI:** `AfiliarRostroColors` (`lib/presentation/afiliar_rostro/afiliar_rostro_colors.dart`).

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

### 2.5.3 FaceAffiliationService

**Ubicación:** `lib/features/afiliar_rostro/services/face_affiliation_service.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| validarPoseYGenerarEmbedding | `Future<List<double>> validarPoseYGenerarEmbedding({required int sampleIndex, required String filename, required List<int> imageBytes})` | validate-pose (sesión) → embed JWT servicio (`FaceAuthRemoteDatasource`) → embedding 512D. Lanza `AuthException` si pose inválida o embedding ≠ 512. |
| registrarRostro | `Future<FaceAffiliationResponse> registrarRostro({required FaceAffiliationRequest request})` | Valida datos personales (teléfono 10 dígitos) y exactamente 3 embeddings de 512 → `POST /api/rostros`. |

---

### 2.5.4 AfiliarRostroService (legacy)

**Ubicación:** `lib/features/afiliar_rostro/services/afiliar_rostro_service.dart`

| Método | Firma | Contrato |
|--------|--------|----------|
| validarCapturas | `Future<void> validarCapturas({required Uint8List foto1, required Uint8List foto2})` | Liveness 2 fotos vía `FaceAuthRemoteDatasource`. **No usado en UI actual.** |
| afiliarRostro | `Future<AfiliarRostroResponse> afiliarRostro({required String idUsuario, required Uint8List foto1, required Uint8List foto2})` | `POST /api/face-auth/enroll`. **No usado en UI actual.** |

---

### 2.5.5 ProfileService

**Ubicación:** `lib/features/profile/services/profile_service.dart`

| Método | Endpoint | Contrato |
|--------|----------|----------|
| changePassword | `PATCH /api/login/cambiar/accesso` | Bearer explícito; body `passwordActual`, `passwordNueva`, `passwordNuevaConfirmacion`. |
| updateUserNip | `PATCH /api/login/mi-nip` | Bearer explícito; body `{ pinHash }`. |

---

### 2.5.6 ReportesService

**Ubicación:** `lib/features/reportes/services/reportes_service.dart`

| Método | Contrato |
|--------|----------|
| enviarReporteTurno | Delega en `ReportesRepository`; valida destinatario. |

---

### 2.5.7 ChecklistProgressService

**Ubicación:** `lib/features/turnos/services/checklist_progress_service.dart`

Persiste en SharedPreferences el progreso del checklist (paso actual, ids de bitácora, placa, datos de vehículo) para retomar flujos incompletos.

| Método / concepto | Contrato |
|-------------------|----------|
| `leerProgreso()` | Devuelve `ChecklistProgress?` con paso, `idTurno`, flags de cierre, datos de vehículo. |
| `actualizarPaso(int paso)` | Persiste el paso actual del checklist. |
| `tieneProgresoIncompleto` | Indica si hay checklist sin finalizar (usado en `ControlTurnosPage` para retomar). |

**Navegación:** `checklist_apertura_navigation.dart` define `ChecklistAperturaPasos`, `ChecklistCierrePasos` y `routeForPaso` / navegación standalone al retomar.

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
    Control de Turnos: miTurnoActivoProvider → GET /api/turnos/mi-turno
        Historial Reciente: turnoActual (Apertura de turno), ultimoTurno (Cierre), incidencias
    Resumen: informacionGeneralProvider → estadoVehiculo dinámico (etiqueta/valor)

Reportes:
    DetalleTurnoPage → ReportesService → ReportesRepository → ReportesRemoteDatasource → ApiClient

Registro de vehículo:
    RegistroVehiculoPage → registroVehiculoRepositoryProvider → RegistroVehiculoRepositoryImpl
        → RegistroVehiculoRemoteDatasourceImpl → ApiClient (POST /api/placas)
    OCR placa: IdentificarPlacaPage → PlateReadRemoteDatasource (sin cambios)
    Selector año: RegistroVehiculoAnioPicker.availableYears → _RegistroVehiculoAnioPickerSheet

Afiliar Rostro (UI actual):
    AfiliarRostroPage → afiliarRostroOperadorProvider → AfiliarRostroOperadorDatasource (GET /api/login/me)
    Captura → FaceAffiliationCapturePage → faceAffiliationRepositoryProvider → FaceAffiliationService
        → FaceAffiliationRemoteDatasource (validate-pose, POST /api/rostros)
        → FaceAuthRemoteDatasource (POST /api/embed, JWT servicio)
    Legacy (sin UI): AfiliarRostroService → AfiliarRostroRemoteDatasource (POST /api/face-auth/enroll)

Refresh:
    HttpApiClient → RefreshTokenRunner (POST /api/login/refresh) → TokenStorageService
    onSessionExpired → sessionExpiredTriggerProvider → AuthController.logout()
```

Las capas superiores no conocen implementaciones concretas; solo interfaces y contratos descritos en este documento.
