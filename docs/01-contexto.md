# 1. Contexto de la solución

## 1.1 Descripción general

**Turnos Spring** es una aplicación Flutter multiplataforma (Android, iOS, Web) para el control de turnos operativos. Permite autenticación (login con correo/contraseña, NIP y reconocimiento facial), flujos de apertura y cierre de turno (checklist, fotos de resguardo/tablero, odómetro, combustible, daños, reporte de incidentes), consulta de historial y detalle de turnos, envío de reportes por correo, y gestión de perfil y apariencia.

Toda la comunicación con el backend se realiza contra el **BFF ShiftControl** (`AppEnvironmentConfig.baseUrl`). No hay URLs separadas para BehaviorIQ ni hosts legacy (`spcode.ddns.net`, `faceauth.ddns.net`).

La solución sigue una **arquitectura en capas** (data / domain / presentation) con **Riverpod** para inyección de dependencias y estado, **Navigator 1.0** para rutas, y una separación clara entre fuentes de datos, repositorios, casos de uso, servicios de features y UI.

---

## 1.2 Stack tecnológico

| Área | Tecnología |
|------|------------|
| Framework | Flutter (Dart) |
| Estado / DI | Riverpod (Provider, StateNotifierProvider) |
| Navegación | Navigator 1.0 + MaterialApp.onGenerateRoute |
| Red | `package:http` → `ApiClient` (`HttpApiClient`) y llamadas HTTP directas para multipart |
| Persistencia local | SharedPreferences (sesión, checklist, tema) |
| Ubicación | `geolocator` (Face Auth, apertura/cierre de turno) |
| Cámara / imágenes | `camera`, `image_picker`, `image` |
| Temas | Material 3 (`AppTheme` light/dark, `ThemeController`) |
| Plataformas | Android, iOS, Web (hash routing para deep links) |

---

## 1.3 Estructura de carpetas (lib)

```
lib/
├── config/                 # Ambiente (baseUrl DEV/QA/PROD)
├── core/
│   ├── auth/               # TokenStorageService, RefreshTokenRunner (POST /api/login/refresh)
│   ├── constants/          # Rutas, keys SharedPreferences
│   ├── errors/             # AppException, AuthException, NetworkException, StorageException
│   ├── network/            # ApiClient, HttpApiClient (refresh + reintento 401/403)
│   ├── theme/              # AppTheme, colores
│   └── utils/              # Validadores, initial route (web/stub), read file bytes, date_format_utils
├── data/
│   ├── datasources/
│   │   ├── local/          # AuthLocalDatasource
│   │   └── remote/         # Auth, FaceAuth, PlateRead, PlacasValidar, Reportes
│   ├── models/             # DTOs (UserModel, LoginTokensResponse, LoginMeResponse, etc.)
│   └── repositories/       # AuthRepositoryImpl, ReportesRepositoryImpl
├── domain/
│   ├── entities/           # UserEntity
│   ├── repositories/       # AuthRepository, ReportesRepository
│   └── usecases/           # Login, Logout, GetCurrentUser, CheckAuth
├── features/
│   ├── auth/               # AuthService (login NIP), FaceAuthService
│   ├── profile/            # ProfileService (contraseña, NIP)
│   └── turnos/             # TurnosService, ChecklistProgressService
├── presentation/
│   ├── controllers/        # AuthController, ThemeController
│   ├── auth/               # Login, recuperar/nueva contraseña, perfil, face_auth
│   ├── home/               # MainShell, Drawer, bottom nav, tabs
│   ├── turnos/             # Control, checklist apertura/cierre, historial, detalle, placa, incidentes
│   ├── settings/           # Apariencia
│   ├── widgets/            # AppAlertBanner, LoadingOverlay, ExpandableNetworkImage, etc.
│   └── app_router.dart
└── main.dart
```

---

## 1.4 Flujos principales

### Autenticación

#### Login correo/contraseña (2 pasos)
- **UI:** `LoginPage` → `AuthController.login`
- **API:**
  1. `POST /api/login` → `token`, `refreshToken`, `expiresIn`
  2. `GET /api/login/me` (Bearer) → datos del usuario
- **Persistencia:** `AuthRepository.saveSession` → `TokenStorageService` + SharedPreferences

#### Login NIP
- **UI:** `LoginPage` (modo NIP; requiere correo previo en `getLastLoginEmail`)
- **API:** `POST /api/login/operador/accesso/nip` → tokens → `GET /api/login/me`
- **Servicio:** `AuthService.loginWithNip`

