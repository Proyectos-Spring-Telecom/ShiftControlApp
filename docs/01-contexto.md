# 1. Contexto de la solución

## 1.1 Descripción general

**Turnos Spring** es una aplicación Flutter multiplataforma (Android, iOS, Web) para el control de turnos operativos. Permite autenticación (login con correo/contraseña y NIP, con soporte de **refresh token** para renovar el access token automáticamente), flujos de apertura y cierre de turno (checklist, fotos de resguardo/tablero, odómetro, combustible, daños, reporte de incidentes) y gestión de perfil y apariencia.

La solución sigue una **arquitectura en capas** (data / domain / presentation) con **Riverpod** para inyección de dependencias y estado, **Navigator 1.0** para rutas, y una separación clara entre fuentes de datos, repositorios, casos de uso y UI.

---

## 1.2 Stack tecnológico

| Área | Tecnología |
|------|------------|
| Framework | Flutter (Dart) |
| Estado / DI | Riverpod (Provider, StateNotifierProvider) |
| Navegación | Navigator 1.0 + MaterialApp.onGenerateRoute |
| Red | package:http → ApiClient (HttpApiClient) |
| Persistencia local | SharedPreferences (sesión de auth) |
| Temas | Material 3 (AppTheme light/dark, ThemeController) |
| Plataformas | Android, iOS, Web (hash routing para deep links) |

---

## 1.3 Estructura de carpetas (lib)

```
lib/
├── config/                 # Ambiente (baseUrl DEV/QA/PROD)
├── core/
│   ├── auth/               # TokenStorageService (token + refreshToken), RefreshTokenRunner (POST /api/auth/refresh sin ApiClient)
│   ├── constants/          # Rutas, constantes de app (keyAuthToken, keyRefreshToken, etc.)
│   ├── errors/             # AppException, AuthException, NetworkException
│   ├── network/            # ApiClient (contrato), HttpApiClient (impl con refresh y reintento 401/403)
│   ├── theme/              # AppTheme, colores
│   └── utils/              # Validadores, initial route (web/stub), read file bytes (io/stub), date_format_utils (fecha/hora en español)
├── data/
│   ├── datasources/
│   │   ├── local/          # AuthLocalDatasource (SharedPreferences)
│   │   └── remote/         # AuthRemoteDatasource; FaceAuthRemoteDatasource; PlateReadRemoteDatasource (POST /plate/read); PlacasValidarRemoteDatasource (GET /placas/validar)
│   ├── models/             # DTOs (LoginRequest, LoginResponse, UserModel, etc.)
│   └── repositories/      # AuthRepositoryImpl
├── domain/
│   ├── entities/          # UserEntity
│   ├── repositories/      # AuthRepository (contrato)
│   └── usecases/          # Login, Logout, GetCurrentUser, CheckAuth
├── features/
│   ├── auth/               # AuthService (login NIP), modelos NIP
│   └── profile/            # ProfileService, modelos cambio contraseña/NIP
├── presentation/
│   ├── controllers/       # AuthController, ThemeController
│   ├── auth/               # Login, recuperar contraseña, nueva contraseña, perfil, face_auth (captura, flujo)
│   ├── home/               # MainShell, Drawer, bottom nav, tabs
│   ├── turnos/             # Control turnos, inicio/cierre, odómetro, combustible, daños, incidentes; identificar_placa (PlateRead), placa_validada_provider (estado global vehículo), plate_image_crop
│   ├── settings/           # Apariencia
│   ├── widgets/            # AppAlertBanner, LoadingOverlay, etc.
│   └── app_router.dart     # Rutas estáticas (login, home, nueva-contrasena)
└── main.dart               # Bootstrap, initialRoute desde hash (web), ProviderScope
```

---

## 1.4 Flujos principales

