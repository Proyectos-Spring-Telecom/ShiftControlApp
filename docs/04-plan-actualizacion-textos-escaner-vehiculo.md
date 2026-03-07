# Plan de implementación: Actualización de textos – Escáner Vehículo (placa)

## 1. Objetivo

Actualizar la interfaz de **Escáner Vehículo** para que los textos reflejen identificación por **placa** en lugar de código QR, tanto en **Apertura de Turno** como en **Cierre de Turno**.

**Textos objetivo:**

| Actual (o equivalente) | Nuevo |
|------------------------|--------|
| Escanea el código QR | **Escanea la placa del vehículo** |
| Coloca el código del vehículo dentro del marco. | **Coloca la placa del vehículo dentro del marco.** |

---

## 2. Alcance

- **Flujos:** Apertura de Turno e Inicio de Turno (Cierre de Turno). En ambos, la opción **Seleccionar Vehículo** abre la pantalla de identificación por placa.
- **Pantallas afectadas:**
  1. **IdentificarPlacaPage** – Pantalla actualmente usada en Apertura y Cierre para capturar/identificar la placa (foto, galería, vista previa). Es la que el usuario ve al tocar “Tomar foto de la placa del vehículo”.
  2. **EscanearVehiculoPage** (opcional) – Pantalla de escáner QR; si se mantiene en el proyecto o se usa en otra ruta, conviene alinear sus textos a “placa” para consistencia de mensajería.

---

## 3. Estado actual

| Ubicación | Textos actuales |
|-----------|-----------------|
| **IdentificarPlacaPage** (`lib/presentation/turnos/identificar_placa/identificar_placa_page.dart`) | Título: “Identificar vehículo por placa”. Instrucción: “Toma una foto de la placa o selecciona una imagen”. Subtexto: “Asegúrate de que la placa sea legible. Puedes ingresar la placa manualmente si lo prefieres.” |
| **EscanearVehiculoPage** (`lib/presentation/turnos/escanear_vehiculo/escanear_vehiculo_page.dart`) | “Escanea el Código QR”, “Coloca el código del vehículo dentro del marco.”, “Alinea el código dentro del cuadro para identificar la unidad automáticamente”. |

---

## 4. Textos objetivo (copiar/pegar)

- **Título principal de instrucción:**  
  `Escanea la placa del vehículo`

- **Instrucción secundaria (marco):**  
  `Coloca la placa del vehículo dentro del marco.`

Opcional para pantallas con más contexto:
- **Refuerzo:**  
  `Alinea la placa dentro del cuadro para identificar la unidad automáticamente.`

---

## 5. Tareas de implementación

### 5.1 IdentificarPlacaPage (Apertura y Cierre)

- **Archivo:** `lib/presentation/turnos/identificar_placa/identificar_placa_page.dart`
- **Cambios:**
  1. Sustituir el **título de sección / instrucción principal** por: **“Escanea la placa del vehículo”** (p. ej. el `Text` que hoy dice “Toma una foto de la placa o selecciona una imagen” o el que se use como instrucción principal).
  2. Sustituir o añadir el **texto secundario** por: **“Coloca la placa del vehículo dentro del marco.”**
  3. Opcional: mantener un tercer texto de refuerzo (“Asegúrate de que la placa sea legible…” o el de “Alinea la placa…”) según diseño.
- **Criterio de aceptación:** En Apertura y en Cierre, al abrir “Seleccionar Vehículo” y llegar a la pantalla de placa, se muestran “Escanea la placa del vehículo” y “Coloca la placa del vehículo dentro del marco.” en los lugares acordados.

### 5.2 EscanearVehiculoPage (opcional / consistencia)

- **Archivo:** `lib/presentation/turnos/escanear_vehiculo/escanear_vehiculo_page.dart`
- **Cambios (si la pantalla sigue en uso o se quiere unificar mensajes):**
  1. Reemplazar **“Escanea el Código QR”** por **“Escanea la placa del vehículo”**.
  2. Reemplazar **“Coloca el código del vehículo dentro del marco.”** por **“Coloca la placa del vehículo dentro del marco.”**
  3. Reemplazar **“Alinea el código dentro del cuadro…”** por **“Alinea la placa dentro del cuadro para identificar la unidad automáticamente.”** (o variante equivalente).
- **Nota:** Si en el futuro esta pantalla deja de usarse y solo se usa IdentificarPlacaPage, estos cambios son opcionales pero recomendables si la pantalla sigue accesible.

### 5.3 Verificación

- Probar en **Apertura de Turno**: ir a Inicio de Turno (Apertura) → Seleccionar Vehículo → comprobar que la pantalla de placa muestre los nuevos textos.
- Probar en **Cierre de Turno**: ir a Inicio de Turno (Cierre) → Seleccionar Vehículo → comprobar los mismos textos.

---

## 6. Resumen de archivos

| Archivo | Acción |
|---------|--------|
| `lib/presentation/turnos/identificar_placa/identificar_placa_page.dart` | Actualizar instrucción principal y secundaria a “Escanea la placa del vehículo” y “Coloca la placa del vehículo dentro del marco.” |
| `lib/presentation/turnos/escanear_vehiculo/escanear_vehiculo_page.dart` | (Opcional) Sustituir textos de QR por textos de placa. |

---

## 7. Relación con otros planes

- Este plan complementa **[03-plan-identificacion-vehiculo-por-placa.md](03-plan-identificacion-vehiculo-por-placa.md)**: allí se definió el flujo por foto/placa y la pantalla IdentificarPlacaPage; aquí se definen los **textos concretos** de la interfaz “Escáner Vehículo” para Apertura y Cierre.
