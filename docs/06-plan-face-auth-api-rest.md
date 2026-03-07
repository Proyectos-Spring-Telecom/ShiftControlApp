# Plan de implementación: Face Auth con servicios API REST

## 1. Objetivo

Integrar el flujo **Iniciar con FaceAuth** con los servicios API REST de autenticación por rostro. Cuando el usuario toque el botón "Iniciar con FaceAuth", la app ejecutará en orden: login (token), obtención de idCliente, dos capturas de rostro (con pausa de ~2 s), liveness-check, extracción de embedding (512D) y validateFace; en éxito se considerará al usuario autenticado y se navegará a Home.

**Referencia de documentación API:** [Swagger API BehaviorIQ](https://spcode.ddns.net/api-behavioriq/docs/#/).

**Base URL del API Face Auth:** Configurable en `AppEnvironmentConfig`: `faceAuthBaseUrl` (ej. `https://spcode.ddns.net/api-behavioriq`). Opcionalmente `faceAuthLivenessBaseUrl` (ej. `https://faceauth.ddns.net/api`) solo para `POST /embed/liveness-check`.

---

## 2. Flujo en 6 pasos (resumen)

| Paso | Descripción | Método / ruta | Salida clave |
|------|-------------|---------------|--------------|
| 1 | Login (obtener token) | POST `/auth/login` | `accessToken` (JWT) |
| 2 | Obtener idCliente | GET `/auth/me` | `idCliente` |
| 3 | Dos capturas de rostro | (en app) | `capture1`, `capture2` (bytes) |
| 4 | Liveness-check | POST `/embed/liveness-check` | `passed`, `reason` |
| 5 | Embed (embedding 512D) | POST `/embed` | `embedding` (array 512 números) |
| 6 | ValidateFace | POST `/auth/validateFace/{idCliente}` | `success`, `nombre`, `paterno`, `materno`, etc. |

Todos los pasos posteriores al 1 usan el header **Authorization: Bearer {token}**.

---

## 3. Contrato API detallado

### 3.1 Paso 1 — Login (obtener token)

- **URL:** `POST {API_BASE_URL}/auth/login`  
  Ejemplo: `https://faceauth.ddns.net/api/auth/login`
- **Headers:** `Content-Type: application/json`, `Accept: application/json`
- **Body (JSON):**
  ```json
  { "usuario": "...", "contrasena": "..." }
  ```
- **Respuesta (éxito):** JSON con el token de acceso. Ejemplo: `accessToken` o el campo que devuelva el API (documentar según Swagger).
  - La app debe **guardar este token** en memoria (o en un estado del flujo) para usarlo en los pasos 2, 4, 5 y 6.
- **Errores:** 400/401 con mensaje; no continuar y mostrar mensaje al usuario.

### 3.2 Paso 2 — Obtener idCliente

- **URL:** `GET {API_BASE_URL}/auth/me`
- **Headers:** `Authorization: Bearer {token}` (token del paso 1)
- **Respuesta (éxito):** JSON con `idCliente`, `idSolucion`, `usuario`, etc.
  - **Guardar `idCliente`** para el paso 6 (validateFace).
- **Errores:** 401 (token inválido); no continuar.

### 3.3 Paso 3 — Dos capturas de rostro (en la app)

- **Captura 1:** Foto del rostro de frente. Mensaje: *"Mantenga la posición al frente"*; countdown *"Captura en 2 segundos."* / *"Captura en 1 segundo."*; captura automática a los 2 s. Se guarda en memoria (`Uint8List` / `List<int>`).
- **Transición:** Mensaje *"Gira un poco el rostro a la derecha o izquierda."* y countdown *"Segunda captura en 2 segundos…"* / *"Segunda captura en 1 segundo…"*; esperar 2 s.
- **Captura 2:** Segunda foto (misma pantalla, misma sesión de cámara). Se guarda en memoria.
- No hay tercera captura; solo estas dos.
- Salida: dos buffers (`capture1`, `capture2`) para el Paso 4 (liveness-check). La segunda captura se usa además en el Paso 5 (embed).

### 3.4 Paso 4 — Liveness-check (prueba de vida)

- **URL:** `POST {API_BASE_URL}/embed/liveness-check` (si está definido `faceAuthLivenessBaseUrl`, se usa esa base solo para este endpoint).
- **Headers:** `Authorization: Bearer {token}`, `Accept: application/json`. Body `multipart/form-data` (el cliente fija el boundary).
- **Body (multipart):** Exactamente **dos archivos**, mismo nombre de campo **`files`**:
  - Parte 1: primera captura → `filename: capture_0.jpg`, `Content-Type: image/jpeg`.
  - Parte 2: segunda captura → `filename: capture_1.jpg`, `Content-Type: image/jpeg`.
- **Respuesta (éxito):** JSON:
  ```json
  { "passed": boolean, "reason": string, "score"?: number }
  ```
- **Lógica:**
  - Si `passed === false` → mostrar `reason` al usuario, permitir **Reintentar** (volver al Paso 3) y **no** ejecutar pasos 5 ni 6. Opción **Volver al login**.
  - Si `passed === true` → continuar al Paso 5 (Embed).

### 3.5 Paso 5 — Embed (extraer embedding 512D)

- **URL:** `POST {API_BASE_URL}/embed`
- **Headers:** `Authorization: Bearer {token}`, `Accept: application/json`. Body `multipart/form-data`.
- **Body (multipart):** Un solo archivo, **campo `file`** (singular), con la **segunda captura** (misma imagen que la segunda de liveness). Ej. `filename: capture.jpg`, `Content-Type: image/jpeg`.
- **Respuesta (éxito):** JSON con el arreglo **embedding 512D** (InsightFace ArcFace):
  ```json
  { "embedding": [ 512 números ] }
  ```
- Ese mismo arreglo (512 números) se envía en el Paso 6 en el body de validateFace.

### 3.6 Paso 6 — ValidateFace (identificar persona)

- **URL:** `POST {API_BASE_URL}/auth/validateFace/{idCliente}`  
  Donde `idCliente` es el obtenido en el paso 2.
- **Headers:** `Authorization: Bearer {token}`, `Content-Type: application/json`, `Accept: application/json`.
- **Body (JSON):** El arreglo 512D devuelto por `/embed` se envía como valor de **`embeddings`** (array de 512 números, no array de arrays):
  ```json
  {
    "embeddings": [ -1.22, -0.33, 1.19, ... (512 números en total) ... ]
  }
  ```
  Es decir: `"embeddings"` es un **único array con exactamente 512 elementos** (el vector del Paso 5).
- **Respuesta (reconocido):** Ejemplo:
  ```json
  { "success": true, "nombre": "...", "paterno": "...", "materno": "...", "distancia": ... }
  ```
  Con estos datos se considera al usuario autenticado; la app guarda sesión y navega a **Home**.
- **Respuesta (no reconocido):** 404 (ej. rostro no enrolado o no coincide). Mostrar pantalla con mensaje *"Rostro no reconocido. Es posible que no esté registrado..."*, botones **Reintentar** (volver al Paso 3) y **Volver al login** (cerrar flujo). No dejar loading infinito.

---

## 4. Requisitos previos en la UI actual

- El usuario debe poder ingresar **usuario** y **contrasena** antes de tocar "Iniciar con FaceAuth" (o la app debe solicitarlos al iniciar el flujo). El paso 1 usa estos valores.
- Pantallas de captura ya implementadas: **FaceAuthCapturePage** (óvalo, cámara frontal automática). Falta:
  - Inserción del mensaje *"Mantenga la posición, segunda captura en 2 segundos…"* y espera de ~2 s entre captura 1 y captura 2.
  - Sustituir la simulación de validación por las llamadas reales a los pasos 4, 5 y 6.

---

## 5. Configuración

- **Base URL del API Face Auth:** Debe ser configurable (distinta de la base URL del API principal de la app si aplica).
  - Opción A: Añadir en `AppEnvironmentConfig` (o en `app_environment.dart`) una variable `faceAuthBaseUrl` (ej. `https://faceauth.ddns.net/api`).
  - Opción B: Archivo de config específico para Face Auth (ej. `lib/config/face_auth_config.dart`) con `baseUrl` y, si aplica, paths relativos.
- Documentar en este plan o en `02-contratos-capas-modulos.md` la base URL y los paths usados.

---

## 6. Capa de red / cliente HTTP

- El API principal usa `ApiClient` con JSON. Los pasos **4 y 5** requieren **multipart/form-data** (envío de archivos).
- **Opciones:**
  1. **Nuevo cliente solo para Face Auth:** Implementar un `FaceAuthApiClient` (o similar) que use `http.MultipartRequest` (o `dio` si se añade) para `liveness-check` y `embed`, y `http.get`/`http.post` con JSON para login, `auth/me` y `validateFace`.
  2. **Extender ApiClient:** Añadir método `postMultipart(path, files, {headers})` en la interfaz y en `HttpApiClient`; usar solo desde el servicio de Face Auth para no acoplar el resto de la app.
- Recomendación: **Cliente dedicado Face Auth** con base URL propia y métodos: `login`, `me`, `livenessCheck(multipart)`, `embed(multipart)`, `validateFace(idCliente, embeddings)`. Así se mantiene el contrato actual de `ApiClient` y se aísla la base URL y el formato multipart.

---

## 7. Estructura de archivos propuesta

```
lib/
├── config/
│   └── app_environment.dart          # Añadir faceAuthBaseUrl (o crear face_auth_config.dart)
├── core/
│   └── network/
│       └── ...                      # ApiClient sin cambios; opcional postMultipart
├── data/
│   └── datasources/remote/
│       └── face_auth_remote_datasource.dart   # NUEVO: login, me, livenessCheck, embed, validateFace
├── domain/
│   └── entities/
│       └── face_auth_user.dart      # NUEVO (opcional): nombre, paterno, materno, etc.
├── features/
│   └── auth/
│       ├── services/
│       │   └── face_auth_service.dart   # NUEVO: orquesta los 6 pasos, usa datasource
│       └── face_auth/                   # Ya existe (capture, flow)
├── presentation/
│   ├── auth/
│   │   ├── face_auth/
│   │   │   ├── face_auth_capture_page.dart
│   │   │   └── face_auth_flow_page.dart   # Modificar: credenciales, 2 capturas + 2 s, llamadas reales
│   │   └── login/
│   │       └── login_page.dart           # Asegurar que usuario/contrasena estén disponibles para Face Auth
│   └── controllers/
│       └── auth_controller.dart           # Opcional: loginWithFaceAuth() que guarde sesión tras validateFace
```

---

## 8. Tareas de implementación (orden sugerido)

### 8.1 Configuración

- [ ] Definir **base URL** del API Face Auth (ej. `https://faceauth.ddns.net/api`) y añadirla en config (ej. `AppEnvironmentConfig.faceAuthBaseUrl` o `FaceAuthConfig.baseUrl`).
- [ ] Confirmar en Swagger los nombres exactos de campos de respuesta (ej. `accessToken` vs `token`, `idCliente`, etc.) y documentarlos en este plan o en 02-contratos.

### 8.2 Cliente / datasource Face Auth

- [ ] Crear **FaceAuthRemoteDatasource** (o cliente HTTP dedicado) que:
  - Use la base URL de Face Auth (sin usar el token del login principal de la app).
  - **login(usuario, contrasena):** POST `/auth/login` JSON → devolver token (y guardarlo en el flujo o en el servicio).
  - **me(token):** GET `/auth/me` con Bearer → devolver mapa con `idCliente`, etc.
  - **livenessCheck(token, bytes1, bytes2):** POST `/embed/liveness-check` multipart con dos archivos en campo `files` → devolver `{ passed, reason, score? }`.
  - **embed(token, bytesSegundaCaptura):** POST `/embed` multipart con un archivo en campo `file` → devolver `{ embedding }`.
  - **validateFace(token, idCliente, embedding):** POST `/auth/validateFace/{idCliente}` JSON `{ "embeddings": [ n1, n2, ..., n512 ] }` (array directo de 512 números) → devolver mapa con success, nombre, paterno, materno, etc.
- [ ] Implementar envío **multipart** (p. ej. `http.MultipartRequest`, o paquete `http` con `multipart/form_data`) para liveness-check y embed.
- [ ] Mapear códigos HTTP y cuerpos de error a excepciones (AuthException / NetworkException) coherentes con el resto de la app.

### 8.3 Servicio de aplicación (orquestación)

- [ ] Crear **FaceAuthService** (en `features/auth/services/`) que:
  - Reciba usuario y contrasena (o los lea del estado del login).
  - Ejecute en orden: login → me → (dejar listo para recibir dos capturas).
  - Tras recibir captura1 y captura2: livenessCheck → si passed, embed → validateFace.
  - Devuelva un resultado tipado (éxito con datos de usuario / error con mensaje) para que la UI muestre éxito o error.
- [ ] Decidir cómo se persiste la sesión tras validateFace exitoso: ¿se guarda el token del paso 1 en SharedPreferences (o solo en memoria)? ¿Se construye un `User`/`UserModel` a partir de nombre/paterno/materno y se llama a `AuthLocalDatasource.saveSession`? Documentar y aplicar.

### 8.4 Flujo UI (FaceAuthFlowPage)

- [ ] **Credenciales:** Asegurar que al tocar "Iniciar con FaceAuth" se disponga de usuario y contrasena (si el usuario no ha llenado el formulario, mostrar mensaje "Ingresa usuario y contraseña para usar Face Auth" o abrir un paso previo que los pida).
- [ ] **Orden del flujo:**  
  1) Llamar a login y luego a me (mostrando indicador de carga). Si falla, mostrar error y no abrir capturas.  
  2) Abrir **captura 1**; al confirmar, mostrar texto *"Mantenga la posición, segunda captura en 2 segundos…"* y **esperar 2 segundos**.  
  3) Abrir **captura 2**; al confirmar, llamar a liveness-check con las dos imágenes.  
  4) Si liveness no passed → mostrar `reason`, botón Reintentar (volver a capturas o a liveness según diseño).  
  5) Si liveness passed → llamar a embed con la segunda captura, luego validateFace con idCliente y embedding.  
  6) Si validateFace success → guardar sesión (según 8.3) y navegar a Home. Si no (404 u otro) → mostrar mensaje "Rostro no reconocido" (o el mensaje del API) y permitir reintentar.
