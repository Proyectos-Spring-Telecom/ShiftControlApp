# 1. Contexto de la solución

## 1.1 Descripción general

**Turnos Spring** es una aplicación Flutter multiplataforma (Android, iOS, Web) para el control de turnos operativos. Permite autenticación (login con correo/contraseña, NIP y reconocimiento facial), flujos de apertura y cierre de turno (checklist, fotos de resguardo/tablero, odómetro, inspección exterior, combustible, reporte de incidentes), registro de vehículos (alta de placa vía `POST /api/placas`), **afiliación de rostro del operador** (captura facial + `POST /api/rostros`), consulta de historial y detalle de turnos, **compartir reporte de turno en PDF** y envío por correo, y gestión de perfil y apariencia.

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
| Compartir archivos | `share_plus` (PDF de reporte de turno en Detalle de Turno) |
| Fechas (historial) | `calendar_date_picker2` (selector de rango en Historial de Turnos) |
| Selector de año (vehículo) | Bottom sheet con lista dinámica (Registro de Vehículo; sin calendario) |
| Temas | Material 3 (`AppTheme` light/dark, `ThemeController`) |
| Plataformas | Android, iOS, Web (hash routing para deep links; ajustes Web en `web/index.html`) |
| Build Android release | APK Gradle: `shiftControlAPP.apk` (`android/app/build.gradle.kts`) |

---

## 1.3 Estructura de carpetas (lib)

