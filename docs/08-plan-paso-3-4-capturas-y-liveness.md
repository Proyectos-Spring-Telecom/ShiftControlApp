# Plan de implementación: Paso 3 (Dos capturas) y Paso 4 (Liveness-check)

## 1. Objetivo

Definir de forma explícita el **Paso 3** (dos capturas de rostro en la app) y el **Paso 4** (Liveness-check), con el mensaje **"Gire un poco a la derecha o izquierda"** mostrado en el contexto del Paso 4, y asegurar que el flujo llegue correctamente al Paso 5 (Embed) y Paso 6 (ValidateFace). Mejorar el manejo del error 404 "Rostro no reconocido" (que proviene del Paso 6 cuando el usuario no está enrolado o no coincide).

---

## 2. Paso 3 — Dos capturas de rostro (en la app)

### 2.1 Secuencia (contrato implementado)

| Orden | Acción | Detalle |
|-------|--------|---------|
| 1 | **Captura 1** | Foto del rostro de frente. Mensaje: *"Mantenga la posición al frente"*; countdown *"Captura en 2 segundos."* / *"Captura en 1 segundo."*; captura automática a los 2 s. Guardar en memoria (`Uint8List`). |
| 2 | **Mensaje** | *"Gira un poco el rostro a la derecha o izquierda."* y *"Segunda captura en 2 segundos…"* / *"Segunda captura en 1 segundo…"* (misma pantalla, sin cerrar cámara). |
| 3 | **Espera** | 2 segundos (countdown 2 → 1). |
| 4 | **Captura 2** | Segunda foto. Guardar en memoria. Óvalo en verde al completar cada captura (feedback visual). |
| 5 | **Fin** | No hay tercera captura. Devolver `[captura1, captura2]` al flujo para Paso 4 (liveness-check). |

### 2.2 Requisitos de implementación

- Las dos capturas se realizan **en la misma pantalla** (misma sesión de cámara).
- Validar que ambas imágenes tengan longitud > 100 bytes antes de llamar al Paso 4; si no, mostrar error y **Reintentar** (volver a doble captura).

---

## 3. Paso 4 — Liveness-check (prueba de vida)

### 3.1 Dónde mostrar el mensaje

**AQUÍ (en el Paso 4) se muestra el mensaje:**  
**"Gire un poco a la derecha o izquierda"**

- Se debe mostrar cuando la app está realizando o a punto de realizar la **prueba de vida** (liveness-check), para que el usuario entienda qué se está validando y qué hacer si no pasa (reintentar girando la cabeza entre las dos fotos).
- Opciones de ubicación:
  1. **Pantalla de espera del Paso 4:** Al llamar al API de liveness-check, mostrar una pantalla (o el mismo estado "Validando...") con título tipo *"Prueba de vida"* y el texto *"Gire un poco a la derecha o izquierda entre las dos fotos para mejorar el resultado."* (o *"Si no pasa, gire un poco a la derecha o izquierda e intente de nuevo."*).
  2. **Pantalla de reintento:** Si `passed === false`, mostrar la razón y el mensaje *"Gire un poco a la derecha o izquierda"* junto al botón **Reintentar**.

### 3.2 Contrato API — Paso 4

| Elemento | Especificación |
|----------|----------------|
| **URL** | `POST https://faceauth.ddns.net/api/embed/liveness-check` (o `{API_BASE_URL}/embed/liveness-check`). Si el backend usa un host distinto para liveness (p. ej. `faceauth.ddns.net`) que para login/me/validateFace (p. ej. `spcode.ddns.net/api-behavioriq`), configurar una base URL específica para liveness. |
| **Headers** | `Authorization: Bearer {token}`, `Accept: application/json`. |
| **Body** | `multipart/form-data` con **dos archivos**, mismo nombre de campo **`files`**: Parte 1: primera captura (ej. `capture_0.jpg`, Content-Type: image/jpeg). Parte 2: segunda captura (ej. `capture_1.jpg`, Content-Type: image/jpeg). |
| **Respuesta** | `{ "passed": boolean, "reason": string, "score"?: number }`. |
| **Si passed === false** | Mostrar `reason` al usuario, mostrar el mensaje *"Gire un poco a la derecha o izquierda"* y ofrecer **Reintentar** (volver al Paso 3 para nuevas dos capturas). No seguir al Paso 5 ni 6. |
| **Si passed === true** | Seguir al Paso 5 (Embed). |

