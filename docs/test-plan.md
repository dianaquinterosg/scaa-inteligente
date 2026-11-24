# Plan de pruebas y evidencias — MVP 60 % (v0.2)

**Estado:** plan de pruebas del MVP. T08 se ejecutó como sonda técnica de inferencia real; los demás casos funcionales siguientes **NO han sido ejecutados**. Las pruebas de la base técnica se registran por separado en [test-results.md](evidence/iteration-0/test-results.md) y no acreditan CU01–CU03 completos.

## 1. Niveles y herramientas tentativas

| Nivel | Qué verificar | Implementación propuesta | Estado |
|---|---|---|---|
| Unitarias | Normalizaciones, validaciones, clasificación, integridad de pasos | `pytest` + `pytest-asyncio` si aplica | Pendiente |
| Integración API/BD | FastAPI, SQLite, transacciones, persistencia y FKs | `TestClient`/cliente ASGI, BD de test aislada | Pendiente |
| Integración servicios externos controlada | Timeout/respuesta/error ARASAAC y adaptador IA | Fake/stubs en tests automatizados | Pendiente |
| Smoke test REAL | ARASAAC conectado e IA ejecutándose localmente | Script/endpoint manual con evidencias y datos sintéticos | Pendiente |
| Sistema E2E | Flutter→FastAPI→persistencia→consulta | Recorrido manual reproducible y capturas | Pendiente |
| Instalación release/demo | Instalación desde instrucciones y arranque | Procedimiento documentado tras verificación | Pendiente |

## 2. Casos mínimos concretos

| ID de prueba | CU / CA | Escenario y resultado esperado | Estado | Evidencia |
|---|---|---|---|---|
| T01 | CU01 / CA01.1, CA01.8 | Guardar perfil y recuperar alias/tags | No ejecutado | — |
| T02 | CU01 / CA01.4–CA01.7 | Rechazar alias vacío, tags inválidos y duplicados normalizados | No ejecutado | — |
| T03 | CU01 / CA01.9 | Error simulado de BD no reemplaza perfil existente | No ejecutado | — |
| T04 | CU02 / CA02.2–CA02.3 | Coincidencia local sin llamada externa; ausencia local consulta ARASAAC | No ejecutado | — |
| T05 | CU02 / CA02.5–CA02.7 | Archivo propio válido se incorpora solo tras aprobar; inválido se rechaza | No ejecutado | — |
| T06 | CU02 / CA02.8–CA02.9 | Pictograma ARASAAC persistido; intento duplicado no crea nueva fila | No ejecutado | — |
| T07 | CU02 / CA02.13–CA02.19 | Categorías N:M y filtrado; nombre duplicado no aceptado | No ejecutado | — |
| T08 | CU03 / CA03.2 | IA local REAL entrega 3 rutinas estructuradas válidas (registrar modelo, equipo, tiempos) | Ejecutado como sonda técnica; integración CU03 y calidad pendientes | [Inferencia real](evidence/iteration-0/integrations/bootstrap-integrations.json), [equipo y entorno](evidence/iteration-0/environment/environment-audit.md) |
| T09 | CU03 / CA03.4–CA03.5 | Exacta local > prefijo > contiene; empate local sin selección arbitraria | No ejecutado | — |
| T10 | CU03 / CA03.4, CA03.15 | ARASAAC sugiere candidato temporal; cancelar propuesta no crea filas | No ejecutado | — |
| T11 | CU03 / CA03.7, CA03.13–CA03.14 | Reordenar/repetir recurso, bloquear guardado de paso sin pictograma | No ejecutado | — |
| T12 | CU03 / CA03.8–CA03.9 | Confirmación guarda rutina/pasos/imágenes aprobadas y permite recuperarlos | No ejecutado | — |
| T13 | CU03 / CA03.15 | Falla simulada de persistencia deja BD consistente y limpia temporales | No ejecutado | — |
| T14 | CU03 / CA03.11 (P1) | IA caída → posibilidad de creación manual; si no se implementa, documentar brecha | No ejecutado | — |
| T15 | CU02/CU03 / P1 | Editar/borrar con integridad: imagen usada no se elimina; borrar rutina conserva imagen | No ejecutado | — |
| T16 | E2E | Primera configuración → incorporar pictograma → rutina IA → revisar → guardar → recuperar | No ejecutado | — |

## 3. Validación de calidad de la asociación (sin cifras inventadas)

Preparar una lista fechada de descripciones y pasos esperados. En cada ejecución registrar: `search_term`, candidato local/ARASAAC, decisión humana (`adecuado`, `corregir`, `sin resultado`), número de correcciones y duración. El orden de resultados de ARASAAC no implica que el primer pictograma sea correcto. La regla de desempate no usa IA ni umbrales inventados.

## 4. Entornos y línea base

- **Dev:** configuración local, BD y archivos de desarrollo.
- **Test:** BD de test aislada, pruebas con fakes y servicios reales **solo** en smoke tests identificados.
- **Release/demo:** ejecutables/servicios y BD separada de prueba; publicar únicamente cuando se haya verificado procedimiento de instalación y haya resultados de tests documentados.

El entregable de control debe incluir: SHA de commit, tag (por ejemplo `v0.6.0-mvp` **solo cuando exista**), contenido de release notes, versión de Python/Flutter/modelo, comandos de instalación *probados*, variables de entorno necesarias sin secretos, resultados de suite y capturas con fecha. No afirmar «producción desplegada» si solo existe demo local.

## 5. Registro de ejecución (rellenar con hechos)

| Fecha | Versión/commit | Prueba | Resultado | Evidencia | Responsable |
|---|---|---|---|---|---|
| — | — | — | No ejecutado | — | — |

## 6. Evaluación de objetivos

OE1/OE2 requieren comparar tareas equivalentes del proceso de referencia y del prototipo en condiciones definidas y registrar **tiempo e interacciones**. OE4 requiere participantes y tareas de usabilidad con asistencia observada. No usar porcentajes como «resultados» mientras no hayan sido medidos.
