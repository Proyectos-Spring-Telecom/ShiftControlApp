# Plan de implementación: GET /auth/me (BehaviorIQ)

## 1. Objetivo

Integrar el servicio **GET /auth/me** del API BehaviorIQ para obtener los datos del usuario autenticado **inmediatamente después** de un login exitoso en `https://spcode.ddns.net/api-behavioriq/auth/login`. La información devuelta (idUsuario, idCliente, idSolucion, usuario, isRoot, rol) se usará en otros servicios del mismo API.

**Base URL:** `https://spcode.ddns.net/api-behavioriq` (`AppEnvironmentConfig.faceAuthBaseUrl`).

---

## 2. Contrato del servicio

### 2.1 Request

| Elemento | Especificación |
|----------|----------------|
| **Método** | GET |
| **URL** | `GET {API_BASE_URL}/auth/me` → `https://spcode.ddns.net/api-behavioriq/auth/me` |
| **Headers** | `Accept: application/json`, `Authorization: Bearer {token}` |

**Ejemplo cURL:**
```bash
curl -X 'GET' \
  'https://spcode.ddns.net/api-behavioriq/auth/me' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer {token}'
```

### 2.2 Respuesta 200

| Código | Significado |
|--------|-------------|
| **200** | Datos del usuario autenticado. |

**Response body (200):**
```json
{
  "idUsuario": 2,
  "idCliente": 2,
  "idSolucion": 2,
  "usuario": "admin@shiftcontrol.mx",
  "isRoot": false,
  "rol": "admin"
}
```

| Campo      | Tipo    | Descripción                          |
|-----------|---------|--------------------------------------|
| idUsuario | number  | Identificador del usuario.           |
| idCliente | number  | Identificador del cliente.          |
| idSolucion| number  | Identificador de la solución.        |
| usuario   | string  | Correo o usuario (ej. admin@...).     |
| isRoot    | boolean | Si el usuario es root.                |
| rol       | string  | Rol (ej. "admin").                    |

---

## 3. Flujo en la app

### 3.1 Momento de ejecución

- **Enseguida del login exitoso** del endpoint `https://spcode.ddns.net/api-behavioriq/auth/login`.
- Secuencia: `POST /auth/login` → se recibe `accessToken` → **GET /auth/me** con `Authorization: Bearer {accessToken}`.

### 3.2 Uso actual

- El flujo **Face Auth** ya realiza este orden en `FaceAuthService.loginAndGetIdCliente()`:
  1. `_datasource.login(usuario, contrasena)` → token.
  2. `_datasource.me(token)` → idCliente, usuario (y otros según modelo).

- El resultado de **/auth/me** se expone en `FaceAuthCredentialsResult` (token, idCliente, usuario) y se usa en pasos posteriores (p. ej. `validateFace` con idCliente).

### 3.3 Requisitos del plan

1. **Ejecutar GET /auth/me** justo después de un login exitoso a BehaviorIQ (ya cubierto en Face Auth).
2. **Imprimir en consola** la respuesta completa con `debugPrint` para depuración.
3. **Modelo de datos** que refleje todos los campos del response (idUsuario, idCliente, idSolucion, usuario, isRoot, rol) para uso en otros servicios API.

---

## 4. Tareas de implementación

### 4.1 Capa de datos (datasource)

- **Archivo:** `lib/data/datasources/remote/face_auth_remote_datasource.dart`.
- **Estado actual:** GET /auth/me ya implementado en `me(String token)`; se parsean idCliente, usuario, idSolucion.
- **Tareas:**
  - Ampliar **FaceAuthMeResult** con: `idUsuario` (int?), `isRoot` (bool?), `rol` (String?), manteniendo idCliente, usuario, idSolucion.
  - En `me()`, parsear y asignar idUsuario, isRoot, rol del JSON.
  - Añadir **debugPrint** con la respuesta completa del body (ej. `debugPrint('[FaceAuth] auth/me response: ${response.body}');`) para que en consola se vea el JSON tal cual.

### 4.2 Servicio (Face Auth)

- **Archivo:** `lib/features/auth/services/face_auth_service.dart`.
- **Tareas:**
  - Exponer en **FaceAuthCredentialsResult** los campos adicionales que necesiten otros servicios (p. ej. idUsuario, idSolucion, isRoot, rol), o devolver **FaceAuthMeResult** completo junto al token para uso posterior.
  - No cambiar el orden: login → me (ya correcto).

### 4.3 Uso en otros servicios API

- Cuando se implementen otros endpoints que requieran **idUsuario**, **idCliente**, **idSolucion**, **rol** o **isRoot**, obtenerlos del resultado de **/auth/me** (guardado en memoria, provider o sesión tras el login BehaviorIQ).

---

## 5. Resumen de archivos

| Archivo | Acción |
|---------|--------|
| `lib/data/datasources/remote/face_auth_remote_datasource.dart` | Ampliar FaceAuthMeResult; parsear idUsuario, isRoot, rol; debugPrint respuesta completa. |
| `lib/features/auth/services/face_auth_service.dart` | Opcional: exponer más campos de /auth/me en FaceAuthCredentialsResult o tipo devuelto. |
| `docs/11-plan-api-auth-me-integracion.md` | Plan (este documento). |

---

## 6. Referencias

- **API BehaviorIQ:** `https://spcode.ddns.net/api-behavioriq`
- **Login:** POST /auth/login (devuelve token).
- **Me:** GET /auth/me (datos del usuario; ejecutar tras login exitoso).