---

## 4. Flujo resumido (Pasos 3 y 4)

```
[Paso 3]
  → Pantalla cámara: countdown → Captura 1
  → Mensaje: "Mantenga la posición, segunda captura en 2 segundos…"
  → Esperar 2 s
  → Captura 2
  → Validar que ambas imágenes existan y tengan bytes
  → Si no: error + Reintentar. Si sí: continuar.

[Paso 4]
  → Mostrar mensaje: "Gire un poco a la derecha o izquierda" (en pantalla de prueba de vida / validando).
  → POST .../embed/liveness-check con las dos imágenes (campo files, Content-Type image/jpeg).
  → Si passed === false: mostrar reason + "Gire un poco a la derecha o izquierda" + Reintentar (volver a Paso 3).
  → Si passed === true: continuar al Paso 5 (Embed).
```

---

## 5. Error 404 "Rostro no reconocido"

- El **404** suele venir del **Paso 6 (validateFace)**, no del Paso 4. Significa que el backend no encontró una persona registrada que coincida con el embedding (usuario no enrolado o no coincide).
- **Acciones:**
  - Mostrar mensaje claro: *"Rostro no reconocido. Es posible que no esté registrado en el sistema. Intente de nuevo o use otro método de inicio de sesión."*
  - Ofrecer **Reintentar** (volver a Paso 3) y **Volver al login** (cerrar flujo Face Auth).
  - No dejar loading infinito; asegurar `finally` que ponga `_isValidating = false`.

---

## 6. Tareas de implementación (estado actual)

### 6.1 Paso 3 (capturas) — Implementado

- [x] Doble captura en la misma pantalla; mensaje captura 1: *"Mantenga la posición al frente"* + *"Captura en 2 segundos."*; entre capturas: *"Gira un poco el rostro a la derecha o izquierda."* + *"Segunda captura en 2/1 segundos…"*.
- [x] Validar longitud > 100 bytes de ambas imágenes antes del Paso 4; si falla, mensaje y Reintentar.
- [x] Óvalo en verde al completar captura 1 y captura 2.

### 6.2 Paso 4 (liveness) — Implementado

- [x] En el estado "Validando..." del Paso 4: título *"Prueba de vida"* y texto *"Gire un poco a la derecha o izquierda entre las dos fotos."*
- [x] Si `passed === false`: pantalla de reintento con `reason`, *"Gire un poco a la derecha o izquierda..."* y botones **Reintentar** / **Volver al login**.

### 6.3 Base URL para Liveness — Implementado

- [x] `faceAuthLivenessBaseUrl` en config; `FaceAuthRemoteDatasource` usa esa URL solo para `POST embed/liveness-check`; el resto usa `faceAuthBaseUrl`.

### 6.4 Manejo del 404 (ValidateFace) — Implementado

- [x] 404 en validateFace: pantalla con *"Rostro no reconocido. Es posible que no esté registrado..."*, **Reintentar** y **Volver al login**; `_isValidating = false` en `finally`.

---

## 7. Resumen de archivos (implementación actual)

| Archivo | Contrato / comportamiento |
|---------|---------------------------|
| **FaceAuthCapturePage** | Paso 3: "Mantenga la posición al frente" + countdown 2 s → captura 1; "Gira un poco el rostro a la derecha o izquierda" + countdown 2 s → captura 2. Óvalo verde al éxito. `autoCaptureDelaySeconds: 2` cuando se abre desde el flujo. |
| **FaceAuthFlowPage** | Paso 4: "Validando..." con "Prueba de vida" y "Gire un poco a la derecha o izquierda entre las dos fotos."; reintento liveness con reason y "Volver al login"; 404 validateFace con pantalla "Rostro no reconocido" + Reintentar / Volver al login. |
| **FaceAuthRemoteDatasource** | Liveness con `_uriLiveness('embed/liveness-check')`; validateFace body `{ "embeddings": embedding }` (512 números). Debug prints `[FaceAuth]` por paso. |
| **AppEnvironmentConfig** | `faceAuthBaseUrl`, `faceAuthLivenessBaseUrl` (opcional para liveness). |
