# Plan de implementación: Mensaje de éxito al iniciar sesión con reconocimiento facial

## 1. Objetivo

Modificar el texto que se muestra al usuario cuando inicia sesión correctamente con **reconocimiento facial**. Actualmente el mensaje de éxito dice **"Has iniciado sesión con Face Auth."**; debe cambiarse a **"Iniciaste sesión con reconocimiento facial."** para alinear el copy con el nombre del botón ("Reconocimiento facial") y un tono más natural en español.

---

## 2. Ubicación actual

| Elemento | Valor actual |
|----------|--------------|
| **Archivo** | `lib/presentation/auth/face_auth/face_auth_flow_page.dart` |
| **Widget** | `showAppAlertBanner` (éxito tras `setSessionFromFaceAuth`) |
| **Título** | `'Bienvenido'` (se mantiene) |
| **Mensaje** | `'Has iniciado sesión con Face Auth.'` |

El banner se muestra justo antes de navegar a Home (`pushReplacementNamed(RouteConstants.home)`), tras validar el rostro y establecer la sesión.

---

## 3. Cambio solicitado

| Campo | Antes | Después |
|-------|--------|---------|
| **Mensaje** | `Has iniciado sesión con Face Auth.` | `Iniciaste sesión con reconocimiento facial.` |
| **Título** | `Bienvenido` | Sin cambio (opcional: se puede dejar o ajustar según criterio de producto). |

Solo es obligatorio cambiar el **message** al nuevo texto. El **title** puede seguir siendo "Bienvenido" o, si se prefiere un único texto destacado, usar "Iniciaste sesión con reconocimiento facial." como título y un mensaje breve (ej. "Bienvenido.") como mensaje; este plan asume **solo** el cambio del mensaje.

---

## 4. Tarea de implementación

### 4.1 Modificación en código

En `lib/presentation/auth/face_auth/face_auth_flow_page.dart`, localizar la llamada:

```dart
showAppAlertBanner(
  context,
  type: AppAlertType.success,
  title: 'Bienvenido',
  message: 'Has iniciado sesión con Face Auth.',
);
```

Sustituir el parámetro `message` por:

```dart
message: 'Iniciaste sesión con reconocimiento facial.',
```

Dejar `title: 'Bienvenido'` sin cambios (salvo que se decida unificar todo en un solo texto).

### 4.2 Verificación

- Iniciar sesión con reconocimiento facial (flujo completo: credenciales → capturas → liveness → validateFace).
- Tras éxito, debe mostrarse el banner con título "Bienvenido" y mensaje **"Iniciaste sesión con reconocimiento facial."**.
- Comprobar que la navegación a Home sigue funcionando igual.

---

## 5. Resumen de archivos

| Archivo | Acción |
|---------|--------|
| `lib/presentation/auth/face_auth/face_auth_flow_page.dart` | Cambiar `message` de `'Has iniciado sesión con Face Auth.'` a `'Iniciaste sesión con reconocimiento facial.'`. |
| `docs/13-plan-face-auth-mensaje-exito-sesion.md` | Este documento (plan). |

---

## 6. Relación con otros documentos

- **09-plan-face-auth-boton-ovalo-y-countdown.md:** El botón en login ya se llama "Reconocimiento facial"; este plan alinea el mensaje de éxito con esa nomenclatura.
- **01-contexto.md / 02-contratos-capas-modulos.md:** No requieren cambios; es solo copy de UI.
