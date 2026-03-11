# Plan de implementación: Integración API REST POST /plate/read (lectura de placa)

## 1. Objetivo

Integrar el servicio **POST /plate/read** del API BehaviorIQ en el flujo **Inicio de Turno → Seleccionar Vehículo**. Cuando el usuario capture una imagen de la placa (cámara o galería), la app enviará la imagen al servicio; ante respuesta **200/201** se obtendrá `plate_number` y se mostrará en el input "Seleccionar vehículo".

**Referencia Swagger:** [spcode.ddns.net/api-behavioriq](https://arc.net/l/quote/xgodcfvb) (plate/read).

**Base URL del servicio:** `https://spcode.ddns.net/api-behavioriq` (misma que Face Auth: `AppEnvironmentConfig.faceAuthBaseUrl`).

---

## 2. Contrato del servicio

### 2.1 Request

| Elemento | Especificación |
|----------|----------------|
| **URL** | `POST {API_BASE_URL}/plate/read` → `https://spcode.ddns.net/api-behavioriq/plate/read` |
| **Headers** | `Accept: application/json`, `Authorization: Bearer {token}`, `Content-Type: multipart/form-data` (boundary automático). |
| **Body** | `multipart/form-data` con un único archivo: campo **`file`** (requerido), imagen de la placa (ej. `image/jpeg`). |

**Ejemplo cURL:**
```bash
curl -X 'POST' \
  'https://spcode.ddns.net/api-behavioriq/plate/read' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer {token}' \
  -H 'Content-Type: multipart/form-data' \
  -F 'file=@placa.jpg;type=image/jpeg'
```

### 2.2 Respuestas

| Código | Significado | Acción en la app |
|--------|-------------|------------------|
| **200** | Número de placa detectado. | Mostrar mensaje de éxito; usar `plate_number` en el input "Seleccionar vehículo". |
| **201** | Creado / placa detectada. | Igual que 200: éxito, mostrar `plate_number`. |
| **400** | No se detectó placa o parámetros inválidos. | Mostrar mensaje al usuario; permitir reintentar. |
| **404** | No se detectó placa en la imagen (`code: no_plate_found`). | Igual que 400: mensaje "No se detectó placa. Coloque la placa en el marco y toque Reintentar." |
| **403** | Servicio de placa no habilitado para esta solución. | Mostrar mensaje específico (ej. "Servicio de placa no disponible para esta cuenta."). |
| **503** | Servicio no disponible. | Mostrar "Servicio no disponible. Intente más tarde." y opción reintentar. |

### 2.3 Response body (éxito 200/201)

```json
{
  "plate_number": "12G-270",
  "confidence": 0.9998035457884702
}
```

- **plate_number** (string): número de placa detectado. Es el valor que debe mostrarse en el input "Seleccionar vehículo".
- **confidence** (number, opcional): nivel de confianza del reconocimiento; se puede usar para mostrar un aviso si es bajo (opcional).

---

## 3. Flujo en la app

### 3.1 Pantallas involucradas

| Pantalla | Archivo | Rol |
|----------|---------|-----|
| Inicio de Turno | `lib/presentation/turnos/inicio_turno/inicio_turno_page.dart` | Muestra el selector "Seleccionar Vehículo"; al tocar abre `IdentificarPlacaPage`. Recibe el resultado (placa) y lo muestra en el selector. |
| Identificar vehículo por placa | `lib/presentation/turnos/identificar_placa/identificar_placa_page.dart` | El usuario toma foto o elige imagen → vista previa + campo de placa manual. Al pulsar "Identificar vehículo" con imagen: llamar al API `/plate/read` → en éxito rellenar el input con `plate_number` y mostrar success; en error mostrar mensaje según código. |

### 3.2 Secuencia deseada

1. Usuario en **Inicio de Turno** toca **Seleccionar Vehículo**.
2. Se abre **IdentificarPlacaPage**.
3. Usuario **toma foto** de la placa o **elige imagen** de galería.
4. Se muestra **vista previa** y el campo de texto (placa manual).
5. Usuario toca **"Identificar vehículo"** (o se puede disparar la llamada al API automáticamente tras capturar la imagen; el plan asume botón explícito).
6. App envía la imagen con **POST /plate/read** (Bearer token).
7. **200/201:** Se recibe `plate_number` → se asigna al `TextEditingController` del input de placa (y se muestra mensaje de éxito). El usuario puede confirmar y cerrar; al cerrar con "Identificar" o "Confirmar", el valor (`plate_number`) se devuelve a Inicio de Turno y se muestra en "Seleccionar vehículo".
8. **400/403/503:** Se muestra el mensaje correspondiente (banner o SnackBar) y se permite reintentar o ingresar placa manualmente.

---

## 4. Token de autorización

- El servicio requiere **Authorization: Bearer {token}**.
- **Opción A:** Usar el token de la sesión actual de la app (`AuthLocalDatasource.getStoredToken()`). Si el backend de placa es el mismo que el login principal, este token sería el correcto.
- **Opción B:** Si `/plate/read` pertenece al mismo API BehaviorIQ que Face Auth y requiere el token obtenido en **login Face Auth** (auth/login de BehaviorIQ), habría que usar ese token cuando el usuario haya iniciado sesión por Face Auth; si no, podría usarse el token del login principal si el backend lo acepta.
- **Recomendación:** Implementar primero con el **token almacenado** de la app (`getStoredToken`). Si en pruebas el servicio responde 401, valorar uso de token BehaviorIQ (por ejemplo guardando el token de Face Auth cuando corresponda) o aclarar con backend qué token usar para `/plate/read`.

---

## 5. Tareas de implementación

### 5.1 Capa de datos: cliente del servicio plate/read

- **Crear** un datasource o servicio que llame a `POST /plate/read` con la imagen en multipart.
- **Ubicación sugerida:** `lib/data/datasources/remote/plate_read_remote_datasource.dart` (o extender un cliente existente de BehaviorIQ si ya se centraliza ahí).
- **Configuración:** Usar `AppEnvironmentConfig.faceAuthBaseUrl` como base (misma que BehaviorIQ) y path `plate/read`.
- **Firma sugerida:** `Future<PlateReadResult> readPlate(String token, List<int> imageBytes)`.
- **Resultado tipado:** Por ejemplo `PlateReadResult(plateNumber: String, confidence: double?)`; en error lanzar excepciones según código (400 → mensaje "No se detectó placa"; 403 → "Servicio no habilitado"; 503 → "Servicio no disponible"; 401 → AuthException).
- **Implementación:** Equivalente curl: `-H 'accept: application/json' -H 'Authorization: Bearer <token>' -H 'Content-Type: multipart/form-data' -F 'file=@placa.jpeg;type=image/jpeg'`. `http.MultipartRequest('POST', uri)`, headers Accept y Authorization, parte con nombre `file`, contenido `imageBytes`, `filename: 'placa.jpeg'`, `Content-Type: image/jpeg`. Bytes tal cual. Resolución captura: `ResolutionPreset.medium` (~480p). Enviar request, parsear JSON 200/201; 4xx/5xx excepción con mensaje.

### 5.2 Proveedor y acceso al token

- Exponer el datasource vía **Riverpod** (ej. `plateReadDatasourceProvider`).
- En la pantalla que llame al servicio, obtener el token con `ref.read(authLocalDatasourceProvider).getStoredToken()` (o el que proporcione el AuthController/local). Si el token es null, mostrar mensaje "Sesión expirada" y no llamar al API.

### 5.3 Cambios en IdentificarPlacaPage

- **Estado:** Mantener `_imageBytes`, `_placaController`, `_isLoading`; opcionalmente `_lastPlateReadError` para mostrar mensaje de error específico.
- **Al pulsar "Identificar vehículo":**
  - Si hay texto en `_placaController` (placa manual): comportamiento actual (devolver ese valor y cerrar o llamar callback).
  - Si hay `_imageBytes` y no placa manual (o se quiere priorizar API):
    - Poner `_isLoading = true`.
    - Obtener token; si null, mensaje de sesión y `_isLoading = false`.
    - Llamar al servicio `readPlate(token, _imageBytes!)`.
    - En éxito: asignar `_placaController.text = result.plateNumber`; mostrar SnackBar o banner de éxito; `_isLoading = false`. El usuario puede confirmar y cerrar; al cerrar, el valor del input (ya rellenado) se devuelve a Inicio de Turno.
    - En error 400: mensaje "No se detectó placa. Intente de nuevo o ingrese la placa manualmente."; `_isLoading = false`.
    - En error 403: mensaje "Servicio de placa no habilitado para esta solución."; `_isLoading = false`.
    - En error 503: mensaje "Servicio no disponible. Intente más tarde."; `_isLoading = false`.
    - En otros errores (red, 5xx): mensaje genérico y reintentar.
- **Eliminar** el TODO y el valor temporal "Placa (pendiente OCR)"; reemplazar por la llamada real al API.

### 5.4 Mostrar plate_number en "Seleccionar vehículo"

- El selector "Seleccionar Vehículo" en **Inicio de Turno** ya muestra `_vehiculoSeleccionado` (el String devuelto por `IdentificarPlacaPage`).
- Al cerrar `IdentificarPlacaPage` con éxito (con `Navigator.pop(plate_number)` o callback `onPlacaIdentificada(plate_number)`), ese valor se asigna a `_vehiculoSeleccionado` en `inicio_turno_page.dart`, por lo que **no requiere cambios adicionales** en esa pantalla; solo asegurar que el valor que se hace pop o se pasa al callback sea exactamente `plate_number` recibido del API.

### 5.5 Documentación y pruebas

- Añadir en este plan o en `02-contratos-capas-modulos.md` el contrato del datasource/servicio de plate/read (URL, body, códigos de respuesta).
- Probar con imagen real de placa (200/201), con imagen sin placa (400), y si es posible 403/503 para validar mensajes.

---

## 6. Resumen de archivos

| Archivo | Acción |
|---------|--------|
| `lib/config/app_environment.dart` | Sin cambios si se reutiliza `faceAuthBaseUrl` para plate/read. |
| `lib/data/datasources/remote/plate_read_remote_datasource.dart` | **Crear:** POST /plate/read, multipart file, parseo 200/201, excepciones 400/403/503. |
| `lib/presentation/controllers/auth_controller.dart` (o donde se definan providers) | **Añadir** provider del plate read datasource; el token se obtiene de AuthLocalDatasource. |
| `lib/presentation/turnos/identificar_placa/identificar_placa_page.dart` | **Modificar:** Integrar llamada al servicio en "Identificar vehículo" cuando hay imagen; rellenar input con `plate_number` en éxito; mostrar mensajes de error según código. |
| `lib/presentation/turnos/inicio_turno/inicio_turno_page.dart` | Sin cambios (ya recibe y muestra el String de placa en el selector). |

---

## 7. Referencias

- **Swagger / API:** [spcode.ddns.net/api-behavioriq](https://arc.net/l/quote/xgodcfvb) — endpoint `plate/read`.
- **Plan relacionado:** `03-plan-identificacion-vehiculo-por-placa.md` (identificación por placa en Apertura/Cierre de Turno).
- **Config base URL:** `AppEnvironmentConfig.faceAuthBaseUrl` = `https://spcode.ddns.net/api-behavioriq`.
