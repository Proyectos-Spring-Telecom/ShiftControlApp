# 1. Contexto de la solución

## 1.1 Descripción general

**Turnos Spring** es una aplicación Flutter multiplataforma (Android, iOS, Web) para el control de turnos operativos. Permite autenticación (login con correo/contraseña y NIP), flujos de apertura y cierre de turno (checklist, fotos de resguardo/tablero, odómetro, combustible, daños, reporte de incidentes) y gestión de perfil y apariencia.

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
│   ├── constants/          # Rutas, constantes de app
│   ├── errors/             # AppException, AuthException, NetworkException
│   ├── network/            # ApiClient (contrato), HttpApiClient (impl)
│   ├── theme/              # AppTheme, colores
│   └── utils/              # Validadores, initial route (web/stub), read file bytes (io/stub)
├── data/
│   ├── datasources/
│   │   ├── local/          # AuthLocalDatasource (SharedPreferences)
│   │   └── remote/         # AuthRemoteDatasource (login, recuperar, cambiar contraseña)
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
│   ├── auth/               # Login, recuperar contraseña, nueva contraseña, perfil
│   ├── home/               # MainShell, Drawer, bottom nav, tabs
│   ├── turnos/             # Control turnos, inicio/cierre, odómetro, combustible, daños, incidentes
│   ├── settings/           # Apariencia
│   ├── widgets/            # AppAlertBanner, LoadingOverlay, etc.
│   └── app_router.dart     # Rutas estáticas (login, home, nueva-contrasena)
└── main.dart               # Bootstrap, initialRoute desde hash (web), ProviderScope
```

---

## 1.4 Flujos principales

### Autenticación
- **Login correo/contraseña:** UI → AuthController.login → LoginUseCase → AuthRepository → AuthRemoteDatasource (POST /api/login) + AuthLocalDatasource.saveSession.
- **Login NIP:** AuthController.loginWithNip → AuthService (POST /api/login/operador/accesso/nip) + saveSession.
- **Recuperar acceso:** RecuperarContrasenaPage → AuthController.recuperarAcceso → AuthRepository.recuperarAcceso → POST /api/login/usuario/solicitud/recuperacion → banner + pushNamedAndRemoveUntil(login).
- **Cambiar contraseña desde link:** NuevaContrasenaPage (token en URL) → AuthController.cambiarContrasenaDesdeRecuperacion → AuthRepository → POST /api/login/cambiar/accesso con header Authorization: Bearer {token} → banner + navegación a login.
- **Cierre de sesión:** AuthController.logout → LogoutUseCase → AuthRepository.logout → clearSession.

### Ruta inicial (Web)
- En web, la ruta inicial se resuelve desde el hash (#/nueva-contrasena?token=...).
- Se intenta primero `Uri.base.fragment`; si viene vacío (típico en release), se usa un helper que lee `window.location.hash` (import condicional dart.library.html).
- Si la ruta es `RouteConstants.nuevaContrasena`, se pasa como `initialRoute` a MaterialApp para mostrar NuevaContrasenaPage sin pasar por login.

### Turnos
- Flujo de **inicio/cierre de turno**: selección de vehículo, foto de resguardo (cierre), foto de tablero, captura de odómetro, registro de combustible, niveles de fluido, accesorios, luces, daños, reporte de incidentes, documentación, resumen.
- Las **fotos capturadas** se guardan en memoria como `Uint8List` y se muestran con `Image.memory` para compatibilidad con web (evitar `Image.file`).

---

## 1.5 Decisiones de diseño

- **Contratos por capa:** Las capas se comunican por interfaces (ApiClient, AuthRepository, AuthRemoteDatasource, AuthLocalDatasource). La implementación concreta se inyecta vía Riverpod.
- **Errores controlados:** Se usan `AppException` y subclases (`AuthException`, `NetworkException`, `StorageException`). El cliente HTTP mapea códigos 4xx/5xx a estas excepciones; la UI muestra mensajes vía `AppAlertBanner`.
- **Sin lógica de red en UI ni en controllers de negocio:** Los controllers orquestan (validan, llaman repos/servicios, muestran banners y navegación); la red está en datasources/servicios.
- **Web:** Deep links por hash; visualización de fotos con bytes (`Image.memory`); lectura del hash con import condicional; overlay del banner usa el contexto del overlay para `MediaQuery` y evitar null tras navegación.
- **Ambiente:** Un solo punto de configuración (`config/app_environment.dart`): `current` (dev/qa/prod) y `AppEnvironmentConfig.baseUrl` para el ApiClient.

---

## 1.6 Convenciones

- **Nombres de rutas:** Centralizados en `RouteConstants`; rutas con query (ej. token) se construyen con helpers (ej. `nuevaContrasenaWithToken(token)`).
- **AppRouter:** Recibe `RouteSettings.name` que puede incluir query; se normaliza el path para el switch y se extrae el token para NuevaContrasenaPage.
- **Debug:** Se usa `debugPrint` en datasources, controller y puntos críticos (resolución de ruta, éxito/error de recuperación y cambio de contraseña).
