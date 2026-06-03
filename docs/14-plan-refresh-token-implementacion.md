# Plan de implementación: Refresh Token en autenticación existente

## Objetivo

Extender el sistema de autenticación actual **sin reescribir el login** para soportar:

- Renovación automática del access token cuando expire.
- Reintento automático de requests que fallen con 401/403.
- Logout automático si el refresh token ya no es válido.
- Manejo seguro y centralizado de tokens.
- Arquitectura limpia y escalable (sin modificar pantallas UI).

---

## Contrato del backend (referencia)

### Login

- **Endpoint:** `POST /auth/login` (o el que use actualmente el proyecto, ej. `POST /api/login`).
- **Respuesta esperada (extendida):**
```json
{
  "success": true,
  "token": "JWT_ACCESS_TOKEN",
  "refreshToken": "REFRESH_TOKEN"
}
```
- `token` = access token (JWT corta duración).
- `refreshToken` = refresh token (larga duración).

### Refresh

- **Endpoint:** `POST /auth/refresh` (path a confirmar según baseUrl del proyecto).
- **Body:**
```json
{
  "refreshToken": "REFRESH_TOKEN"
}
```
- **Respuesta 200:**
```json
{
  "token": "NEW_ACCESS_TOKEN",
  "refreshToken": "NEW_REFRESH_TOKEN"
}
```
- Si la respuesta es 401 o 403 → refresh token expirado o revocado → logout automático.

---

## Estado actual del proyecto (resumen)

- **Login:** `AuthRemoteDatasource.login` → POST al endpoint de login; retorna `LoginResult(user, token)`. No hay `refreshToken` en la respuesta actual.
- **Persistencia:** `AuthLocalDatasource` (SharedPreferences) guarda `token` en `AppConstants.keyAuthToken`; no existe clave para refresh token.
- **Cliente HTTP:** `HttpApiClient` implementa `ApiClient`; usa un callback `getToken` para añadir `Authorization: Bearer <token>`; no hay interceptor; en 401/403 lanza `AuthException` y no hay reintento ni refresh.
- **Pantallas:** No se modifican; la lógica se centraliza en servicios e interceptores.

---

## 1. Almacenamiento de tokens (TokenStorageService)

### 1.1 Responsabilidad

- **Centralizar** lectura/escritura de access token y refresh token.
- **No** exponer SharedPreferences ni claves fuera de este servicio.
- Regla: access token en “estado de autenticación actual” (puede ser memoria o el mismo almacenamiento persistente; el plan recomienda persistir ambos para consistencia con el flujo actual y para que `getToken()` siga funcionando tras reinicio).

### 1.2 API propuesta

| Método | Firma | Comportamiento |
|--------|--------|----------------|
| saveToken | `Future<void> saveToken(String token)` | Persiste access token (misma key que hoy o una dedicada). |
| getToken | `Future<String?> getToken()` | Devuelve access token o null. |
| saveRefreshToken | `Future<void> saveRefreshToken(String refreshToken)` | Persiste refresh token (nueva key). |
| getRefreshToken | `Future<String?> getRefreshToken()` | Devuelve refresh token o null. |
| clearTokens | `Future<void> clearTokens()` | Borra token y refreshToken (y opcionalmente el resto de datos de sesión, o delegar en AuthLocalDatasource). |

### 1.3 Ubicación e implementación

- **Ubicación sugerida:** `lib/core/auth/token_storage_service.dart` (o `lib/features/auth/services/token_storage_service.dart`).
- **Implementación:** Usar SharedPreferences (las mismas prefs que usa `AuthLocalDatasource`). Nueva constante en `AppConstants`: `keyRefreshToken = 'refresh_token'`.
- **Inyección:** Provider de Riverpod que dependa de `sharedPreferencesProvider`; el resto del código usa solo `TokenStorageService`, no accede a localStorage directamente.

### 1.4 Integración con sesión existente

