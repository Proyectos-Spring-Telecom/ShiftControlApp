# Documentación Turnos Spring

Documentación de contexto y contratos de la solución.

| Documento | Contenido |
|-----------|-----------|
| [01-contexto.md](01-contexto.md) | Contexto de la solución: descripción general, stack, estructura de carpetas, flujos principales, decisiones de diseño y convenciones. |
| [02-contratos-capas-modulos.md](02-contratos-capas-modulos.md) | Contratos por capas y módulos: Core (ApiClient, excepciones, rutas, config), Domain (AuthRepository, entidades, use cases), Data (datasources, repository impl), Presentation (router, AuthController, providers), Features y utilidades multiplataforma. |
| [03-plan-identificacion-vehiculo-por-placa.md](03-plan-identificacion-vehiculo-por-placa.md) | Plan de implementación: identificación de vehículo por placa (foto/imagen) en Apertura y Cierre de Turno, sustituyendo el escaneo QR en la opción Seleccionar Vehículo. |
| [04-plan-actualizacion-textos-escaner-vehiculo.md](04-plan-actualizacion-textos-escaner-vehiculo.md) | Plan de implementación: actualización de textos de la interfaz Escáner Vehículo (“Escanea la placa del vehículo”, “Coloca la placa del vehículo dentro del marco”) en Apertura y Cierre de Turno. |
| [05-plan-face-auth-login.md](05-plan-face-auth-login.md) | Plan de implementación: inicio de sesión con Face Auth (autenticación por rostro). Enrollamiento (3 muestras), validación con liveness, validateFace, WhereIsFace, embeddings 512D vía API REST; UI de captura de rostro y segunda captura de validación. Referencia de diseño: Dribbble Identity Verification KYC. |
| [06-plan-face-auth-api-rest.md](06-plan-face-auth-api-rest.md) | Plan de implementación: Face Auth con servicios API REST (6 pasos: login, auth/me, dos capturas + 2 s, liveness-check, embed, validateFace). Contrato de endpoints, multipart, configuración base URL y tareas de implementación. Referencia: Swagger API BehaviorIQ. |
| [07-plan-face-auth-paso-4-5-liveness-embed.md](07-plan-face-auth-paso-4-5-liveness-embed.md) | Plan para Paso 4 (Liveness-check) y Paso 5 (Embed): validación de imágenes, instrucción "gire a la derecha/izquierda", reintentos cuando liveness no pasa, y verificación de URLs/contratos. Contrato Paso 6: body validateFace con `embeddings` (array 512D). |
| [08-plan-paso-3-4-capturas-y-liveness.md](08-plan-paso-3-4-capturas-y-liveness.md) | Paso 3 (dos capturas): mensajes "Mantenga la posición al frente", "Gira un poco el rostro...", countdown 2 s; Paso 4 (liveness): mensaje "Gire...", 404 validateFace con Reintentar/Volver al login. Estado de implementación actual. |