```
lib/
├── config/                 # Ambiente (baseUrl DEV/QA/PROD)
├── core/
│   ├── auth/               # TokenStorageService, RefreshTokenRunner (POST /api/login/refresh)
│   ├── constants/          # Rutas, keys SharedPreferences, appBarLeadingWidthWithoutBack
│   ├── errors/             # AppException, AuthException, NetworkException, StorageException
│   ├── network/            # ApiClient, HttpApiClient (refresh + reintento 401/403)
│   ├── theme/              # AppTheme, colores
│   └── utils/              # Validadores, initial route (web/stub), read/save file bytes, content-disposition, date_format_utils
├── data/
│   ├── datasources/
│   │   ├── local/          # AuthLocalDatasource
│   │   └── remote/         # Auth, FaceAuth, FaceAffiliation, AfiliarRostro, PlateRead, PlacasValidar, Reportes, RegistroVehiculo
│   ├── models/             # DTOs (UserModel, LoginMeResponse, RegistroVehiculoRequest, FaceAffiliationRequest, etc.)
│   └── repositories/       # AuthRepositoryImpl, FaceAffiliationRepositoryImpl, AfiliarRostroRepositoryImpl, ReportesRepositoryImpl, RegistroVehiculoRepositoryImpl
├── domain/
│   ├── entities/           # UserEntity
│   ├── repositories/       # AuthRepository, FaceAffiliationRepository, AfiliarRostroRepository, ReportesRepository, RegistroVehiculoRepository
│   └── usecases/           # Login, Logout, GetCurrentUser, CheckAuth
├── features/
│   ├── auth/               # AuthService (login NIP), FaceAuthService
│   ├── afiliar_rostro/     # FaceAffiliationService, AfiliarRostroService (legacy enroll)
│   ├── profile/            # ProfileService (contraseña, NIP)
│   └── turnos/             # TurnosService, ChecklistProgressService
├── presentation/
│   ├── controllers/        # AuthController, ThemeController
│   ├── auth/               # Login, recuperar/nueva contraseña, perfil, face_auth
│   ├── afiliar_rostro/     # AfiliarRostroPage, captura facial de afiliación
│   ├── home/               # MainShell, Drawer, bottom nav, tabs
│   ├── turnos/             # Control, checklist apertura/cierre, historial, detalle, placa, incidentes, registro vehículo, inspección exterior
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
- **Jerarquía visual de botones:** **Iniciar Sesión** — botón primario sólido (azul); **Reconocimiento facial** — estilo outline (borde, sin relleno sólido). Misma disposición en modos credenciales y NIP.
- **API:**
  1. `POST /api/login` → `token`, `refreshToken`, `expiresIn`
  2. `GET /api/login/me` (Bearer) → datos del usuario
- **Persistencia:** `AuthRepository.saveSession` → `TokenStorageService` + SharedPreferences
- **Token JWT:** normalización en `TokenStorageService` y `HttpApiClient` (eliminación de saltos de línea); `GET /api/login/me` **sí recibe Bearer** automático (no se omite como en `POST /api/login`)

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

**Historial Reciente (Control de Turnos):** sección con 4 tarjetas `_HistorialItem` alimentadas desde `MiTurnoActivoResponse`:

| Tarjeta | Origen de datos | Subtítulo |
|---------|-----------------|-----------|
| Cierre de Turno | `ultimoTurno` | fecha cierre relativa + vehículo |
| Incidente Reportado | `ultimaIncidenciaAccidente` | fecha + descripción truncada |
| **Apertura de turno** | **`turnoActual`** | fecha apertura (corta) + `etiqueta` |
| Registro de Combustible | `ultimaIncidenciaGasolina` | fecha + litros |

- **`turnoActual`:** `{ etiqueta, idTurno, fechaApertura, enCurso }`; si es `null` → «Sin registros».
- Indicador activo del día (`esRegistroDelDia`): en Apertura de turno usa `turnoActual.fechaApertura`.
- Tarjeta **Cierre de Turno** sigue usando `ultimoTurno` (sin cambios).

**Checklist apertura (9 pasos):** Inicio → Odómetro → Inspección exterior → Testigos → Fluidos → Luces → Accesorios → Documentación → Resumen.

**Checklist cierre (9 pasos):** mismo orden con rutas `/cierre-*`; paso 1 es inicio de cierre (sin captura de placa).

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
| Historial | `GET /api/turnos/list?fechaDesde=&fechaHasta=` |
| Detalle turno | `GET /api/turnos/{id}` |
| Combustible | `POST /api/turnos/incidencias/gasolina` |
| Incidente/accidente | `POST /api/turnos/incidencias/accidente` + `GET /api/ubicacion/reverse` |

**Progreso local:** `ChecklistProgressService` en SharedPreferences (paso actual, ids de bitácora/turno, placa, datos de vehículo). **Retomar:** desde `ControlTurnosPage` si hay progreso incompleto (`onAperturaResumeTap` / `onCierreResumeTap`).

**Orden canónico (9 pasos, apertura y cierre):**

| Paso | Apertura | Cierre |
|------|----------|--------|
| 1 | `InicioTurnoPage` (`/inicio-turno`) | `InicioTurnoPage` modo cierre (`/cierre-turno`) |
| 2 | Captura odómetro | Captura odómetro |
| 3 | Inspección exterior (`RegistroDanosPage`) | Inspección exterior |
| 4 | Indicadores testigo | Indicadores testigo |
| 5 | Niveles de fluido | Niveles de fluido |
| 6 | Luces del vehículo | Luces del vehículo |
| 7 | Accesorios | Accesorios |
| 8 | Documentación | Documentación |
| 9 | Resumen de turno | Resumen de turno |

Rutas de cierre con prefijo `/cierre-*` (definidas en `ChecklistCierrePasos`).

**Navegación secuencial (pasos internos):** en las pantallas del checklist (excepto `InicioTurnoPage` en paso 1) no hay regreso a pasos anteriores:

- `PopScope(canPop: false)` — bloquea botón físico Back, gesto iOS y pop del Navigator.
- AppBar sin flecha: `automaticallyImplyLeading: false`.
- Espaciado del título: `leadingWidth: AppConstants.appBarLeadingWidthWithoutBack` (56 px, equivalente al área del botón back).
- **Títulos centrados:** AppBar con `centerTitle: true` en las **9 pantallas** del checklist (apertura y cierre): `InicioTurnoPage`, `CapturaOdometroPage`, `RegistroDanosPage`, `IndicadoresTestigoPage`, `NivelesFluidoPage`, `LucesVehiculoPage`, `AccesoriosPage`, `DocumentacionPage`, `ResumenTurnoPage`.

Pantallas con restricción de no regreso en el checklist (pasos 2–9): `CapturaOdometroPage`, `IndicadoresTestigoPage`, `NivelesFluidoPage`, `LucesVehiculoPage`, `AccesoriosPage`, `DocumentacionPage`, `RegistroDanosPage`, `ResumenTurnoPage`.

**Inspección Exterior (`RegistroDanosPage` — paso 3 apertura y cierre):**

- Título AppBar: «Inspección Exterior»; 4 vistas del vehículo (frontal, trasera, lateral izquierdo, lateral derecho) con puntos interactivos de daño.
- **Widget de imagen:** `VehicleViewWidget` → `VehicleInspectionAssets.pathFor(view, brightness)`.
- **Android / iOS:** assets fijos `.png` (`vehicle_lateral_izquierdo.png`, `vehicle_trasera.png`, `vehicle_frontal.png`, `vehicle_lateral_derecho.png`) — sin cambio por tema.
- **Flutter Web (`kIsWeb`):** assets `.webp` según `Theme.of(context).brightness`:
  - Tema claro: `vehicle_* .webp` (versión estándar).
  - Tema oscuro: `vehicle_*_blanco.webp` / `vehicle_frontal_Blanco.webp` (versión blanca).
- Helper centralizado: `lib/presentation/turnos/registro_danos/vehicle_inspection_assets.dart`.
- API de registro de daños sin cambios: `POST /api/turnos/inspeccion-vehiculo-ex`.

**`IdentificarPlacaPage`:** en el checklist aplica `PopScope(canPop: false)`; si se abre con callback `onRegresar` (desde Inicio de Turno o Registro de Vehículo), el botón **Regresar** del pie y la flecha del AppBar ejecutan `Navigator.pop` y conservan el formulario de la pantalla origen.

**Resumen de turno (`ResumenTurnoPage`):**

- Consulta `GET /api/bitacora-vehicular/informacion-general` vía `informacionGeneralProvider`.
- Secciones: estado, información general, estado del vehículo, tiempo/ubicación, métricas iniciales.
- **Estado del Vehículo:** renderizado **dinámico** del arreglo `informacionGeneral.estadoVehiculo`; cada ítem muestra `etiqueta` y `valor` del API (sin lista fija ni filtro por posición). Compatible con nuevos estados del backend (ej. «Estado de los niveles del vehículo»). Si el arreglo está vacío → «No disponible».
- En **Métricas Iniciales**, la etiqueta del odómetro depende del flujo: **Odómetro Inicial** (apertura) u **Odómetro Final** (cierre); el valor y formato provienen del API sin cambios.
- Acción final: `GradientSlideToAct` — «Iniciar Turno» (apertura) o «Cerrar Turno» (cierre).
- Feedback de éxito/error en esta pantalla: `QuickAlert` (resto de la app usa principalmente `AppAlertBanner`).

### Registro de combustible

- **Pantalla:** `RegistroCombustiblePage` — acceso desde `ControlTurnosPage` (`/registro-combustible`).
- **API:** `POST /api/turnos/incidencias/gasolina` (multipart: fotos bomba/tablero, litros, total, kilometraje, GPS).
- Requiere turno activo (`miTurnoActivoProvider` / `turnoAperturaProvider`).
- Evidencias en memoria (`Uint8List`); validaciones locales antes de enviar.

### Reporte de incidente / accidente

- **Pantalla:** `ReporteIncidentePage` — acceso desde `ControlTurnosPage` (`/reporte-incidente`).
- **API:** `POST /api/turnos/incidencias/accidente` + `GET /api/ubicacion/reverse` (geocodificación inversa para mostrar dirección).
- Tipo de incidencia, descripción, múltiples fotos (máx. 10 MB c/u), GPS obligatorio.
- Providers: `reporteIncidenteSeleccionProvider`, `reporteIncidenteRegistradaProvider`.

### Placa y vehículo (Inicio de Turno)

- **OCR placa:** `IdentificarPlacaPage` → `POST /api/plate/read` (`PlateReadRemoteDatasource`)
- **Validar placa:** `GET /api/placas/validar?numeroPlaca=...` (`PlacasValidarRemoteDatasource`)
- **Estado global:** `placaValidadaProvider` (`StateProvider<PlacasValidarResult?>`)
- **UI:** header con Folio/Fecha/Lugar; Continuar habilitado solo con `registered == true`; datos de vehículo en CapturaOdometro, Resumen, Control de Turnos
- **Identificar placa:** cámara en vivo, captura automática, recorte; navegación de retorno vía `onRegresar` cuando se abre desde flujos que lo proveen (Inicio de Turno, Registro de Vehículo)

### Registro de vehículo

- **Acceso:** menú lateral (`AppDrawer`) → `RegistroVehiculoPage` (push independiente del checklist).
- **Formulario (6 campos):** número de placa, marca, modelo, año, color, número económico.
- **OCR placa:** reutiliza `IdentificarPlacaPage` (mismo flujo que Inicio de Turno); `plate_number` prellena el campo placa; al regresar sin capturar se mantiene el estado del formulario.
- **Selector de año:** bottom sheet con lista desplegable generada dinámicamente (`RegistroVehiculoAnioPicker.availableYears`); rango **1980 – año actual + 1**; el campo muestra solo el año (ej. `2024`); valor enviado como `int`.
- **API:** `POST /api/placas` vía `RegistroVehiculoRemoteDatasource` → `RegistroVehiculoRepository` (`ApiClient`, JWT automático).
- **Body:** `{ numeroPlaca, marca, modelo, anio, color, economico }`.
- **Respuesta exitosa:** `idPlaca`, `numeroPlaca`, `economico`; mensaje `AppAlertBanner`: «Vehículo registrado correctamente».
- **Errores mapeados:** 400 → placa sin vehículo registrado; 409 → placa ya afiliada; 401 → sesión expirada; 500/503 → error genérico de registro.
- **UI:** botones homologados al resto de la app (primario ancho completo, acciones secundarias con estilo de Detalle de Turno); loading en botón Guardar vehículo; validación de campos obligatorios antes de habilitar envío.
- **Providers:** `registroVehiculoRepositoryProvider`, `registroVehiculoEnviadoProvider` (último formulario enviado en sesión).

### Afiliar Rostro

- **Acceso:** menú lateral (`AppDrawer`) → `AfiliarRostroPage` (push independiente del checklist).
- **Información del operador:** campos de solo lectura cargados con `GET /api/login/me` vía `AfiliarRostroOperadorDatasource` → `AfiliarRostroOperadorInfo` (Nombre, Apellido paterno, Apellido materno, Teléfono).
- **Contrato `/api/login/me`:** respuesta plana en raíz (sin wrapper `data`); campos `message`, `id`, `nombre`, `apellidoPaterno`, `apellidoMaterno`, `telefono`, `userName`, `rol`, `permisos`, etc. (`LoginMeResponse`).
- **Flujo de captura (UI actual):** botón **Capturar rostro** → `FaceAffiliationCapturePage` orquesta **3 capturas** independientes del login facial:
  1. **Frente** (`sample_index=1`) — instrucción «Mira al frente»
  2. **Izquierda** (`sample_index=2`) — «Gira un poco el rostro a la izquierda»
  3. **Derecha** (`sample_index=3`) — «Gira un poco el rostro a la derecha»
- **Captura individual:** `FaceAffiliationSingleCapturePage` — cámara frontal, óvalo verde (estilo Face Auth); **3 segundos de espera después de mostrar la instrucción** (countdown visible); luego `takePicture()` automático. **No reutiliza** `FaceAuthCapturePage`.
- **Pipeline API por captura:**
  1. `POST /api/embed/validate-pose?sample_index={1|2|3}` — multipart `file`, Bearer JWT de sesión
  2. `POST /api/embed` — multipart `file` (mismo mecanismo que login facial; JWT de servicio vía `FaceAuthRemoteDatasource.obtainEmbedServiceJwt`) → embedding 512D
- **Registro final:** `POST /api/rostros` — body `{ nombre, paterno, materno, telefono, embeddingsList }` (3 embeddings de 512 elementos).
- **Errores:**
  - Pose inválida → banner error + reintento de la captura actual
  - HTTP **409** en `POST /api/rostros` → pop con `FaceAffiliationCaptureResult.conflictoRegistro()`; `AfiliarRostroPage` muestra `showAppAlertInfo` («Rostro registrado»)
  - Otros errores → banner error; usuario puede reintentar
- **Éxito:** banner verde «Rostro afiliado correctamente» + banner de estado «Rostro afiliado» con fecha; botón **Capturar rostro** deshabilitado.
- **Arquitectura:** `FaceAffiliationRemoteDatasource` → `FaceAffiliationService` → `FaceAffiliationRepository` → `faceAffiliationRepositoryProvider`. Operador: `afiliarRostroOperadorProvider`.
- **No usa en UI actual:** `POST /api/auth/validateFace`, `POST /api/face-auth/enroll`, liveness de 2 capturas (`AfiliarRostroService` / `AfiliarRostroRemoteDatasource` permanecen en código legacy sin uso en pantalla).

### Home y shell principal

- **HomeTab:** pantalla de bienvenida con botón «Comenzar» → tab Turnos / `ControlTurnosPage`.
- **MainShell:** bottom navigation (Inicio, Turnos, Historial, Perfil), drawer (incluye acceso a **Registro de Vehículo** y **Afiliar Rostro**), navigator anidado para checklist y rutas auxiliares (combustible, incidente).

### Feedback visual (banners)

- **`AppAlertBanner` / `showAppAlertBanner`:** banners éxito/info/error en la mayoría de flujos; **auto-cierre a los 3 segundos** (`_bannerVisibilityDuration`).
- **`LoadingOverlay`:** overlay de carga en formularios.
- **`QuickAlert`:** usado en `ResumenTurnoPage` para confirmaciones de inicio/cierre de turno.

### Historial de turnos
- **Pantalla:** `HistorialTurnosPage` (tab Historial en `MainShell`)
- **API:** `GET /api/turnos/list?fechaDesde=&fechaHasta=` (scroll infinito día a día, máx. 30 días)
- Filtro de búsqueda local y selector de rango de fechas con `calendar_date_picker2`

### Detalle de turno
- **Pantalla:** `DetalleTurnoPage` — navegación desde historial con `idTurno`
- **API:** `GET /api/turnos/{id}` (`turnoDetalleProvider`) → `TurnoDetalleData`
- **Secciones:** estado del turno, empleado/vehículo, **Estado del Vehículo — Apertura** (dinámico desde bitácora inicio), **Estado del Vehículo — Cierre** (si hay bitácora de fin), horario, odómetro (fotos lectura inicial/final), kilometraje actual, **Registro de Combustible** (incidencias gasolina con fotos tablero/bomba), **Incidencias de Accidente** (tipo, descripción, hasta 3 evidencias)
- **Estado del vehículo (apertura/cierre):** lista dinámica `estadoVehiculo[]` con `etiqueta` / `valor` del API (mismo criterio que Resumen de Turno)
- **Imágenes remotas:** `ExpandableNetworkImage` con indicador de carga (`CircularProgressIndicator` + texto «Cargando imagen...»); en **Web** usa `frameBuilder` (`kIsWeb`) porque `loadingBuilder` no reporta progreso en navegador
- **Compartir:** icono AppBar → sheet `compartir_reporte_sheets.dart` con **Compartir** (PDF) y **Enviar por correo**
- Mensaje de fin de detalle al final del listado

### Compartir reporte de turno (PDF y correo)
- **UI:** `DetalleTurnoPage` → `showCompartirReporteOpciones` / `showEnviarReporteEmailSheet`
- **Compartir PDF:**
  1. `GET /api/reportes/turno/{idTurno}` — respuesta binaria PDF (`ApiClient.getBytes`)
  2. Nombre de archivo desde header `Content-Disposition` (`content_disposition_utils.dart`)
  3. Guardado temporal (`save_bytes_to_temp_file.dart` — stub Web / IO nativo)
  4. `Share.shareXFiles` vía `share_plus`
- **Errores PDF mapeados:** 401 sesión expirada; 403 sin permisos; 404 reporte no encontrado; 500 error al generar; timeout 60 s
- **Enviar por correo:** `POST /api/reportes/turno/{id}/enviar` — body `{ destinatario, asunto? }` (sin cambios respecto al flujo previo)
- **Cadena PDF:** `ReportesService.descargarReporteTurnoPdf` → `ReportesRepository` → `ReportesRemoteDatasource` → `HttpApiClient.getBytes`
- **Modelo:** `ReporteTurnoPdfResult` (`bytes`, `fileName`)
- **UX Compartir:** loading en botón mientras descarga; cierra sheet antes de abrir diálogo nativo de compartir

### Apariencia
- `AppearancePage` — tema claro / oscuro / sistema (`themeModePreferenceProvider`)
- En **Web**, el cambio de tema actualiza las imágenes de Inspección Exterior al reconstruir `RegistroDanosPage` (assets `.webp` vía `VehicleInspectionAssets`)

### Comportamiento específico Flutter Web

| Área | Implementación |
|------|----------------|
| Deep links | Hash `#/nueva-contrasena?token=...` en `main.dart` / `initial_route_web.dart` |
| Viewport / cámara | `web/index.html`: meta viewport fijo, `touch-action: manipulation`, script que reaplica escala al volver del diálogo de permisos de cámara |
| Carga de imágenes (Detalle de Turno) | `ExpandableNetworkImage`: `frameBuilder` cuando `kIsWeb`; Android/iOS mantienen `loadingBuilder` |
| Inspección Exterior | `VehicleInspectionAssets`: assets `.webp` según tema solo en Web; móvil usa `.png` fijos |
| Archivos temporales PDF | `save_bytes_to_temp_file_stub.dart` (Web) / `save_bytes_to_temp_file_io.dart` (IO) |
| Fotos en checklist | `Uint8List` / `Image.memory` para compatibilidad web |

