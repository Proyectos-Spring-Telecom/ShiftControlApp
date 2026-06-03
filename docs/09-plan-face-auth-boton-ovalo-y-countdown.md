# Plan de implementación: Botón "Reconocimiento facial", óvalo verde con efecto over y eliminación de cuenta regresiva

## 1. Objetivo

1. Cambiar el título del botón de **"Iniciar con FaceAuth"** a **"Reconocimiento facial"**.
2. Al hacer tap se abre la cámara; **rediseñar el óvalo** de encuadre con estilo **verde y efecto over** (referencia: botón verde con borde brillante y sensación de relieve/3D).
3. **Quitar la cuenta regresiva** "2… 1… Capturando…"; al entrar a la pantalla de captura el flujo debe ejecutarse sin mostrar números ni texto "Capturando…", manteniendo los tiempos y las dos capturas.

**Referencia visual:** Óvalo/button verde con borde verde brillante, relleno verde oscuro y efecto tipo “over” (borde con ligero relieve o realce).

---

## 2. Cambios por área

### 2.1 Título del botón (Login)

| Dónde | Actual | Nuevo |
|------|--------|--------|
| **LoginPage** | Texto del botón: `'Iniciar con FaceAuth'` | `'Reconocimiento facial'` |

**Archivo:** `lib/presentation/auth/login/login_page.dart`  
**Ubicación aproximada:** Widget que usa `_onFaceAuthTap` y `const Text('Iniciar con FaceAuth')` (aprox. línea 248). Sustituir por `const Text('Reconocimiento facial')`.

---

### 2.2 Diseño del óvalo (verde + efecto over)

El óvalo actual usa `FaceAuthColors.frameBorder(context)` (azul/tono oscuro) y, en éxito de captura, `_ovalSuccessGreen`. El scrim exterior es `Colors.black54`.

**Objetivo:** Óvalo en **verde** por defecto, con **efecto over** (borde destacado, sensación de relieve similar al botón de referencia).

**Paleta sugerida (referencia imagen):**

| Uso | Color | Notas |
|-----|--------|--------|
| Borde principal (brillante) | Verde vivo, ej. `#4CAF50` o más luminoso `#66BB6A` | Borde que “resalta” |
| Efecto over / relieve | Segundo trazo exterior más suave (p. ej. mismo verde con menor opacidad o verde más claro) o sombra suave | Da sensación de elevación |
| Scrim (exterior al óvalo) | Mantener oscuro (ej. `Colors.black54`) o tintado verde muy oscuro | Enfoque en el óvalo |
| Captura exitosa | Mantener verde de éxito actual o unificar con el mismo verde del óvalo | Opcional |

**Implementación sugerida:**

1. **FaceAuthColors** (`lib/presentation/auth/face_auth/face_auth_colors.dart`):
   - Añadir colores para el óvalo verde, por ejemplo:
     - `ovalBorderGreen` (verde brillante para el borde).
     - `ovalBorderGreenOver` (verde para efecto over: más claro o con opacidad, para un segundo trazo o “glow”).
   - Opcional: `ovalScrimGreen` (verde muy oscuro para el scrim) o seguir usando negro/transparente.

2. **FaceAuthCapturePage / _OvalFramePainter** (`lib/presentation/auth/face_auth/face_auth_capture_page.dart`):
   - Por defecto (modo dos capturas, flujo Face Auth) usar el **verde** para el borde del óvalo en lugar del azul (`frameBorder`).
   - En `_OvalFramePainter.paint`:
     - Dibujar un primer trazo (óvalo) más ancho y semi-transparente o más claro → efecto “glow” o relieve exterior.
     - Dibujar el trazo principal del óvalo con el verde brillante y grosor normal (ej. 3–4 px).
   - Mantener la lógica actual que pone el óvalo en verde cuando `_capture1Success || _capture2Success` si se desea feedback adicional; en ese caso puede usarse el mismo verde o uno ligeramente más claro.

**Detalle efecto over (opción A — doble trazo):**

- Primero: `canvas.drawOval(rect, Paint()..color = ovalBorderGreenOver.withOpacity(0.5) ..style = stroke ..strokeWidth = 6)`.
- Segundo: `canvas.drawOval(rect, Paint()..color = ovalBorderGreen ..style = stroke ..strokeWidth = 3)`.

**Detalle efecto over (opción B — sombra):**

- Usar un `Canvas.saveLayer` y dibujar el óvalo con un `Paint()..maskFilter = MaskFilter.blur(...)` antes del trazo principal, o dibujar el óvalo desplazado un par de píxeles con opacidad baja para simular sombra.

Elegir una de las opciones (A suele ser más simple y estable).

---

### 2.3 Eliminación de la cuenta regresiva

**Comportamiento actual:**