### Autenticación
- **Login correo/contraseña:** UI → AuthController.login → LoginUseCase → AuthRepository → AuthRemoteDatasource (POST /api/login) + AuthLocalDatasource.saveSession (token y opcional refreshToken si el backend los envía). Tokens se persisten vía **TokenStorageService**.
- **Login NIP:** AuthController.loginWithNip → AuthService (POST /api/login/operador/accesso/nip) + saveSession (token y opcional refreshToken).
- **Refresh token:** Si una request devuelve 401 o 403, **HttpApiClient** intenta renovar el token llamando a **RefreshTokenRunner** (POST /api/auth/refresh con refreshToken; no usa ApiClient para evitar ciclos). Si el refresh tiene éxito, se guardan los nuevos token y refreshToken y se **reintenta la request original**. Si el refresh falla (p. ej. 401/403), se llama a **onSessionExpired** (incrementa `sessionExpiredTriggerProvider`), el listener en la app ejecuta logout y se redirige al login. Solo se permite un refresh en vuelo (Completer) para evitar múltiples renovaciones simultáneas. Ver docs 14.
- **Login Face Auth:** Botón "Reconocimiento facial" en LoginPage → FaceAuthFlowPage. Flujo: FaceAuthService.loginAndGetIdCliente (POST auth/login, GET auth/me) → FaceAuthCapturePage (dos capturas en misma pantalla: "Mantenga la posición al frente" + 2 s, "Gira un poco el rostro..." + 2 s) → liveness-check (POST embed/liveness-check, 2 imágenes) → embed (POST /embed, 2ª imagen → 512D) → validateFace (POST auth/validateFace/{idCliente}, body `embeddings` 512 números). Éxito: AuthController.setSessionFromFaceAuth → Home. Fallo liveness/404: pantallas de reintento y "Volver al login". API Face Auth: `AppEnvironmentConfig.faceAuthBaseUrl` y opcional `faceAuthLivenessBaseUrl` (solo liveness). UI de captura: óvalo verde con efecto over; sin cuenta regresiva visible (plan 09). **UI actual:** mensajes claros de éxito/error; en fallo de verificación pantalla "No pudimos verificar tu rostro" con opciones reintentar/volver al login; sin banner duplicado; estados de carga "Verificando tu identidad" y "Analizando..." durante liveness/embed/validateFace. Ver docs 06, 07, 08, 09.
- **Recuperar acceso:** RecuperarContrasenaPage → AuthController.recuperarAcceso → AuthRepository.recuperarAcceso → POST /api/login/usuario/solicitud/recuperacion → banner + pushNamedAndRemoveUntil(login).
- **Cambiar contraseña desde link:** NuevaContrasenaPage (token en URL) → AuthController.cambiarContrasenaDesdeRecuperacion → AuthRepository → POST /api/login/cambiar/accesso con header Authorization: Bearer {token} → banner + navegación a login.
- **Cierre de sesión:** AuthController.logout → LogoutUseCase → AuthRepository.logout → AuthLocalDatasource.clearSession (que llama a TokenStorageService.clearTokens y limpia datos de usuario).