---

## 1.5 Decisiones de diseño

- **Un solo BFF:** `AppEnvironmentConfig.baseUrl` para login, turnos, placas, face auth, reportes y perfil. Face Auth usa `package:http` directo en `FaceAuthRemoteDatasource` (multipart y JWT de servicio).
- **Login en 2 pasos:** tokens en `POST /api/login`; perfil en `GET /api/login/me`.
- **Tokens centralizados:** `TokenStorageService` (access, refresh, `expiresIn`/`expiresAt`); normalización de JWT (sin saltos de línea). `AuthLocalDatasource` delega en él.
- **Bearer en `/api/login/me`:** `HttpApiClient._shouldSkipAutoBearer` omite Authorization solo en rutas públicas de login (`POST /api/login`, refresh, NIP, recuperación); **`GET /api/login/me` sí envía Bearer**.
- **Refresh reactivo:** renovación ante 401/403, no proactiva por timer.
- **Logout optimista:** siempre limpia sesión local aunque falle el servidor.
- **Face Auth sin IA local:** embedding generado exclusivamente por `POST /api/embed` con captura2.
- **Afiliar Rostro independiente del login:** flujo propio de 3 capturas con validate-pose + embed + `POST /api/rostros`; pantalla de captura dedicada (`FaceAffiliationSingleCapturePage`) con delay post-instrucción.
- **Checklist secuencial:** pasos internos sin navegación hacia atrás (`PopScope`); solo avance en el flujo; títulos de AppBar centrados (`centerTitle: true`).
- **Estado del vehículo en resumen:** lista dinámica desde API; sin hardcodear etiquetas en UI.
- **Errores controlados:** `AppException` y subclases; UI con `AppAlertBanner` (auto-cierre 3 s) y `QuickAlert` en resumen de turno.
- **Sin lógica de red en UI:** controllers orquestan; red en datasources/servicios.
- **Web:** deep links por hash; fotos con `Image.memory` / bytes; banner con contexto de overlay; viewport fijo y sin zoom post-permisos de cámara (`web/index.html`); carga de imágenes de red con `frameBuilder` en `ExpandableNetworkImage`; assets de vehículo en Inspección Exterior según tema solo en Web.
- **Fotos en checklist:** `Uint8List` en memoria para compatibilidad web.
- **Reportes PDF:** descarga binaria con `ApiClient.getBytes`; compartir con `share_plus`; nombre de archivo desde `Content-Disposition`.
- **Inspección Exterior:** selección de asset centralizada en `VehicleInspectionAssets`; PNG en nativo, WebP temático en Web.
- **Build Android:** nombre de APK release `shiftControlAPP.apk` (Gradle `applicationVariants`).

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
          POST /api/embed/validate-pose, POST /api/rostros
          POST /api/face-auth/enroll (legacy; no usado en UI actual de Afiliar Rostro)
Turnos:   /api/turnos/*, /api/bitacora-vehicular/informacion-general
          /api/ubicacion/reverse, /api/turnos/incidencias/*
Placas:   POST /api/plate/read, GET /api/placas/validar, POST /api/placas
Reportes: GET /api/reportes/turno/{id} (PDF), POST /api/reportes/turno/{id}/enviar
```