- Al entrar en modo `autoCapture` + `twoCaptures` se inicia `_startAutoCapture()`.
- Hay un countdown con `_autoCaptureCountdown` = 2, 1, 0; se muestra un overlay con:
  - Números grandes "2", "1" y texto "Captura en 2 segundos.", "Captura en 1 segundo.", "Capturando..." / "Mantenga la posición al frente.".
- Luego se toma la primera foto; después overlay "Gira un poco el rostro..." y "Segunda captura en 2/1 segundos…"; luego segunda foto.

**Comportamiento deseado:**

- **Quitar** el overlay que muestra "2", "1" y "Capturando..." para la **primera** captura.
- Al entrar: solo se ve la cámara, el óvalo (verde con efecto over) y el mensaje de texto arriba ("Mantenga la posición al frente."). Sin números ni "Capturando...".
- Los **tiempos se mantienen**: esperar 2 segundos y luego tomar la primera foto; después 2 segundos entre primera y segunda con el mensaje "Gira un poco el rostro..."; luego segunda foto.
- Opcional: quitar también los textos "Segunda captura en 2 segundos" / "Segunda captura en 1 segundo" y dejar solo "Gira un poco el rostro..."; los 2 segundos de espera se mantienen sin mostrar cuenta regresiva.

**Implementación:**

1. **FaceAuthCapturePage** (`face_auth_capture_page.dart`):
   - En `_startAutoCapture()`: **no** asignar `_autoCaptureCountdown` durante la fase inicial (no poner 2, 1, 0). Mantener el `await Future<void>.delayed(const Duration(seconds: 2))` (o el que corresponda a `autoCaptureDelaySeconds`) sin actualizar estado de countdown.
   - En el `build`, **no** mostrar el overlay de countdown para la primera captura: eliminar o condicionar el bloque que pinta el overlay cuando `widget.autoCapture && _autoCaptureCountdown != null` (o no poner `_autoCaptureCountdown` nunca en la primera fase para que ese overlay no aparezca).
   - Resultado: la pantalla muestra desde el inicio la preview de la cámara + óvalo + subtítulo "Mantenga la posición al frente."; a los 2 s se toma la primera foto; luego el mensaje "Gira un poco el rostro..." y, si se mantiene, el texto "Segunda captura en X segundos" o solo el mensaje de girar; 2 s después se toma la segunda foto.
   - Si se desea quitar también la cuenta regresiva de la **segunda** captura: no mostrar `_secondCaptureCountdown` en la UI (no mostrar "Segunda captura en 2/1 segundos"); mantener solo el delay de 2 s y el texto "Gira un poco el rostro...".

2. **Estado:** Se puede dejar de usar `_autoCaptureCountdown` en el flujo de dos capturas (solo usarlo en modo una captura si aplica), o mantenerlo en null durante todo el tiempo hasta la primera foto para que el overlay no se dibuje.

---

## 3. Resumen de archivos a tocar

| Archivo | Cambios |
|---------|--------|
| `lib/presentation/auth/login/login_page.dart` | Sustituir texto del botón por `'Reconocimiento facial'`. |
| `lib/presentation/auth/face_auth/face_auth_colors.dart` | Añadir colores del óvalo verde: borde brillante y color para efecto over (y opcional scrim verde). |
| `lib/presentation/auth/face_auth/face_auth_capture_page.dart` | (1) Usar colores verdes para el óvalo por defecto. (2) En `_OvalFramePainter`, implementar efecto over (doble trazo o sombra). (3) Eliminar lógica/UI de cuenta regresiva para la primera captura (y opcionalmente para la segunda): no mostrar overlay "2, 1, Capturando..."; mantener delays de 2 s y mensajes instructivos. |

---

## 4. Orden de tareas sugerido

1. Cambiar el texto del botón a "Reconocimiento facial" en LoginPage.
2. Añadir en FaceAuthColors los colores del óvalo verde y del efecto over.
3. En FaceAuthCapturePage: pintar el óvalo en verde con efecto over (doble trazo o sombra) y usar estos colores por defecto en el flujo de doble captura.
4. Ajustar _startAutoCapture y el build para quitar la cuenta regresiva (sin overlay 2/1/Capturando…); mantener delays y mensajes "Mantenga la posición al frente" y "Gira un poco el rostro...".
5. Probar flujo completo: tap en "Reconocimiento facial" → cámara con óvalo verde y efecto over → primera captura a los 2 s sin números → mensaje de girar → segunda captura a los 2 s.

---

## 5. Relación con otros documentos

- **06-plan-face-auth-api-rest.md:** Flujo de 6 pasos sin cambios; solo cambia la UX de entrada (botón y pantalla de captura).
- **08-plan-paso-3-4-capturas-y-liveness.md:** Paso 3 sigue siendo dos capturas en la misma pantalla; los mensajes "Mantenga la posición al frente" y "Gira un poco el rostro..." se mantienen; solo se elimina la cuenta regresiva visible.
