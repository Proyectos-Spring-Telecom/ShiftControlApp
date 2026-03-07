# Plan de implementación: Identificación de vehículo por placa (Apertura y Cierre de Turno)

## 1. Objetivo

En las interfaces de **Apertura de Turno** e **Inicio de Turno (Cierre de Turno)**, actualizar la opción **Seleccionar Vehículo**: dejar de usar escaneo de código QR y en su lugar identificar el vehículo mediante **fotografía o imagen de la placa**. En Cierre de Turno esta opción aparece debajo de la **Foto de resguardo**; en Apertura, en el mismo bloque de selectores.

---

## 2. Estado actual

| Elemento | Ubicación | Comportamiento actual |
|----------|-----------|------------------------|
| Pantalla Cierre de Turno | `lib/presentation/turnos/inicio_turno/inicio_turno_page.dart` | `ChecklistType.cierre`: muestra Foto de resguardo y luego bloque "Seleccionar Vehículo" + Operador. |
| Acción "Seleccionar Vehículo" | `_abrirEscanerVehiculo()` en `inicio_turno_page.dart` | Abre `EscanearVehiculoPage` (escáner QR en tiempo real). |
| Escáner QR | `lib/presentation/turnos/escanear_vehiculo/escanear_vehiculo_page.dart` | Usa `mobile_scanner`; al detectar código llama `onVehiculoEscaneado(vehiculoId)` con el valor del QR. |
| Selector visual | `_VehiculoSelector` en `inicio_turno_page.dart` | Muestra "Escanear código QR del vehículo" o el `vehiculoId` seleccionado; icono `qr_code_scanner`. |

El resultado del flujo actual es un `vehiculoId` (String) que se guarda en `_vehiculoSeleccionado` y se muestra en el mismo selector.

---

## 3. Alcance del cambio

- **Apertura de Turno e Inicio de Turno (Cierre de Turno):** la nueva identificación por placa (foto/imagen) aplica en **ambas** interfaces. Se elimina el escaneo QR en Apertura y en Cierre.
- **Contrato existente:** seguir devolviendo un identificador de vehículo (String) para que el resto del flujo (Operador, Continuar → CapturaOdometroPage, etc.) no cambie.

---

## 4. Flujo objetivo (Apertura y Cierre de Turno)

1. Usuario toca **Seleccionar Vehículo** (en Apertura: en el bloque de selectores; en Cierre: debajo de Foto de resguardo).
2. Se abre una pantalla / bottom sheet **“Capturar placa”** (o “Identificar vehículo por placa”).
3. Usuario **toma una foto** de la placa o **selecciona una imagen** de la galería.
4. Se muestra **vista previa** de la imagen y un botón tipo **“Identificar vehículo”**.
5. La app **procesa la imagen** (OCR en dispositivo y/o envío a backend) y obtiene la **placa** y/o el **identificador de vehículo**.
6. Se cierra la pantalla y se actualiza el selector con el vehículo identificado (igual que hoy con el QR: `_vehiculoSeleccionado = resultado`).

---

## 5. Opciones de reconocimiento de placa

| Opción | Descripción | Pros | Contras |
|--------|-------------|------|---------|
| **A) OCR en dispositivo** | Usar ML Kit (o similar) para extraer texto de la imagen y post-procesar para obtener la placa. | Sin backend obligatorio, funciona offline. | Requiere lógica de limpieza/formato de placa; puede fallar con fotos mal encuadradas. |
| **B) API backend** | Enviar la imagen al servidor; el servidor devuelve placa y/o `vehiculoId`. | Lógica centralizada, posible validación contra flota. | Requiere endpoint y posible almacenamiento de imagen. |
| **C) Híbrido** | OCR en dispositivo para pre-llenar; opcionalmente validar con backend. | Mejor UX y posibilidad de validación. | Más desarrollo. |

**Recomendación:** Definir con backend si existirá o existirá un endpoint de reconocimiento de placa. Si sí → priorizar **B** o **C**. Si no → **A** con OCR en dispositivo (p. ej. `google_mlkit_text_recognition`) y reglas simples de formato de placa.

---

## 6. Tareas de implementación

### 6.1 UI y flujo en Apertura y Cierre de Turno

- **Archivo:** `lib/presentation/turnos/inicio_turno/inicio_turno_page.dart`
- **Cambios:**
  - En **Apertura y Cierre de Turno**, al tocar **Seleccionar Vehículo** abrir siempre la nueva pantalla o bottom sheet de **captura de placa** (por imagen/foto). Dejar de usar `EscanearVehiculoPage` (QR) en ambos flujos.
  - El callback de la nueva pantalla debe ser equivalente a `onVehiculoEscaneado(String vehiculoId)` para no romper el resto del flujo (mismo tipo de dato: identificador de vehículo).
- **Texto e icono del selector (Apertura y Cierre):**
  - Placeholder: p. ej. **“Tomar foto de la placa del vehículo”** (o “Identificar vehículo por placa”).
  - Icono: cambiar de `qr_code_scanner` a uno acorde (p. ej. `badge` / `confirmation_number` / `camera`). El icono de cámara a la derecha puede mantenerse.