- **Opción A:** `TokenStorageService` solo maneja token + refreshToken; al hacer login/refresh, quien orquesta (AuthService / AuthRepository) llama a `TokenStorageService` para tokens y a `AuthLocalDatasource.saveSession` para usuario (y opcionalmente token, para no duplicar lógica de “sesión”).
- **Opción B:** `AuthLocalDatasource` se extiende con `saveRefreshToken`, `getRefreshToken` y en `clearSession` también borra refresh token; `TokenStorageService` sería un wrapper fino sobre AuthLocalDatasource + constantes para no acoplar el resto del código a “auth_local”. El plan recomienda un **servicio explícito TokenStorageService** que use las mismas prefs y que AuthLocalDatasource (o AuthRepository) llame a clearTokens al hacer logout, para mantener una sola fuente de verdad para “tokens”.

---

## 2. Extender modelo de login y persistencia

### 2.1 Respuesta de login

- Si el backend ya devuelve `refreshToken`, extender el DTO de respuesta (por ejemplo `LoginResponseModel` o el que se use) con campo opcional `refreshToken`.
- Al parsear la respuesta del login, si existe `refreshToken`, guardarlo vía `TokenStorageService.saveRefreshToken`.
- El access token se sigue guardando como hasta ahora (o vía `TokenStorageService.saveToken` si se centraliza ahí).

### 2.2 AuthLocalDatasource

- Añadir clave `keyRefreshToken` en `AppConstants`.
- Añadir métodos: `saveRefreshToken(String refreshToken)`, `getRefreshToken()`, y en `clearSession()` eliminar también la clave del refresh token.
- O bien: que `clearSession()` llame a un método de `TokenStorageService.clearTokens()` si se decide que TokenStorageService sea el dueño de las keys de tokens y AuthLocalDatasource solo de usuario/sesión. En ese caso, `TokenStorageService` puede ser el que escribe/lee `keyAuthToken` y `keyRefreshToken`.

### 2.3 Decisión de diseño recomendada

- **TokenStorageService** como única interfaz para token y refreshToken: implementación que use SharedPreferences con `keyAuthToken` y `keyRefreshToken`.
- En login exitoso: `TokenStorageService.saveToken(token)`, `TokenStorageService.saveRefreshToken(refreshToken)` (si viene en la respuesta).
- En logout: `TokenStorageService.clearTokens()` y el resto de limpieza de sesión (usuario, etc.) en `AuthLocalDatasource.clearSession()` (clearSession puede llamar a TokenStorageService.clearTokens para no duplicar keys).

---

## 3. Endpoint de refresh y AuthService / AuthRemoteDatasource

### 3.1 AuthRemoteDatasource

- Añadir método: `Future<RefreshResult> refreshToken(String refreshToken)`.
- **RefreshResult:** DTO con `token` y `refreshToken` (ambos String).
- Implementación: `POST /auth/refresh` (o `/api/auth/refresh` según baseUrl) con body `{"refreshToken": "<refreshToken>"}`.
- **Importante:** Esta llamada **no** debe usar el interceptor que añade Bearer (o debe usar un cliente sin auth), para no enviar el access token expirado. Path debe ser considerado “no protegido” en el cliente (como login).
- En 401/403 en este endpoint → lanzar AuthException (refresh fallido).

### 3.2 AuthService (o capa que orquesta login)

- Añadir método `Future<String?> refreshToken()` (o equivalente que devuelva el nuevo access token).
- Lógica:
  1. Obtener refreshToken desde `TokenStorageService.getRefreshToken()`.
  2. Si es null o vacío → retornar null (o lanzar; el interceptor interpretará como “no se pudo renovar”).
  3. Llamar a `AuthRemoteDatasource.refreshToken(refreshToken)`.
  4. Si la respuesta es exitosa: llamar a `TokenStorageService.saveToken(newToken)` y `TokenStorageService.saveRefreshToken(newRefreshToken)`.
  5. `debugPrint` tipo: "Intentando renovar token...", "Token renovado correctamente" (sin imprimir tokens completos).
  6. Retornar el nuevo access token.

### 3.3 Evitar múltiples refreshes simultáneos

- En el punto donde se llame a refresh (p. ej. dentro del interceptor o del cliente), usar un flag `_isRefreshing` (o equivalente).
- Si ya hay un refresh en curso, **esperar** su resultado (p. ej. con un Completer o una cola de espera) y reutilizar el nuevo token para todas las requests en espera.
- Solo **un** intento de refresh por “oleada” de 401/403; si ese intento falla, no reintentar refresh para la misma causa (logout).

---

## 4. Interceptor HTTP global (cliente que maneja 401/403 y reintento)

### 4.1 Ubicación