#### Refresh token
- Ante **401/403**, `HttpApiClient` llama a `RefreshTokenRunner` → `POST /api/login/refresh` (HTTP directo, sin `ApiClient`)
- Si el refresh tiene éxito: guarda nuevos tokens y reintenta la petición original
- Si falla: `sessionExpiredTriggerProvider` → logout automático en `main.dart`
- Mutex (`Completer`) para un solo refresh en vuelo

#### Logout
- **UI:** `ProfilePage`, `AppDrawer`, etc.
- **Flujo:** `AuthController.logout` → `POST /api/login/logout` (Bearer, optimista) → `clearSession` local siempre

#### Recuperar acceso
- `RecuperarContrasenaPage` → `POST /api/login/usuario/solicitud/recuperacion` → banner + navegación a login

#### Cambiar contraseña
| Contexto | Pantalla | Endpoint |
|----------|----------|----------|
| Link de recuperación | `NuevaContrasenaPage` (`?token=`) | `POST /api/login/cambiar/accesso` + Bearer token URL |
| Perfil (logueado) | `CambiarContrasenaPage` | `PATCH /api/login/cambiar/accesso` → logout tras éxito |

#### Perfil — NIP
- `CrearNipPage` → `PATCH /api/login/mi-nip` con `{ pinHash }` (6 u 8 dígitos; validaciones locales de seguridad)

#### Login Face Auth (reconocimiento facial)
- **Entrada:** botón "Reconocimiento facial" en `LoginPage` → `FaceAuthFlowPage` (push, no ruta nombrada)
- **Captura:** `FaceAuthCapturePage` — cámara frontal, óvalo, 2 capturas automáticas (2 s entre ellas) → `[captura1, captura2]`
- **Pipeline API (ShiftControl BFF):**
  1. `POST /api/login?Nombres=SIT` — JWT de servicio interno para liveness/embed (en datasource, invisible al usuario)
  2. `POST /api/embed/liveness-check` — multipart `files` ×2 (captura1 + captura2), Bearer JWT servicio
  3. `POST /api/embed` — multipart `file` = **solo captura2** → embedding 512D (generado en backend, no en Flutter)
  4. `POST /api/auth/validateFace` — body `{ embeddings, latitud?, longitud? }` → `token`, `refreshToken`, `expiresIn`
  5. `GET /api/login/me` — Bearer token de validateFace → `UserModel`
- **Sesión:** `authRepository.saveSession` + `AuthController.checkAuth` → Home
- **Embedding:** la app **no** calcula vectores localmente; solo envía JPEG de captura2 y parsea `response.embedding`
- **Errores:** cualquier fallo (liveness `passed: false`, embedding inválido, HTTP 4xx/5xx, red, timeout) → `AppAlertBanner` + `pushNamedAndRemoveUntil(login)`
- **UX preservada:** pantalla "Verificando tu identidad" / "Analizando...."; mensaje de éxito "Iniciaste sesión con reconocimiento facial."

### Ruta inicial (Web)
- Hash `#/nueva-contrasena?token=...` resuelto en `main.dart` vía `getInitialRouteFromHash()`
- `AppRouter` normaliza path y query para `NuevaContrasenaPage`

### Turnos — control y checklist

**Hub:** `ControlTurnosPage` consulta `GET /api/turnos/mi-turno` (`miTurnoActivoProvider`).

**Checklist apertura (9 pasos):** Inicio → Odómetro → Daños → Testigos → Fluidos → Luces → Accesorios → Documentación → Resumen.

**Checklist cierre (9 pasos):** rutas paralelas `/cierre-*`.

**APIs principales (`TurnosService`):**

| Acción | Endpoint |
|--------|----------|
| Crear turno (apertura) | `POST /api/turnos` (multipart: placa, lat, lng, evidencia) |
| Cierre geográfico | `PATCH /api/turnos` (multipart) |
| Cerrar bitácora | `PATCH /api/turnos/bitacora/cierre` |
| Odómetro | `POST /api/turnos/tablero` |
| Daños | `POST /api/turnos/inspeccion-vehiculo-ex` |
| Testigos | `POST /api/turnos/testigos` |
| Fluidos | `POST /api/turnos/niveles-fluidos` |
| Luces | `POST /api/turnos/luces-vehiculo` |
| Accesorios | `POST /api/turnos/accesorios-vehiculo` |
| Documentación | `POST /api/turnos/documentacion-vehiculo` |
| Resumen bitácora | `GET /api/bitacora-vehicular/informacion-general` |
| Combustible | `POST /api/turnos/incidencias/gasolina` |
| Incidente/accidente | `POST /api/turnos/incidencias/accidente` + `GET /api/ubicacion/reverse` |

