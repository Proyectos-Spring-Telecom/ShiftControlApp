# Plan de implementación: Inicio de sesión con Face Auth (autenticación por rostro)

## 1. Objetivo

Implementar la funcionalidad **Iniciar con FaceAuth** en la pantalla de login, permitiendo al usuario iniciar sesión mediante **autenticación por rostro** (similar a Face ID). La lógica de enrollamiento (registro de rostro), validación con liveness, **validateFace**, **WhereIsFace** y **embeddings 512D** se consumirá vía **API REST**. En la interfaz se realizará la **captura del rostro** y una **segunda captura de validación de cara**.

**Referencia de diseño:** [Identity Verification KYC – Dribbble](https://dribbble.com/shots/22453948-Identity-Verification-KYC) (flujo tipo KYC: encuadre, instrucciones, captura, validación).

---

## 2. Alcance

| Área | Alcance |
|------|--------|
| **Login** | El botón "Iniciar con FaceAuth" (hoy muestra "próximamente") abrirá el flujo de Face Auth: captura de rostro → validación de cara → llamada API → sesión o error. |
| **Enrollamiento** | Si el usuario aún no tiene rostro registrado, se mostrará un flujo de **enrollamiento** con **3 muestras** de rostro, validación de **liveness** y registro en backend. |
| **Validación en login** | Validación con **liveness**, **validateFace**, **WhereIsFace**; uso de **embeddings 512D** (generados/almacenados en backend). |
| **Backend** | Toda la lógica de rostro (embeddings, comparación, liveness) se asume en **servicios REST**; la app envía imágenes (o datos derivados) y recibe token/sesión o errores. |
| **UI** | Crear **nuevas pantallas** que no existen hoy: flujo de captura de rostro, segunda captura de validación, y (opcional) flujo de enrollamiento en 3 pasos. Diseño inspirado en el video KYC de Dribbble. |

---

## 3. Especificación funcional

### 3.1 Enrollamiento (registro de rostro)

- **Condición:** Usuario ya autenticado (por ejemplo por correo/contraseña o NIP) y sin rostro registrado en el sistema.
- **Flujo:**
  1. Pantalla de bienvenida / instrucciones (“Registra tu rostro para usar Face Auth”).
  2. **3 capturas** de rostro (muestras), cada una con:
     - Encuadre guiado (óvalo/marco tipo “coloca tu rostro dentro del marco”).
     - Validación de **liveness** (que sea un rostro real, no foto/video).
  3. Envío de las 3 muestras al API de enrollamiento.
  4. Backend genera/almacena **embeddings 512D** asociados al usuario.
  5. Mensaje de éxito y cierre; a partir de ahí el usuario puede usar “Iniciar con FaceAuth” en el login.

### 3.2 Login con Face Auth

- **Condición:** Usuario con rostro ya enrolado.
- **Flujo:**
  1. Usuario toca **Iniciar con FaceAuth** en la pantalla de login (modo Credenciales o NIP).
  2. Se abre la **primera captura**: “Captura de tu rostro” (encuadre, liveness si el API lo requiere en este paso).
  3. **Segunda captura**: “Validación de cara” (segunda imagen para validar identidad / liveness).
  4. La app envía las capturas (o los datos que el API defina) al servicio REST.
  5. Backend realiza **validateFace**, **WhereIsFace**, liveness y comparación con embeddings 512D; devuelve token/sesión o error.
  6. En éxito: guardar sesión (igual que login con correo/NIP) y navegar a Home. En error: mostrar mensaje y permitir reintentar o volver al login.

### 3.3 Contrato API (REST) a consumir

Los siguientes se asumen como **contratos a implementar/consumir** en el backend; la app solo consume endpoints REST.

| Operación | Descripción | Entrada (ejemplo) | Salida (ejemplo) |
|-----------|-------------|-------------------|------------------|
| **Enrollamiento** | Registrar 3 muestras de rostro del usuario autenticado. | `POST /api/face-auth/enroll`: token Bearer + 3 imágenes (base64 o multipart); opcional liveness payload. | 200 OK; error 4xx si falla liveness o calidad. |
| **Validación (login)** | Validar rostro y devolver sesión. | `POST /api/face-auth/validate`: 2 imágenes (captura rostro + validación de cara), o las que el API defina; opcional identificador de usuario/email. | 200: `{ "token": "...", "user": { ... } }` (mismo formato que login actual); 401/4xx si validateFace/WhereIsFace/liveness fallan. |
| **Estado de enrollamiento** | Saber si el usuario ya tiene rostro registrado. | `GET /api/face-auth/enrollment-status` (con Bearer). | `{ "enrolled": true \| false }`. |

- **Liveness, validateFace, WhereIsFace, embeddings 512D:** implementados en backend; la app envía imágenes (o datos que el backend indique) y recibe éxito/error.
- **Formato de imágenes:** Definir con backend (base64 en JSON, multipart/form-data, etc.).

---

## 4. Diseño de interfaz (referencia)

- **Referencia:** [Identity Verification KYC – Dribbble](https://dribbble.com/shots/22453948-Identity-Verification-KYC).
- **Elementos a replicar/adaptar:**
  - Pantalla con **marco/óvalo** para encuadrar el rostro (“Coloca tu rostro dentro del marco”).
  - **Instrucciones claras** en cada paso (captura 1, captura 2, enrollamiento muestra 1/2/3).
  - **Indicador de estado** (listo para capturar, procesando, error).
  - **Botones** de captura, reintentar, continuar, cerrar.
  - Estilo **moderno y limpio** (tipografía, espaciado, colores alineados con la app).

Las interfaces actuales **no existen**; hay que crearlas siguiendo esta referencia y la guía de estilo del proyecto (LoginColors, AppTheme, etc.).

---

## 5. Estructura de archivos propuesta

```
lib/
├── core/
│   └── constants/
│       └── route_constants.dart          # Añadir rutas: faceAuthCapture, faceAuthEnroll (si aplica)
├── data/
│   ├── datasources/remote/
│   │   └── auth_remote_datasource.dart   # Opcional: añadir métodos face-auth si se integra en AuthRemote
│   └── models/                           # Opcional: face_enroll_request, face_validate_request, etc.
├── features/
│   └── auth/
│       ├── services/
│       │   ├── auth_service.dart         # Añadir loginWithFaceAuth (o delegar a FaceAuthService)
│       │   └── face_auth_service.dart    # NUEVO: enroll(), validate(), getEnrollmentStatus()
│       └── face_auth/                     # NUEVO módulo
│           ├── face_auth_capture_page.dart      # Pantalla de captura de rostro (reutilizable)
│           ├── face_auth_validation_page.dart    # Segunda captura: validación de cara
│           ├── face_auth_enroll_flow.dart        # Flujo enrollamiento (3 muestras)
│           └── face_auth_colors.dart             # Colores (o reutilizar LoginColors)
├── presentation/
│   ├── auth/
│   │   └── login/
│   │       └── login_page.dart           # _onFaceAuthTap: navegar a flujo Face Auth en lugar de "próximamente"
│   └── controllers/
│       └── auth_controller.dart          # Añadir loginWithFaceAuth()
```

- **face_auth_capture_page.dart:** Pantalla con cámara (o selector de imagen si solo se usa galería en pruebas), marco de encuadre, botón “Capturar” y callback con imagen (bytes o base64). Reutilizable para “captura de rostro” y “validación de cara” (cambiando solo el texto).
- **face_auth_validation_page.dart:** Segunda captura; puede ser otra instancia de la misma pantalla de captura con título “Validación de cara”.
- **face_auth_enroll_flow.dart:** Orquestación de 3 capturas + llamada a enroll API (puede ser una pantalla con stepper o 3 pasos).

---

## 6. Dependencias y permisos

| Recurso | Uso |
|---------|-----|
| **Cámara** | Captura de rostro en vivo. Paquete sugerido: `camera` (o `image_picker` solo para pruebas). |
| **Permisos** | Android: `android.permission.CAMERA`. iOS: `NSCameraUsageDescription` en Info.plist. |
| **ApiClient** | Reutilizar `ApiClient` (HttpApiClient) y `AppEnvironmentConfig.baseUrl` para llamadas REST. |

No es obligatorio implementar detección de rostro o embeddings en el dispositivo; todo puede delegarse al backend.

---

## 7. Tareas de implementación (orden sugerido)

### 7.1 Backend / contrato API

- [ ] Definir con backend los endpoints exactos: paths, método HTTP, cuerpo (imágenes en base64 o multipart), headers, y formato de respuesta (token, user, errores).
- [ ] Documentar en este repo (o en 02-contratos-capas-modulos) los paths y DTOs de face-auth.

### 7.2 Servicio Face Auth (capa de datos/features)

- [ ] Crear **FaceAuthService** (o integrar en AuthService) que consuma:
  - `GET /api/face-auth/enrollment-status` → `bool enrolled`.
  - `POST /api/face-auth/enroll` → enviar 3 imágenes (y token si es necesario).
  - `POST /api/face-auth/validate` → enviar 2 imágenes (captura + validación) y recibir token + user.
- [ ] Mapear respuestas a `LoginResult` (user + token) para reutilizar `AuthLocalDatasource.saveSession` y flujo de navegación actual.

### 7.3 Pantalla de captura de rostro

- [x] Crear **FaceAuthCapturePage** (referencia visual: Dribbble KYC):
  - **Cámara frontal se abre de forma automática** al entrar en la pantalla (paquete `camera`).
  - **Marco en forma de óvalo** (elipse), no círculo; borde azul y recorte exterior semioscuro para guiar el encuadre.
  - Vista de cámara en vivo; si la cámara falla (p. ej. web), fallback a image_picker con “Toca para abrir cámara”.
  - Botón “Capturar” que toma la foto desde el controlador de cámara y devuelve los bytes al caller.
  - Manejo de permisos y errores (sin cámara, denegado).
- [x] Reutilizar esta pantalla para “Captura de tu rostro” y “Validación de cara” (títulos/textos distintos).

### 7.4 Flujo de login con Face Auth (2 capturas)

- [ ] Crear **FaceAuthValidationPage** (o flujo de dos pasos):
  - Paso 1: abrir FaceAuthCapturePage con título “Captura de tu rostro”; al capturar, guardar imagen 1.
  - Paso 2: abrir misma pantalla con título “Validación de cara”; al capturar, guardar imagen 2.
  - Llamar a `FaceAuthService.validate(image1, image2)` (o el contrato que defina el backend).
  - En éxito: guardar sesión (AuthLocalDatasource) y navegar a Home (RouteConstants.home).
  - En error: mostrar AppAlertBanner y permitir reintentar o volver al login.

### 7.5 Integración en Login

- [ ] En **LoginPage**, en `_onFaceAuthTap()`:
  - Navegar a la primera pantalla del flujo Face Auth (captura de rostro) en lugar de mostrar “próximamente”.
  - Opcional: antes de abrir captura, llamar a `getEnrollmentStatus()`; si no está enrolado, redirigir a flujo de enrollamiento o mostrar mensaje “Registra tu rostro primero desde tu perfil”.
- [ ] Añadir **AuthController.loginWithFaceAuth()** que reciba las imágenes (o el resultado del flujo) y llame al servicio; actualizar estado y navegación igual que en login con NIP/correo.

### 7.6 Enrollamiento (3 muestras)

- [ ] Crear flujo de **enrollamiento** (pantalla o wizard de 3 pasos):
  - Mostrar 3 veces la pantalla de captura (muestra 1/3, 2/3, 3/3), con liveness si el API lo requiere.
  - Recolectar 3 imágenes y enviar con `POST /api/face-auth/enroll` (con token del usuario logueado).
  - Mensaje de éxito y cierre.
- [ ] Punto de entrada al enrollamiento: desde Perfil (“Registrar mi rostro para Face Auth”) o la primera vez que el usuario toque “Iniciar con FaceAuth” (redirigir a enroll si no está enrolado).

### 7.7 Ajustes de diseño (KYC)

- [ ] Ajustar textos, espaciado, colores y componentes (marco, botones) para acercarse a la referencia [Dribbble KYC](https://dribbble.com/shots/22453948-Identity-Verification-KYC).
- [ ] Revisar en tema claro y oscuro si se usa ThemeController.

---

## 8. Resumen de flujos

| Flujo | Pantallas | API |
|-------|-----------|-----|
| **Login Face Auth** | Login → Captura rostro → Validación de cara → (éxito) Home | POST validate (2 imágenes) → token + user |
| **Enrollamiento** | Perfil o primer uso → Instrucciones → Captura 1 → Captura 2 → Captura 3 → Éxito | POST enroll (3 imágenes + Bearer) |

---

## 9. Relación con otros documentos

- **Contratos y capas:** [02-contratos-capas-modulos.md](02-contratos-capas-modulos.md) — extender con endpoints y DTOs de face-auth cuando estén definidos.
- **Contexto:** [01-contexto.md](01-contexto.md) — stack (cámara, permisos) y estructura de carpetas.
- **Login actual:** `lib/presentation/auth/login/login_page.dart` — botón “Iniciar con FaceAuth” y `_onFaceAuthTap()`.

---

## 10. Criterios de aceptación

- El usuario puede tocar **Iniciar con FaceAuth** y entrar a un flujo de **captura de rostro** y **segunda captura de validación de cara**.
- Las imágenes se envían al API REST; en respuesta exitosa se inicia sesión y se navega a Home (mismo comportamiento que login con credenciales/NIP).
- Si el backend requiere enrollamiento previo, el usuario puede registrar su rostro en **3 muestras** con validación de liveness.
- La interfaz sigue la referencia de diseño tipo KYC (marco de rostro, instrucciones claras, dos capturas en login).
- Embeddings 512D, validateFace, WhereIsFace y liveness quedan del lado del backend; la app solo captura y envía imágenes (o el formato acordado) y consume la respuesta REST.