- [ ] Reemplazar **`_simulateValidation()`** por la llamada al FaceAuthService (pasos 4, 5, 6) usando las dos capturas y el token/idCliente ya obtenidos.
- [ ] Manejar estados de carga y error en cada paso (AppAlertBanner o pantalla de error) y permitir cerrar/reintentar.

### 8.5 Integración con AuthController / sesión

- [ ] Definir si, tras validateFace exitoso, se debe:
  - Llamar a `AuthController` (o AuthLocalDatasource) para guardar sesión con un token y usuario derivados de la respuesta de Face Auth, de modo que el resto de la app (Home, perfil) considere al usuario logueado; o
  - Mantener una sesión "Face Auth" separada y solo navegar a Home con un flag (menos común).
- [ ] Si se integra con el flujo actual: crear o reutilizar modelo de usuario (nombre, paterno, materno, etc.) y token; persistir con `saveSession` y notificar al AuthController para que el estado sea "authenticated" y la ruta inicial sea Home.

### 8.6 Pruebas y ajustes

- [ ] Probar flujo completo con API real: login → me → 2 capturas → liveness → embed → validateFace.
- [ ] Probar casos de error: login incorrecto, liveness no passed, validateFace 404.
- [ ] Ajustar nombres de campos según la respuesta real del API (Swagger / pruebas).

