# Plan de pruebas y evidencias — MVP 60 % (v0.2)

**Estado:** T01–T03 tienen pruebas automáticas aprobadas para CU01; pruebas funcionales manuales en iPad pendientes. T08 cuenta con tres escenarios de inferencia real a través de la API de CU03. T04–T07 se aprobaron con pruebas automáticas de CU02. T15 se verificó con rutinas y pictogramas persistidos. Ver [Iteración 0](evidence/iteration-0/test-results.md) e [Iteración 1](evidence/iteration-1/results.md); CU02 tiene una [regresión específica](evidence/iteration-2/results.md) y un [recorrido manual confirmado en simulador](evidence/iteration-2/manual-check.md). CU03 completó pruebas controladas e integración real. La persona usuaria informó que ejecutó las pruebas manuales de CU03 en el simulador. La validación con usuarios y T16 siguen pendientes.

## 1. Niveles y herramientas tentativas

| Nivel | Qué verificar | Implementación propuesta | Estado |
|---|---|---|---|
| Unitarias | Normalizaciones, validaciones, clasificación, integridad de pasos | `pytest` + `pytest-asyncio` si aplica | CU01–CU03 probados |
| Integración API/BD | FastAPI, SQLite, transacciones, persistencia y FKs | `TestClient`/cliente ASGI, BD de test aislada | CU01–CU03 y migraciones probados |
| Integración servicios externos controlada | Timeout/respuesta/error ARASAAC y adaptador IA | Fakes y transporte HTTP controlado | Error ARASAAC, timeout y salida inválida de Ollama probados |
| Smoke test REAL | ARASAAC conectado e IA ejecutándose localmente | Script/endpoint manual con evidencias y datos sintéticos | ARASAAC real probado en CU02 y CU03. Inferencia Ollama real probada en CU03 con calidad semántica provisional |
| Sistema E2E | Flutter→FastAPI→persistencia→consulta | Recorrido manual reproducible y capturas | HTTP CU01–CU03 probado. CU01 tiene aprobación visual y CU02 recorrido en simulador confirmado. La ejecución manual de CU03 fue reportada sin resultados individuales. T16 sigue pendiente. |
| Instalación release/demo | Instalación desde instrucciones y arranque | Procedimiento documentado tras verificación | Pendiente |

## 2. Casos mínimos concretos

| ID de prueba | CU / CA | Escenario y resultado esperado | Estado | Evidencia |
|---|---|---|---|---|
| T01 | CU01 / CA01.1, CA01.8 | Guardar perfil y recuperar alias/tags | Aprobado automáticamente; prueba funcional manual pendiente | [Criterios y pruebas CU01](evidence/iteration-1/cu01/acceptance.json) |
| T02 | CU01 / CA01.4–CA01.7 | Rechazar alias vacío, tags inválidos y duplicados normalizados | Aprobado automáticamente; prueba funcional manual pendiente | [Criterios y pruebas CU01](evidence/iteration-1/cu01/acceptance.json) |
| T03 | CU01 / CA01.9 | Error simulado de BD no reemplaza perfil existente | Aprobado automáticamente; prueba funcional manual pendiente | [Criterios y pruebas CU01](evidence/iteration-1/cu01/acceptance.json) |
| T04 | CU02 / CA02.2–CA02.3 | Coincidencia local sin llamada externa; ausencia local consulta ARASAAC | Aprobado automáticamente | [CU02](evidence/iteration-2/results.md) |
| T05 | CU02 / CA02.5–CA02.7 | Archivo propio válido se incorpora solo tras aprobar; inválido se rechaza | Aprobado automáticamente | [CU02](evidence/iteration-2/results.md) |
| T06 | CU02 / CA02.8–CA02.9 | Pictograma ARASAAC persistido; intento duplicado no crea nueva fila | Aprobado automáticamente | [CU02](evidence/iteration-2/results.md) |
| T07 | CU02 / CA02.13–CA02.19 | Categorías N:M y filtrado; nombre duplicado no aceptado | Aprobado automáticamente | [CU02](evidence/iteration-2/results.md) |
| T08 | CU03 / CA03.2 | IA local REAL entrega 3 rutinas estructuradas válidas (registrar modelo, equipo y resultado) | Tres respuestas estructuradas reales. Calidad provisional | [CU03](evidence/iteration-3/results.md) |
| T09 | CU03 / CA03.4–CA03.5 | Exacta local > prefijo > contiene; empate local sin selección arbitraria | Aprobado automáticamente | [CU03](evidence/iteration-3/results.md) |
| T10 | CU03 / CA03.4, CA03.15 | ARASAAC sugiere candidato temporal; cancelar propuesta no crea filas | Aprobado automáticamente | [CU03](evidence/iteration-3/results.md) |
| T11 | CU03 / CA03.7, CA03.13–CA03.14 | Reordenar/repetir recurso, bloquear guardado de paso sin pictograma | Aprobado automáticamente | [CU03](evidence/iteration-3/results.md) |
| T12 | CU03 / CA03.8–CA03.9 | Confirmación guarda rutina/pasos/imágenes aprobadas y permite recuperarlos | Aprobado automáticamente | [CU03](evidence/iteration-3/results.md) |
| T13 | CU03 / CA03.15 | Falla simulada de persistencia deja BD consistente y limpia temporales | Aprobado automáticamente | [CU03](evidence/iteration-3/results.md) |
| T14 | CU03 / CA03.11 (P1) | IA caída → posibilidad de creación manual; si no se implementa, documentar brecha | Aprobado automáticamente | [CU03](evidence/iteration-3/results.md) |
| T15 | CU02/CU03 / P1 | Editar/borrar con integridad: imagen usada no se elimina; borrar rutina conserva imagen | Aprobado con una rutina real y comprobación de conservación de imágenes | [CU03](evidence/iteration-3/results.md) |
| T16 | E2E | Primera configuración → incorporar pictograma → rutina IA → revisar → guardar → recuperar | No ejecutado | — |