### Ruta inicial (Web)
- En web, la ruta inicial se resuelve desde el hash (#/nueva-contrasena?token=...).
- Se intenta primero `Uri.base.fragment`; si viene vacío (típico en release), se usa un helper que lee `window.location.hash` (import condicional dart.library.html).
- Si la ruta es `RouteConstants.nuevaContrasena`, se pasa como `initialRoute` a MaterialApp para mostrar NuevaContrasenaPage sin pasar por login.

### Turnos
- Flujo de **inicio/cierre de turno**: selección de vehículo, foto de resguardo (cierre), foto de tablero, captura de odómetro, registro de combustible, niveles de fluido, accesorios, luces, daños, reporte de incidentes, documentación, resumen.
- **Validación de placa:** Tras identificar la placa en Inicio de Turno (IdentificarPlacaPage → POST /plate/read con PlateReadRemoteDatasource), se llama a **GET /placas/validar** (API BehaviorIQ) con `numeroPlaca`, `idCliente` e `idSolucion`. Estos últimos se obtienen con **GET /auth/me** (FaceAuthRemoteDatasource.me(token)) usando el token de sesión actual. El resultado se guarda en el **provider global** `placaValidadaProvider` (`StateProvider<PlacasValidarResult?>`), de modo que cualquier pantalla pueda usar los datos del vehículo (placa, marca, modelo, año, económico). Ver docs 12.
- **Inicio de Turno (UI):** Sin card "Asignación Requerida". Card de vehículo/operador unida (selector de vehículo con input de placa; subtítulo "Placa registrada" cuando la placa está validada). Header muestra solo **Folio: Pendiente**, **Fecha** y **Lugar** (no placa, marca, modelo, año ni económico en el header). Botón **Continuar** habilitado solo cuando la placa está registrada (`placaValidadaProvider` con `registered == true`). En **Cierre de Turno** no se abre cámara de placa: los datos del vehículo se toman de `placaValidadaProvider`; el texto del info box en Cierre es específico ("fotografía de resguardo...", distinto al de Apertura).
- **Apertura de Turno (Captura de odómetro):** Primera card con datos del vehículo en orden: **Placa**, **Económico**, **Año**, **Marca/Modelo** (sin hora). Pill de placa alineado. Datos desde `placaValidadaProvider`.
- **Resumen de Turno:** Card "Información General" con datos del vehículo desde `placaValidadaProvider` y datos del operador desde `authControllerProvider`.
- **Control de Turnos:** Card "Estado Actual" con datos del vehículo desde `placaValidadaProvider`.
- Las **fotos capturadas** se guardan en memoria como `Uint8List` y se muestran con `Image.memory` para compatibilidad con web (evitar `Image.file`).

---

## 1.5 Decisiones de diseño

- **Contratos por capa:** Las capas se comunican por interfaces (ApiClient, AuthRepository, AuthRemoteDatasource, AuthLocalDatasource, TokenStorageService). La implementación concreta se inyecta vía Riverpod.
- **Tokens centralizados:** **TokenStorageService** es la única interfaz para leer/escribir access token y refresh token (SharedPreferences). No se accede a las claves de tokens desde otras partes del código. AuthLocalDatasource delega en TokenStorageService para token/refreshToken; logout limpia vía clearTokens().
- **Refresh token y reintento:** HttpApiClient recibe `getToken`, `refreshToken` (callback) y `onSessionExpired`. Paths que contienen `login` o `refresh` no llevan Authorization. Ante 401/403 en una request protegida se intenta un solo refresh (RefreshTokenRunner con http directo); si tiene éxito se reintenta la request; si falla se dispara logout automático.
- **Errores controlados:** Se usan `AppException` y subclases (`AuthException`, `NetworkException`, `StorageException`). El cliente HTTP mapea códigos 4xx/5xx a estas excepciones; la UI muestra mensajes vía `AppAlertBanner`.
- **Sin lógica de red en UI ni en controllers de negocio:** Los controllers orquestan (validan, llaman repos/servicios, muestran banners y navegación); la red está en datasources/servicios.
- **Web:** Deep links por hash; visualización de fotos con bytes (`Image.memory`); lectura del hash con import condicional; overlay del banner usa el contexto del overlay para `MediaQuery` y evitar null tras navegación.
- **Ambiente:** Un solo punto de configuración (`config/app_environment.dart`): `current` (dev/qa/prod), `AppEnvironmentConfig.baseUrl` para el ApiClient principal, `faceAuthBaseUrl` y opcional `faceAuthLivenessBaseUrl` para Face Auth (cliente HTTP propio en FaceAuthRemoteDatasource).

---

## 1.6 Convenciones

- **Nombres de rutas:** Centralizados en `RouteConstants`; rutas con query (ej. token) se construyen con helpers (ej. `nuevaContrasenaWithToken(token)`).
- **AppRouter:** Recibe `RouteSettings.name` que puede incluir query; se normaliza el path para el switch y se extrae el token para NuevaContrasenaPage.
- **Debug:** Se usa `debugPrint` en datasources, controller y puntos críticos (resolución de ruta, éxito/error de recuperación y cambio de contraseña).