- **Extender** `HttpApiClient` (o crear un wrapper/decorator sobre `ApiClient`) para que antes de cada request obtenga el token desde `TokenStorageService.getToken()` y lo envíe en `Authorization: Bearer <token>`.
- El cliente actual ya usa un callback `getToken`; ese callback puede apuntar a `TokenStorageService.getToken()`.

### 4.2 Flujo ante 401/403

1. Request se envía con `Authorization: Bearer <token>`.
2. Si la respuesta es **401** o **403**:
   - Si el path es el de refresh (`/auth/refresh` o el que sea): **no** reintentar; lanzar AuthException → el orquestador hará logout.
   - Si es otra request:
     - Intentar **una vez** llamar a `refreshToken()` (AuthService o el orductor que tenga acceso a TokenStorageService y AuthRemoteDatasource).
     - Si refresh tiene éxito: actualizar tokens en TokenStorageService y **repetir la request original** con el nuevo token (mismo método, path, body, headers salvo Authorization).
     - Si refresh falla (401/403 o error): no reintentar; llamar a `TokenStorageService.clearTokens()` (y lógica de logout: limpiar sesión y redirigir al login). `debugPrint("Refresh token expirado. Cerrando sesión.")`.

### 4.3 Evitar loop infinito

- Solo **1** intento de refresh por request que devolvió 401/403.
- Flag `_isRefreshing`: si otra request recibe 401 mientras ya hay un refresh en curso, esa request debe **esperar** al resultado del refresh (no lanzar otro refresh) y luego reintentar con el nuevo token, o si el refresh falló, recibir logout.

### 4.4 Paths que no llevan Authorization

- No enviar Authorization (y no intentar refresh) en:
  - Path de login (ya implementado: path contiene `login`).
  - Path de refresh (`/auth/refresh` o el definido).
- El cliente debe conocer la lista de “paths sin auth” para no adjuntar token ni disparar refresh para ellos.

---

## 5. Logout automático y manual

### 5.1 Logout automático (refresh fallido)

- Cuando el endpoint de refresh devuelve 401/403:
  - `TokenStorageService.clearTokens()`.
  - Llamar a la lógica existente de “cerrar sesión” (p. ej. `AuthLocalDatasource.clearSession()` si aún guarda algo más, y notificar a la UI para redirigir al login).
  - `debugPrint("Refresh token expirado. Cerrando sesión.")`.
- La forma de “notificar” a la UI puede ser un callback/canal que el AuthController o el cliente registre al iniciar la app (sin modificar pantallas, solo el flujo de “estado no autenticado” y navegación a login).

### 5.2 Logout manual

- Al cerrar sesión por el usuario: llamar a `TokenStorageService.clearTokens()` (y `AuthLocalDatasource.clearSession()` como hasta ahora).
- Opcional: si el backend expone `POST /auth/logout`, llamarlo antes de clearTokens (sin bloquear la limpieza local si falla).

---

## 6. Seguridad y buenas prácticas

- **Nunca** imprimir tokens completos en logs; solo mensajes como "Token actualizado correctamente" o "Refresh token expirado".
- El **refreshToken** solo se usa en `POST /auth/refresh`; no se envía en ninguna otra request.
- Mantener el access token en memoria o en el mismo almacenamiento persistente de forma coherente con `getToken()` para que el cliente siempre lea de la misma fuente.

---

## 7. Debugging (debugPrint)

Incluir logs en:

- Login exitoso (ej. "Login exitoso; token guardado").
- Token guardado tras login/refresh (sin valor del token).
- Refresh iniciado ("Intentando renovar token...").
- Refresh exitoso ("Token renovado correctamente").
- Refresh fallido ("Refresh token expirado. Cerrando sesión." o similar).
- Reintento de request tras refresh exitoso (ej. "Reintentando request original").
- Logout automático ("Refresh token expirado. Cerrando sesión.").

---

## 8. Orden de tareas sugerido

1. **Constantes y almacenamiento**
   - Añadir `AppConstants.keyRefreshToken`.
   - Crear `TokenStorageService` (interfaz + impl) con saveToken, getToken, saveRefreshToken, getRefreshToken, clearTokens; implementación con SharedPreferences.
   - Registrar provider de TokenStorageService (depende de sharedPreferencesProvider).