## 3. Validación de calidad de la asociación (sin cifras inventadas)

Preparar una lista identificada por iteración y prueba, con descripciones y pasos esperados. En cada ejecución registrar: `search_term`, candidato local/ARASAAC, decisión humana (`adecuado`, `corregir`, `sin resultado`) y número de correcciones. El orden de resultados de ARASAAC no implica que el primer pictograma sea correcto. La regla de desempate no usa IA ni umbrales inventados.

## 4. Entornos y línea base

- **Dev:** configuración local, BD y archivos de desarrollo.
- **Test:** BD de test aislada, pruebas con fakes y servicios reales **solo** en smoke tests identificados.
- **Release/demo:** ejecutables/servicios y BD separada de prueba; publicar únicamente cuando se haya verificado procedimiento de instalación y haya resultados de tests documentados.

El registro de gestión de configuración debe incluir SHA de commit, tag (por ejemplo `v0.6.0-mvp` **solo cuando exista**), contenido de release notes, versión de Python/Flutter/modelo, comandos de instalación *probados*, variables de entorno necesarias sin secretos, resultados de suite y capturas identificadas por iteración, funcionalidad, requisito, prueba y commit. No afirmar «producción desplegada» si solo existe demo local.

## 5. Registro de ejecución por alcance

| Iteración / funcionalidad | Commit asociado | Pruebas y resultado | Evidencia | Pendiente |
|---|---|---|---|---|
| 0 — preparación técnica | `db312e3592648a3b620d66b2ea22af018396112e` | 6 backend, 2 Flutter y sondas reales aprobadas; iPad confirmado por la persona usuaria | [Cierre](evidence/iteration-0/README.md) | Limitaciones del modelo provisional |
| 1 — CU01 | Implementación funcional `854180f` y adaptación visual `bca2e58` | 45 backend, 17 Flutter y 7 escenarios HTTP reales aprobados. Análisis sin incidencias | [Regresión visual](evidence/iteration-1/visual.md) | Aspecto aprobado en simulador; pruebas funcionales manuales pendientes |
| 2 — CU02 | `c311854`, `7a0acd5`, `3e256e8` | 68 backend, 21 Flutter, 4 escenarios HTTP y recorrido de iPad confirmado | [Iteración 2](evidence/iteration-2/README.md) | CA02.12 resuelto en Iteración 3 |
| 3 — CU03 | `51c191b`, `0212ce4`, `c3ad225` | 95 backend, 25 Flutter, 11 verificaciones HTTP CU03 y regresiones HTTP CU01/CU02 | [Iteración 3](evidence/iteration-3/results.md) | Calidad semántica provisional. Ejecución en simulador reportada. T16 pendiente |

Los registros documentales excluyen metadatos temporales. Los resultados se asocian al alcance y al código real, sin atribuir un commit inexistente.

## 6. Verificación de objetivos de calidad y usabilidad

OE1/OE2 requieren comparar tareas equivalentes del proceso de referencia y del prototipo en condiciones definidas y registrar **tiempo e interacciones**. OE4 requiere participantes y tareas de usabilidad con asistencia observada. No usar porcentajes como «resultados» mientras no hayan sido medidos.
