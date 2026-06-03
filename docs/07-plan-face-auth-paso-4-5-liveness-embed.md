# Plan de implementación: Paso 4 (Liveness-check) y Paso 5 (Embed) — Face Auth

## 1. Objetivo

Asegurar que el flujo Face Auth **llegue correctamente al Paso 4 (Liveness-check)** y al **Paso 5 (Embed)**, y mejorar la UX indicando al usuario que **gire un poco a la derecha o izquierda** durante la prueba de vida para aumentar la probabilidad de pasar.

**Referencia API:** [Swagger API BehaviorIQ](https://spcode.ddns.net/api-behavioriq/docs#/).

**Base URL en uso:** `https://spcode.ddns.net/api-behavioriq` (configurable en `AppEnvironmentConfig.faceAuthBaseUrl`).  
Si el backend expone liveness en otro host (ej. `https://faceauth.ddns.net/api`), debe documentarse y, si aplica, añadirse una URL específica para liveness en config.

---

## 2. Problemas observados

| Síntoma | Posible causa | Acción en el plan |
|--------|----------------|-------------------|
| No se llega al Paso 4 (Liveness-check) | Cámara se cierra o falla entre captura 1 y 2; bytes inválidos o vacíos | Validar bytes antes de llamar liveness; mensaje claro de error si faltan imágenes |
| Errores `CameraDevice`, `BufferQueue abandoned` en log | Dispositivo/Driver cámara al hacer segunda captura en la misma sesión | Pequeña pausa entre takePicture 1 y 2; no hacer dispose hasta tener ambas fotos; capturar excepciones y mostrar "Reintentar" |
| API responde "Todos los archivos deben ser imágenes" | Content-Type o formato multipart incorrecto | Enviar partes con `Content-Type: image/jpeg` y nombres de archivo `.jpg` (ya implementado; verificar que los bytes sean JPEG válidos) |
| Usuario no pasa liveness | Falta de movimiento entre las dos capturas | Mostrar instrucción: "Gire un poco a la derecha o izquierda" antes/entre capturas |

---

## 3. Contrato API (Pasos 4 y 5)

### 3.1 Paso 4 — Liveness-check (prueba de vida)

| Elemento | Especificación |
|----------|-----------------|
| **URL** | `POST {API_BASE_URL}/embed/liveness-check` (ej. `https://spcode.ddns.net/api-behavioriq/embed/liveness-check` o la que defina el backend). |
| **Headers** | `Authorization: Bearer {token}`, `Accept: application/json`. El body es multipart; no enviar `Content-Type` en el request (el cliente lo fija con el boundary). |
| **Body** | `multipart/form-data` con **dos archivos**, mismo nombre de campo **`files`**: |
| | Parte 1: primera captura, p. ej. `filename: capture_0.jpg`, `Content-Type: image/jpeg`. |
| | Parte 2: segunda captura, p. ej. `filename: capture_1.jpg`, `Content-Type: image/jpeg`. |
| **Respuesta 2xx** | JSON: `{ "passed": boolean, "reason": string, "score"?: number }`. |
| **Lógica** | Si `passed === false` → mostrar `reason` al usuario, ofrecer **Reintentar** (volver a pantalla de doble captura) y **no** ejecutar pasos 5 ni 6. Si `passed === true` → continuar al Paso 5. |

### 3.2 Paso 5 — Embed (extraer embedding 512D, InsightFace ArcFace)

| Elemento | Especificación |
|----------|-----------------|
| **URL** | `POST {API_BASE_URL}/embed` (ej. `https://spcode.ddns.net/api-behavioriq/embed`). |
| **Headers** | `Authorization: Bearer {token}`, `Accept: application/json`. |
| **Body** | `multipart/form-data` con **un solo archivo**, campo **`file`** (singular), usando la **segunda captura**. Ej. `filename: capture.jpg`, `Content-Type: image/jpeg`. |
| **Respuesta 2xx** | JSON: `{ "embedding": [ 512 números ] }`. Arreglo **embedding 512D (InsightFace ArcFace)**. Ese mismo arreglo se envía en el Paso 6 en el body de validateFace. |

---

## 4. Instrucción al usuario para la prueba de vida

Para que el usuario **pase la prueba de vida** (liveness), el backend suele esperar un **ligero movimiento** entre la primera y la segunda captura (p. ej. girar un poco la cabeza).

- **Texto sugerido:** *"Para la prueba de vida, gire un poco la cabeza a la derecha o a la izquierda antes de la segunda captura."*
- **Dónde mostrarlo:**
  1. **Opción A (recomendada):** En la misma pantalla de doble captura, en el mensaje que se muestra entre captura 1 y captura 2. Sustituir o complementar el texto actual *"Mantenga la posición, segunda captura en 2 segundos…"* por algo como: *"Gire un poco a la derecha o izquierda. Segunda captura en 2 segundos…"*.
  2. **Opción B:** Texto fijo debajo del óvalo (o en la parte superior) durante las dos capturas: *"Gire ligeramente a la derecha o izquierda entre la primera y la segunda foto."*
- Así el usuario sabe que debe hacer un pequeño movimiento para que liveness pase y se continúe al Paso 5.

---

## 5. Tareas de implementación

### 5.1 Validación de imágenes antes del Paso 4

- [ ] En **FaceAuthFlowPage** (o en **FaceAuthService**), antes de llamar a `livenessCheck`, comprobar que `capture1` y `capture2` no sean null y que su longitud sea > 0 (p. ej. > 100 bytes).
- [ ] Si alguna imagen falta o está vacía: no llamar al API; mostrar mensaje *"No se pudieron obtener las dos capturas. Por favor, intente de nuevo."* y ofrecer **Reintentar** (volver a abrir la pantalla de doble captura). Así se evita enviar datos inválidos y se da feedback claro.

### 5.2 Robustez de la doble captura (cámara)

- [ ] En **FaceAuthCapturePage**, en el flujo `twoCaptures`: si `takePicture()` o `readAsBytes()` fallan en la **segunda** captura, capturar la excepción, no hacer pop con lista incompleta; mostrar en pantalla un mensaje de error y un botón **Reintentar** que reinicie el countdown y vuelva a hacer captura 1 y 2.
- [ ] Opcional: entre la primera y la segunda captura, añadir una **pequeña pausa** (p. ej. 200–500 ms) antes de llamar de nuevo a `takePicture()` para la segunda foto, para dar tiempo al dispositivo a estabilizar (puede reducir errores tipo `BufferQueue abandoned` en algunos dispositivos).
- [ ] Mantener la cámara abierta hasta tener ambas fotos; no hacer `dispose` del controller hasta después de haber leído los bytes de la segunda imagen.

### 5.3 Instrucción "Gire a la derecha o izquierda"

- [ ] En **FaceAuthCapturePage**, cuando `twoCaptures` es true y se muestra el overlay entre la primera y la segunda captura (`_waitingForSecondCapture`), actualizar el texto a algo como:
  - *"Gire un poco la cabeza a la derecha o izquierda. Segunda captura en 2 segundos…"*
- [ ] Opcional: añadir una línea adicional debajo del subtítulo de la pantalla (solo en modo `twoCaptures`): *"Para la prueba de vida, mueva ligeramente la cabeza entre las dos fotos."*

### 5.4 Reintentar cuando liveness no pasa

- [ ] En **FaceAuthFlowPage**, cuando el Paso 4 devuelve `passed === false` (o el API lanza con `reason`): mostrar el mensaje (`reason` o genérico) y un botón **Reintentar** que vuelva a abrir la pantalla de doble captura (misma pantalla con `twoCaptures: true`), sin cerrar el flujo ni perder el token/idCliente. Tras nuevas capturas, volver a llamar a liveness-check.
- [ ] Asegurar que el **finally** que pone `_isValidating = false` se ejecute siempre para no dejar un loading infinito.

### 5.5 Verificación del Paso 5 (Embed)

- [ ] Confirmar que **FaceAuthRemoteDatasource.embed** usa:
  - URL: `POST {faceAuthBaseUrl}/embed`
  - Campo del archivo: **`file`** (singular)
  - Archivo: segunda captura (misma que la segunda enviada en liveness), `filename: capture.jpg`, `Content-Type: image/jpeg`
- [ ] El Paso 5 ya está implementado; solo verificar que la **segunda captura** (bytes) que se pasa a `embed` sea exactamente la misma que la segunda enviada en `livenessCheck` (hoy el servicio hace liveness con c1 y c2, y embed con c2; correcto).

### 5.6 Base URL y errores de red

- [ ] Si el backend usa **distintas bases** para liveness (ej. `faceauth.ddns.net`) y el resto (ej. `spcode.ddns.net/api-behavioriq`), añadir en config una variable opcional `faceAuthLivenessBaseUrl` y usarla solo en la llamada a `embed/liveness-check`; si no está definida, usar `faceAuthBaseUrl` para todo.
- [ ] Ante 4xx/5xx en liveness o embed: mapear a `AuthException`/`NetworkException`, mostrar mensaje al usuario y dejar **Reintentar** disponible para liveness.

---

## 6. Resumen de cambios por archivo

| Archivo | Cambios |
|---------|--------|
| **FaceAuthCapturePage** | Texto del overlay entre capturas: "Gire un poco la cabeza a la derecha o izquierda. Segunda captura en 2 segundos…". Opcional: manejo de error en segunda captura + Reintentar. |
| **FaceAuthFlowPage** | Validar que capture1 y capture2 tengan bytes antes de llamar liveness. Si liveness `passed === false`, mostrar `reason` y botón Reintentar (volver a doble captura). Asegurar `finally` para `_isValidating = false`. |
| **FaceAuthRemoteDatasource** | Ya envía Content-Type image/jpeg y campo `files`/`file`. Verificar que no se altere el orden de las partes (primera y segunda captura). |
| **Config** | Opcional: `faceAuthLivenessBaseUrl` si el backend usa otro host para liveness. |

---

## 7. Flujo esperado tras el plan

1. Login interno → token e idCliente.
2. Pantalla única de doble captura: countdown → captura 1 → mensaje *"Gire un poco la cabeza a la derecha o izquierda. Segunda captura en 2 segundos…"* → 2 s → captura 2 → pop con [bytes1, bytes2].
3. Validar que bytes1 y bytes2 existan y tengan tamaño > 0; si no, mensaje y Reintentar.
4. **Paso 4:** POST `/embed/liveness-check` con las dos imágenes (campo `files`, Content-Type image/jpeg). Si `passed === false` → mostrar `reason` y Reintentar (volver al paso 2). Si `passed === true` → continuar.
5. **Paso 5:** POST `/embed` con la segunda imagen (campo `file`) → obtener `embedding` [512] (InsightFace ArcFace).
6. **Paso 6:** POST `/auth/validateFace/{idCliente}` con body `{ "embeddings": [ n1, n2, ..., n512 ] }` (el arreglo 512D directo); en éxito, guardar sesión y navegar a Home.

---

## 8. Contrato Paso 6 (validateFace) — Body del request

El servicio `/auth/validateFace/{idCliente}` espera en el body el **mismo arreglo 512D** devuelto por `/embed`, bajo la clave **`embeddings`** (array directo de 512 números, no array de arrays):

```json
{
  "embeddings": [ -1.22, -0.33, 1.19, ... (512 números) ... ]
}
```

Implementación actual: `jsonEncode({'embeddings': embedding})` con `embedding` de longitud 512; si no tiene 512 elementos se lanza `NetworkException` antes de enviar.

---

## 9. Relación con otros documentos

- **06-plan-face-auth-api-rest.md:** Define el flujo completo de 6 pasos y el contrato de todos los endpoints; este plan (07) profundiza en Pasos 4 y 5 y en la UX de liveness.
- **08-plan-paso-3-4-capturas-y-liveness.md:** Mensajes exactos del Paso 3 y pantallas del Paso 4 (Validando, reintento, 404).
- **Swagger:** [API BehaviorIQ](https://spcode.ddns.net/api-behavioriq/docs#/) — paths `embed/liveness-check` y `embed`.