2. **Extender login**
   - Añadir campo opcional `refreshToken` al DTO de respuesta de login (y parsearlo).
   - Tras login exitoso: guardar refreshToken con TokenStorageService (y mantener guardado del token como hasta ahora, idealmente vía TokenStorageService para centralizar).

3. **Refresh en backend**
   - Añadir `RefreshResult` y método `refreshToken(String refreshToken)` en AuthRemoteDatasource; implementar POST /auth/refresh (o path acordado) en la impl real; mock opcional para tests.
   - En AuthService (o orquestador): implementar `refreshToken()` con la lógica descrita (getRefreshToken → llamar remote → saveToken/saveRefreshToken → return new token).

4. **Cliente HTTP e interceptor**
   - Hacer que el callback `getToken` del HttpApiClient obtenga el token desde TokenStorageService (inyección).
   - Implementar en HttpApiClient (o en un interceptor/middleware único):
     - Detección de 401/403 en la respuesta.
     - Exclusión de path de login y de refresh.
     - Flag _isRefreshing y lógica de “esperar un refresh en curso”.
     - Llamada a refreshToken(); si éxito, repetir request original con nuevo token; si fallo, clearTokens + callback de logout y debugPrint.
   - Asegurar que las llamadas a refresh no lleven Authorization (path sin auth).

5. **Logout**
   - En clearSession / logout manual: llamar TokenStorageService.clearTokens() (y mantener clearSession para el resto de datos de usuario si aplica).
   - Conectar el “refresh fallido” del cliente con la misma lógica de logout (clearTokens + notificación para ir al login).

6. **Pruebas y verificación**
   - Login sigue funcionando y guarda refreshToken si el backend lo envía.
   - Request con token expirado → 401 → refresh → reintento de request.
   - Refresh con token inválido → 401/403 → logout automático y redirección a login.
   - No hay loops (solo un refresh por oleada de 401).
   - Logout manual limpia tokens.

---

## 9. Archivos a crear o modificar (resumen)

| Archivo | Acción |
|---------|--------|
| `lib/core/constants/app_constants.dart` | Añadir `keyRefreshToken`. |
| `lib/core/auth/token_storage_service.dart` (o en features/auth) | **Crear:** interfaz + impl con SharedPreferences. |
| `lib/data/models/login_response_model.dart` | Añadir campo opcional `refreshToken` y parseo. |
| `lib/data/datasources/remote/auth_remote_datasource.dart` | Añadir RefreshResult y método refreshToken; impl POST /auth/refresh. |
| `lib/data/datasources/local/auth_local_datasource.dart` | Opcional: saveRefreshToken, getRefreshToken, limpiar refresh en clearSession; o delegar todo en TokenStorageService. |
| `lib/features/auth/services/auth_service.dart` (o donde esté la orquestación) | Añadir refreshToken(); usar TokenStorageService y AuthRemoteDatasource. |
| `lib/core/network/http_api_client.dart` | Integrar lógica 401/403 + refresh + reintento + flag _isRefreshing; getToken desde TokenStorageService. |
| `lib/presentation/controllers/auth_controller.dart` (o main) | Registrar TokenStorageService; conectar callback de “logout por refresh fallido” con AuthController.logout o equivalente. |
| **No modificar** | Pantallas UI (login, perfil, etc.); solo flujo y servicios. |

---

## 10. Resultado esperado

- El login actual sigue funcionando; si el backend envía `refreshToken`, se persiste.
- Las requests usan `Authorization: Bearer <token>` (token desde TokenStorageService).
- Cuando una request recibe 401/403 por token expirado → se intenta refresh una vez → si tiene éxito se repite la request con el nuevo token.
- Si el refresh falla (401/403) → se limpian tokens y se cierra sesión (redirección a login).
- No hay loops infinitos (un solo refresh en vuelo; el resto espera).
- Logout manual limpia tokens y sesión.
- Arquitectura limpia: TokenStorageService, AuthService (refresh), cliente con interceptor; sin código improvisado en UI.

---

## 11. Referencias

- Contrato actual: `docs/02-contratos-capas-modulos.md` (ApiClient, AuthRepository, AuthLocalDatasource).
- Configuración: `lib/config/app_environment.dart` (baseUrl para el endpoint de refresh).
- Este plan: `docs/14-plan-refresh-token-implementacion.md`.