**Progreso local:** `ChecklistProgressService` en SharedPreferences.

### Placa y vehículo (Inicio de Turno)
- **OCR placa:** `IdentificarPlacaPage` → `POST /api/plate/read` (`PlateReadRemoteDatasource`)
- **Validar placa:** `GET /api/placas/validar?numeroPlaca=...` (`PlacasValidarRemoteDatasource`)
- **Estado global:** `placaValidadaProvider` (`StateProvider<PlacasValidarResult?>`)
- **UI:** header con Folio/Fecha/Lugar; Continuar habilitado solo con `registered == true`; datos de vehículo en CapturaOdometro, Resumen, Control de Turnos

### Historial de turnos
- **Pantalla:** `HistorialTurnosPage` (tab Historial en `MainShell`)
- **API:** `GET /api/turnos/list?fechaDesde=&fechaHasta=` (scroll infinito día a día, máx. 30 días)
- Filtro de búsqueda local y selector de rango de fechas

### Detalle de turno
- **Pantalla:** `DetalleTurnoPage` — navegación desde historial con `idTurno`
- **API:** `GET /api/turnos/{id}` (`turnoDetalleProvider`)
- Muestra datos, evidencias, bitácoras, incidencias (orden: fecha → tipo → descripción → evidencias)
- **Imágenes remotas:** `ExpandableNetworkImage` con indicador de carga
- Mensaje de fin de detalle al final del listado

### Compartir reporte por correo
- **UI:** sheet en `DetalleTurnoPage` (`compartir_reporte_sheets.dart`)
- **API:** `POST /api/reportes/turno/{id}/enviar` — body `{ destinatario, asunto? }`
- Cadena: `ReportesService` → `ReportesRepository` → `ReportesRemoteDatasource`

### Apariencia
- `AppearancePage` — tema claro / oscuro / sistema (`themeModePreferenceProvider`)

---

## 1.5 Decisiones de diseño

- **Un solo BFF:** `AppEnvironmentConfig.baseUrl` para login, turnos, placas, face auth, reportes y perfil. Face Auth usa `package:http` directo en `FaceAuthRemoteDatasource` (multipart y JWT de servicio).
- **Login en 2 pasos:** tokens en `POST /api/login`; perfil en `GET /api/login/me`.
- **Tokens centralizados:** `TokenStorageService` (access, refresh, `expiresIn`/`expiresAt`). `AuthLocalDatasource` delega en él.
- **Refresh reactivo:** renovación ante 401/403, no proactiva por timer.
- **Logout optimista:** siempre limpia sesión local aunque falle el servidor.
- **Face Auth sin IA local:** embedding generado exclusivamente por `POST /api/embed` con captura2.
- **Errores controlados:** `AppException` y subclases; UI con `AppAlertBanner`.
- **Sin lógica de red en UI:** controllers orquestan; red en datasources/servicios.
- **Web:** deep links por hash; fotos con `Image.memory` / bytes; banner con contexto de overlay.
- **Fotos en checklist:** `Uint8List` en memoria para compatibilidad web.

---

## 1.6 Convenciones

- **Rutas:** `RouteConstants` (`/login`, `/home`, `/nueva-contrasena`)
- **AppRouter:** normaliza `settings.name` con query params
- **Providers Riverpod:** definidos en `auth_controller.dart`, `mi_turno_provider.dart`, `reportes_provider.dart`, etc.
- **Debug:** `debugPrint` en datasources y puntos críticos de auth/turnos
- **Ambiente:** cambiar `current` en `app_environment.dart` (dev / qa / prod)

---

## 1.7 Mapa de endpoints del BFF

```
Auth:     POST /api/login, GET /api/login/me, POST /api/login/refresh
          POST /api/login/logout, POST /api/login/operador/accesso/nip
          POST /api/login/usuario/solicitud/recuperacion
          POST|PATCH /api/login/cambiar/accesso, PATCH /api/login/mi-nip
Face:     POST /api/embed/liveness-check, POST /api/embed, POST /api/auth/validateFace
Turnos:   /api/turnos/*, /api/bitacora-vehicular/informacion-general
          /api/ubicacion/reverse, /api/turnos/incidencias/*
Placas:   POST /api/plate/read, GET /api/placas/validar
Reportes: POST /api/reportes/turno/{id}/enviar
```
