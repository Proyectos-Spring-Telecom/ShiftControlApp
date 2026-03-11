# Plan de implementación: GET /placas/validar (BehaviorIQ)

## 1. Objetivo

Integrar el servicio **GET /placas/validar** del API BehaviorIQ en la interfaz **Inicio de Turno** para comprobar si un número de placa está registrado en el contexto del usuario. El número de placa se obtiene del flujo de captura (POST /plate/read); los parámetros de contexto (idCliente, idSolucion) provienen de GET /auth/me.

**Base URL:** `https://spcode.ddns.net/api-behavioriq` (`AppEnvironmentConfig.faceAuthBaseUrl`).

**URL del servicio:** `https://spcode.ddns.net/api-behavioriq/placas/validar`

---

## 2. Contrato del servicio

### 2.1 Request

| Elemento | Especificación |
|----------|----------------|
| **Método** | GET |
| **URL** | `GET {API_BASE_URL}/placas/validar` con query params. |
| **Headers** | `Accept: application/json`, `Authorization: Bearer {token}` |

**Parámetros de consulta (query):**

| Parámetro    | Obligatorio | Tipo   | Descripción                          |
|-------------|-------------|--------|--------------------------------------|
| numeroPlaca | Sí          | string | Número de placa a validar.           |
| idCliente   | No          | number | ID del cliente (contexto del usuario). |
| idSolucion  | No          | number | ID de la solución (contexto del usuario). |
| latitud     | No          | number | Latitud (opcional).                  |
| longitud    | No          | number | Longitud (opcional).                 |

**Ejemplo cURL:**
```bash
curl -X 'GET' \
  'https://spcode.ddns.net/api-behavioriq/placas/validar?numeroPlaca=12G-270&idCliente=2&idSolucion=2' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer {token}'
```

### 2.2 Respuesta 200

| Código | Significado |
|--------|-------------|
| **200** | Respuesta con datos de la placa (registrada o no). |

**Response body (200):**
```json
{
  "registered": true,
  "idPlaca": 3,
  "placa": "12G-270",
  "marca": "BYD",
  "modelo": "King",
  "anio": 2025,
  "color": "Negro",
  "economico": "101"
}
```

| Campo      | Tipo    | Descripción                                      |
|-----------|---------|--------------------------------------------------|
| registered| boolean | Si la placa está registrada en el contexto.      |
| idPlaca   | number  | ID de la placa (cuando está registrada).         |
| placa     | string  | Número de placa.                                 |
| marca     | string  | Marca del vehículo (opcional).                   |
| modelo    | string  | Modelo del vehículo (opcional).                  |
| anio      | number  | Año (opcional).                                  |
| color     | string  | Color (opcional).                                |
| economico | string  | Número económico (opcional).                     |

---

## 3. Origen de los datos en la app

| Parámetro   | Origen en la app |
|-------------|-------------------|
| **numeroPlaca** | Resultado de **POST /plate/read** (`plate_number`). En Inicio de Turno se obtiene cuando el usuario identifica la placa en `IdentificarPlacaPage` y se guarda en el estado (ej. `_vehiculoSeleccionado`). |
| **idCliente**   | Resultado de **GET /auth/me** (`idCliente`). Debe estar disponible en el contexto del usuario (sesión/estado tras login BehaviorIQ o tras ejecutar /auth/me). |
| **idSolucion**  | Resultado de **GET /auth/me** (`idSolucion`). Mismo contexto que idCliente. |
| **latitud / longitud** | Opcionales; se pueden omitir o tomar de geolocalización si se desea. |

---

## 4. Flujo en la app

### 4.1 Pantalla

- **Inicio de Turno** (`lib/presentation/turnos/inicio_turno/inicio_turno_page.dart`).
- El usuario ya tiene flujo: **Seleccionar vehículo** → abre `IdentificarPlacaPage` → captura y POST /plate/read → vuelve con `plate_number` en el selector (estado `_vehiculoSeleccionado`).

### 4.2 Momento de ejecución

- **GET /placas/validar** se ejecutará en Inicio de Turno cuando:
  - Se disponga de un **numeroPlaca** (p. ej. tras elegir/identificar vehículo con /plate/read), y
  - Se disponga de **token** y de **idCliente** e **idSolucion** (de /auth/me).
- Opciones de disparo:
  - **A)** Al volver de `IdentificarPlacaPage` con una placa (callback `onPlacaIdentificada`): tras asignar `_vehiculoSeleccionado`, llamar a /placas/validar con ese número, idCliente e idSolucion.
  - **B)** Al pulsar un botón tipo “Validar placa” o “Continuar” que use la placa seleccionada y llame al servicio.

### 4.3 Uso del resultado (implementado)

- El resultado se guarda en el **provider global** `placaValidadaProvider` (`StateProvider<PlacasValidarResult?>`), ubicado en `lib/presentation/turnos/placa_validada_provider.dart`. Cualquier pantalla puede leerlo con `ref.watch(placaValidadaProvider)` o `ref.read(placaValidadaProvider)`.
- **Inicio de Turno:** Si **registered === true**, el header muestra: placa, marca y modelo (debajo), etiqueta "Año" con el valor de `anio`, y una etiqueta gris con el económico precedido de `#` (ej. `#101`). Si no hay placa validada, se muestra "Folio: Pendiente". Al identificar una nueva placa (callback `onPlacaIdentificada`) se limpia el provider antes de validar de nuevo.
- **Apertura de Turno (Captura de odómetro):** La tarjeta del vehículo se construye dentro de un `Consumer` que hace `ref.watch(placaValidadaProvider)`. Si hay resultado con **registered === true**, se muestran: placa (pill), marca y modelo, "Año" con `anio`, y pill gris con `#economico`. Si no hay datos en el provider, se usan parámetros opcionales del widget o valores por defecto. La pantalla funciona tanto al llegar desde Inicio de Turno (Continuar) como al abrir por ruta (ej. `/captura-odometro`).
- Si **registered === false**: se muestra banner informativo "Placa no registrada" y el provider conserva el resultado; las pantallas que lean el provider pueden decidir no mostrar datos de vehículo.
---