---

## 9. Resumen de endpoints (referencia rápida)

| Paso | Método | Ruta | Body | Notas |
|------|--------|------|------|--------|
| 1 | POST | `/auth/login` | JSON: usuario, contrasena | Guardar token |
| 2 | GET | `/auth/me` | — | Header Bearer; guardar idCliente |
| 3 | — | (en app) | — | 2 capturas, pausa 2 s |
| 4 | POST | `/embed/liveness-check` | multipart: files (x2) | passed / reason |
| 5 | POST | `/embed` | multipart: file (1) | embedding 512D |
| 6 | POST | `/auth/validateFace/{idCliente}` | JSON: `{ "embeddings": [ 512 números ] }` | success, nombre, paterno, materno |

---

## 10. Debug e implementación actual

- En **FaceAuthRemoteDatasource** se imprimen con `debugPrint` (prefijo `[FaceAuth]`) las respuestas de cada paso: status code, body (o resumen) y datos parseados. Útil para validar en consola que cada servicio recibe y devuelve lo esperado.
- **Config:** `AppEnvironmentConfig.faceAuthBaseUrl` y opcional `faceAuthLivenessBaseUrl`; liveness-check usa esta última si está definida.
- **Paso 6:** Si el embedding no tiene 512 elementos se lanza `NetworkException` antes de enviar. El body enviado es exactamente `{ "embeddings": embedding }` con `embedding` de longitud 512.

---

## 11. Relación con otros documentos

- **05-plan-face-auth-login.md:** Define la UI y el flujo de captura; este plan (06) concreta la integración con el API REST en 6 pasos.
- **08-plan-paso-3-4-capturas-y-liveness.md:** Detalle del Paso 3 (mensajes, countdown) y Paso 4 (liveness, mensaje "Gire...", 404).
- **02-contratos-capas-modulos.md:** Se puede extender con el contrato del FaceAuthRemoteDatasource y la base URL de Face Auth.
- **Swagger:** [API BehaviorIQ](https://spcode.ddns.net/api-behavioriq/docs/#/) — referencia para paths y esquemas exactos.