### 6.2 Nueva pantalla / flujo “Capturar placa”

- **Ruta sugerida:** `lib/presentation/turnos/identificar_placa/` (o `capturar_placa/`).
- **Contenido mínimo:**
  - Título: “Identificar vehículo por placa” (o similar).
  - Botón **“Tomar foto”** (cámara) y opción **“Elegir imagen”** (galería) usando `image_picker` (ya usado en el proyecto).
  - Tras elegir imagen: **vista previa** (p. ej. `Image.memory` con `Uint8List` para compatibilidad web).
  - Botón **“Identificar vehículo”** que envíe la imagen al proceso elegido (OCR y/o API).
  - Indicador de carga mientras se procesa.
  - En éxito: callback con `String` (placa o `vehiculoId`) y `Navigator.pop`.
  - En error: mensaje con `AppAlertBanner` (o similar) y opción de reintentar / cambiar imagen.
  - Opción **“Ingresar manualmente”** o **“Regresar”** que llame al mismo callback que hoy usa “Ingresar manualmente” en el escáner QR (cerrar sin resultado o con valor manual si se implementa).

### 6.3 Lógica de reconocimiento

- **Si se usa OCR en dispositivo:**
  - Añadir dependencia (p. ej. `google_mlkit_text_recognition`).
  - Tras obtener texto, aplicar reglas o regex para extraer la placa (formato mexicano u otro según definición).
  - Decidir si la placa es directamente el `vehiculoId` o si se necesita un paso extra (ej. búsqueda por placa en backend) para obtener el `vehiculoId`. Si la app hoy solo muestra el valor y no lo envía a un API de turnos, se puede usar la placa como identificador mostrado.
- **Si se usa API backend:**
  - Definir endpoint (ej. `POST /api/vehiculos/identificar-por-placa` con `multipart` de la imagen).
  - Respuesta esperada: `{ "placa": "...", "vehiculoId": "..." }` o similar.
  - Crear capa de datos (datasource/repository) para esta llamada y llamarla desde la pantalla de captura de placa; manejo de errores con `AppAlertBanner`.

### 6.4 Integración en InicioTurnoPage

- Añadir método p. ej. `_abrirIdentificarPlaca()` que:
  - Navegue a la nueva pantalla de captura de placa.
  - Reciba en callback el `vehiculoId` (o placa si se usa como id).
  - Haga `setState(() => _vehiculoSeleccionado = vehiculoId)` y cierre la pantalla.
- En `_buildSelectores`, para **Apertura y Cierre**:
  - El `onTap` del selector de vehículo debe llamar siempre a `_abrirIdentificarPlaca()` (sustituir la llamada a `_abrirEscanerVehiculo()`).
- Ajustar texto e icono del `_VehiculoSelector` para ambos tipos de turno (placeholder e icono de placa en lugar de QR).

### 6.5 Pruebas y validación

- Probar **Apertura de Turno:** Seleccionar vehículo → captura de imagen de placa → identificar → verificar que el selector muestre el resultado y que “Continuar” siga funcionando.
- Probar **Cierre de Turno:** flujo Foto de resguardo → Seleccionar vehículo → captura de imagen de placa → identificar → verificar que el selector muestre el resultado y que “Continuar” siga funcionando.
- Probar en **web** si la pantalla de placa estará disponible (cámara/galería y `Image.memory` ya usados en el proyecto).

---

## 7. Resumen de archivos a tocar / crear

| Acción | Archivo / carpeta |
|--------|--------------------|
| Modificar | `lib/presentation/turnos/inicio_turno/inicio_turno_page.dart` (usar siempre flujo placa en Apertura y Cierre, callback placa, textos/iconos del selector) |
| Crear | `lib/presentation/turnos/identificar_placa/` (pantalla de captura de imagen + vista previa + botón “Identificar”) |
| Opcional (OCR) | Dependencia `google_mlkit_text_recognition` (o similar) y utilidad de extracción de placa |
| Opcional (API) | Datasource/Repository + endpoint para reconocimiento de placa en backend |

---

## 8. Orden sugerido de implementación

1. Crear la pantalla de **captura de imagen de placa** (cámara + galería + vista previa + botón “Identificar” con lógica temporal que devuelva un valor fijo o la placa en texto manual).
2. En **InicioTurnoPage**, para **Apertura y Cierre de Turno**, enlazar **Seleccionar Vehículo** a esta nueva pantalla (sustituir `_abrirEscanerVehiculo`) y actualizar texto/icono del selector en ambos flujos.
3. Implementar la **lógica real** de reconocimiento (OCR y/o API) y conectar con el callback que ya devuelve un `String` (vehiculoId/placa).
4. Añadir manejo de errores y opción “Ingresar manualmente” / “Regresar” según diseño acordado.

Con esto, las interfaces de Apertura y Cierre de Turno quedan actualizadas para identificar el vehículo por fotografía de la placa en lugar de QR, manteniendo el contrato actual del flujo (un `String` como vehículo seleccionado).