## 5. Token y contexto (idCliente, idSolucion)

- **Token:** El mismo que se usa para /plate/read (p. ej. `AuthLocalDatasource.getStoredToken()`), asumiendo que el backend de turnos y BehaviorIQ comparten o aceptan el mismo Bearer.
- **idCliente e idSolucion:** Deben provenir de **GET /auth/me**. Opciones:
  - Si el usuario inicia sesión por **Face Auth** (BehaviorIQ), ya se obtienen en `FaceAuthCredentialsResult` (idCliente, idSolucion) y se pueden guardar en sesión o en un provider al establecer la sesión.
  - Si el usuario inicia sesión solo por el login principal (correo/contraseña), valorar llamar a **GET /auth/me** con el token actual al entrar a Inicio de Turno (o al iniciar la app) y guardar idCliente/idSolucion para usarlos en /placas/validar y otros servicios BehaviorIQ.

---

## 6. Tareas de implementación

### 6.1 Capa de datos

- **Nuevo datasource o método:** Cliente para **GET /placas/validar**.
  - **Ubicación sugerida:** `lib/data/datasources/remote/placas_validar_remote_datasource.dart` (o extender un cliente existente de BehaviorIQ si ya se centraliza ahí).
  - **Firma sugerida:**  
    `Future<PlacasValidarResult> validar(String token, String numeroPlaca, {int? idCliente, int? idSolucion, double? latitud, double? longitud});`
  - **Resultado tipado:** Por ejemplo `PlacasValidarResult(registered: bool, idPlaca: int?, placa: String?, marca: String?, modelo: String?, anio: int?, color: String?, economico: String?)` mapeando el JSON de respuesta.
  - **Request:** GET con query params `numeroPlaca` (obligatorio), `idCliente`, `idSolucion`, `latitud`, `longitud` (opcionales). Headers: `Accept: application/json`, `Authorization: Bearer $token`.
  - Manejar 4xx/5xx y parsear mensaje de error si el API lo devuelve.

### 6.2 Proveedor y acceso a idCliente / idSolucion

- Exponer el datasource vía **Riverpod** (ej. `placasValidarDatasourceProvider`).
- Asegurar que **idCliente** e **idSolucion** estén disponibles donde se llame a /placas/validar (estado global, provider con datos de /auth/me, o parámetros pasados desde quien tenga ese contexto).

### 6.3 Integración en Inicio de Turno

- En **Inicio de Turno**, cuando se disponga de **numeroPlaca** (p. ej. `_vehiculoSeleccionado` tras /plate/read) y de idCliente/idSolucion y token:
  - Llamar a **validar(token, numeroPlaca, idCliente: idCliente, idSolucion: idSolucion)**.
  - Según `registered`: actualizar UI (mensaje de éxito, datos del vehículo, o aviso “placa no registrada”) y habilitar o no el avance del flujo según reglas de negocio.
- Mostrar estado de carga y manejar errores de red o API.

### 6.4 Documentación

- Dejar documentado en este plan el contrato (URL, params, response) y la dependencia con /plate/read y /auth/me.

---

## 7. Resumen de archivos (estado implementado)

| Archivo | Estado |
|---------|--------|
| `lib/data/datasources/remote/placas_validar_remote_datasource.dart` | **Implementado:** GET /placas/validar, query params, parseo 200, modelo PlacasValidarResult. |
| `lib/presentation/controllers/auth_controller.dart` | **Implementado:** `placasValidarRemoteDatasourceProvider` (PlacasValidarRemoteDatasourceImpl). |
| `lib/presentation/turnos/placa_validada_provider.dart` | **Implementado:** `placaValidadaProvider` (StateProvider<PlacasValidarResult?>). Estado global para uso en Inicio de Turno, Apertura de Turno y otras interfaces. |
| `lib/presentation/turnos/inicio_turno/inicio_turno_page.dart` | **Implementado:** Tras onPlacaIdentificada se llama /placas/validar (con token e idCliente/idSolucion de /auth/me); resultado se escribe en placaValidadaProvider; header muestra placa, marca/modelo, año y #economico cuando registered === true; al identificar nueva placa se limpia el provider; Continuar navega a CapturaOdometroPage sin parámetros. |
| `lib/presentation/turnos/captura_odometro/captura_odometro_page.dart` | **Implementado:** StatefulWidget; la tarjeta del vehículo está dentro de un Consumer que hace ref.watch(placaValidadaProvider); muestra placa, marca/modelo, año y #economico cuando hay resultado registered === true; acepta también parámetros opcionales del widget como fallback. |
| `docs/01-contexto.md` | **Actualizado:** flujo validación placa y provider global en sección Turnos. |
| `docs/02-contratos-capas-modulos.md` | **Actualizado:** PlacasValidarRemoteDatasource, placaValidadaProvider, rutas Inicio/Apertura de Turno. |
| `docs/12-plan-api-placas-validar-integracion.md` | Este documento. |

---

## 8. Referencias

- **API BehaviorIQ:** `https://spcode.ddns.net/api-behavioriq`
- **Plate read:** POST /plate/read → `plate_number` (origen de **numeroPlaca**).
- **Auth me:** GET /auth/me → `idCliente`, `idSolucion` (origen de contexto del usuario).
