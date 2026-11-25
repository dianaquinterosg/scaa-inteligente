# Matriz de trazabilidad — requisitos v0.2 e implementación

**Línea base:** los requisitos y prioridades proceden del SRS v0.2. **Estado de implementación:** Existe una base técnica y se ejecutaron sondas de servicios y pruebas de infraestructura; CU01 está implementado con pruebas automáticas aprobadas y aprobación visual confirmada por la persona usuaria; CU02 está implementado y probado automáticamente. La persona usuaria confirmó el recorrido manual en el simulador de iPad. CU03 está implementado y probado por API, widgets e integración real. La persona usuaria confirmó los escenarios manuales del incremento anterior en [CU01](evidence/iteration-1/manual-check.md), [CU02](evidence/iteration-2/manual-check.md) y [CU03](evidence/iteration-3/manual-check.md). La persona usuaria reportó 16 comprobaciones aprobadas de la [Iteración 4 en Device Hub](evidence/iteration-4/manual-check.md). La aceptación de calidad del modelo sigue pendiente. No hay release de software verificada. `P0/P1/P2` son prioridades, **no resultados**.

| Requisito | CU | CA vinculados | Prioridad | Componente implementado o planificado | Verificación prevista o ejecutada | Estado y evidencia vinculada |
|---|---|---|---|---|---|---|
| RF01.1 | CU01 | CA01.1–CA01.3, CA01.8 | P0 | `ProfileGate`, `ProfileEditor`, `ProfileApi`; `ProfileRepository` | API, widgets y HTTP real; recuperación tras reiniciar | [Pruebas aprobadas](evidence/iteration-1/cu01/acceptance.json); aprobación visual y funcional en iPad reportada; API `89647a9`, Flutter `f81d180` |
| RF01.2 | CU01 | CA01.10 | P0 | `ProfileRepository.load`, estado confirmado de `ProfileGate` | Borrador/cancelación sin persistencia; solo contexto confirmado disponible | [Exposición de contexto probada](evidence/iteration-1/cu01/acceptance.json); consumo del contexto persistido probado en CU03 · [I3](evidence/iteration-3/results.md) |
| RF01.3 | CU01 | CA01.4–CA01.7, CA01.9 | P0 | `ProfilePayload`, validadores de `ProfileEditor`, transacción de `ProfileRepository.save` | Entradas, límites, duplicados y rollback real SQLite | [Pruebas aprobadas](evidence/iteration-1/cu01/acceptance.json); API `89647a9`, Flutter `f81d180` |
| RF02.1 | CU02 | CA02.1 | P0 | `PictogramScreen`, `Catalog.list` | Búsqueda textual en UI/API | Aprobado automáticamente · [Iteración 2](evidence/iteration-2/results.md) |
| RF02.2 | CU02 | CA02.2–CA02.3, CA02.10 | P0 | `Catalog`, `ArasaacClient`, `PictogramScreen` | Local primero; ARASAAC real y mock/error | Aprobado automáticamente · [Iteración 2](evidence/iteration-2/results.md) |
| RF02.3 | CU02 (extensión futura) | Por definir | P2 | ImageGenerator futuro | Calidad visual/integración IA por planificar | Posterior al 60 % |
| RF02.4 | CU02 | CA02.5–CA02.6 | P0 | `choosePictogramFile`, `image_format` | Archivo válido, inválido y tamaño máximo | Aprobado automáticamente. Importación de un PNG desde Archivos confirmada por la persona usuaria · [Iteración 2](evidence/iteration-2/results.md) |
| RF02.5 | CU02 | CA02.4, CA02.7 | P0 | `PictogramEditor`, `PictogramApproval` | No guardar sin confirmación; etiqueta editable | Aprobado automáticamente · [Iteración 2](evidence/iteration-2/results.md) |
| RF02.6 | CU02 | CA02.8–CA02.9 | P0 | `Catalog`, archivos locales | Persistencia y no duplicado ARASAAC | Aprobado automáticamente · [Iteración 2](evidence/iteration-2/results.md) |
| RF02.6 (eliminación) | CU02 | CA02.11–CA02.12 | P1 | `Catalog.delete`, FK restrictiva | Eliminación protegida por dependencia | CA02.11 aprobado. CA02.12 verificado con una rutina real, I3-HTTP-CA02.12 · [Iteración 3](evidence/iteration-3/results.md) |
| RF02.7 (crear) | CU02 | CA02.13–CA02.14 | P0 | `CategoryScreen`, `Catalog.save_category` | Categoría válida y duplicados | Aprobado automáticamente · [Iteración 2](evidence/iteration-2/results.md) |
| RF02.7 (editar/borrar) | CU02 | CA02.15, CA02.18 | P1 | `CategoryScreen`, `Catalog` | Renombrar y borrar preservando pictogramas | Aprobado automáticamente · [Iteración 2](evidence/iteration-2/results.md) |
| RF02.8 | CU02 | CA02.16, CA02.19 | P0 | Tabla `pictogram_category`, `Catalog._assign` | N:M y persistencia asociaciones | Aprobado automáticamente · [Iteración 2](evidence/iteration-2/results.md) |
| RF02.9 | CU02 | CA02.17 | P0 | `PictogramScreen`, `Catalog.list` | Filtro por categoría | Aprobado automáticamente · [Iteración 2](evidence/iteration-2/results.md) |
| RF03.1 | CU03 | CA03.1 | P0 | `RoutinesScreen`, `ProposalInput` | Descripción escrita válida | Pruebas automáticas aprobadas. Escenarios manuales aprobados según la persona usuaria · [Iteración 3](evidence/iteration-3/results.md) |
| RF03.2 | CU03 | CA03.2–CA03.3 | P0 | `OllamaGenerator`, `GeneratedRoutine`, `GeneratedStep` | 3 salidas JSON IA real + esquema válido | Tres respuestas estructuradas reales. Calidad semántica provisional · [Iteración 3](evidence/iteration-3/results.md) |
| RF03.3 | CU03 | CA03.4–CA03.5, CA03.15 | P0 | `associate`, `Catalog`, `ArasaacClient` | Reglas de ranking, preselección provisional | Pruebas automáticas aprobadas. Escenarios manuales aprobados según la persona usuaria · [Iteración 3](evidence/iteration-3/results.md) |
| RF03.4 | CU03 | CA03.7, CA03.14 | P0 | `RoutineEditor`, `ApprovedStep` | Agregar, modificar, ordenar, repetir | Pruebas automáticas aprobadas. Escenarios manuales aprobados según la persona usuaria · [Iteración 3](evidence/iteration-3/results.md) |
| RF03.5 | CU03 | CA03.6, CA03.13 | P0 | `RoutinePictograms`, `PictogramScreen` | Reemplazo y resolución de paso pendiente | Pruebas automáticas aprobadas. Escenarios manuales aprobados según la persona usuaria · [Iteración 3](evidence/iteration-3/results.md) |
| RF03.6 | CU03 | CA03.8–CA03.9, CA03.13, CA03.15 | P0 | `RoutineApproval`, `RoutineRepository.save` | Confirmación, rollback y recuperación | Pruebas automáticas aprobadas. Escenarios manuales aprobados según la persona usuaria · [Iteración 3](evidence/iteration-3/results.md) |
| RF03.7 | CU03 | CA03.10, CA03.12 | P1 | `RoutineRepository`, `RoutinesScreen` | Editar, borrar, conservar imágenes | Pruebas automáticas aprobadas. Escenarios manuales aprobados según la persona usuaria · [Iteración 3](evidence/iteration-3/results.md) |
| RF03.8 | CU03 | CA03.11 | P1 | `routine_api.propose`, editor manual de `RoutinesScreen` | IA indisponible → edición manual | Pruebas automáticas aprobadas. Escenarios manuales aprobados según la persona usuaria · [Iteración 3](evidence/iteration-3/results.md) |
| RF04.1–RF04.3 | CU04 | Por definir | P2 | RecommendationService futuro | Pertinencia ≥70 % tras implementación | Posterior al 60 % |
| RF05.1–RF05.2 | CU05 | CA-I4.2–CA-I4.3 para la porción visual | P2 | `PictogramScreen` en visualización y `RoutineViewer` | Navegación de catálogo y lectura de secuencias aprobadas | Implementación parcial anticipada · [Iteración 4](evidence/iteration-4/README.md). CU05 integral permanece planificado. |

## Refinamientos de la Iteración 4

| Requisito | CU / CA | Código | Prueba |
|---|---|---|---|
| RF-I4.1 | CU01–CU03 / CA-I4.1–CA-I4.3 | `ProfileGate`, `ScaaModeBanner`, `PictogramScreen`, `RoutinesScreen` | I4-01, I4-02 · I4-M01–I4-M07 |
| RF-I4.2 | CU02, CU05 parcial / CA-I4.2 | `PictogramScreen`, `Catalog.list` | I4-02 · I4-M02, I4-M03, I4-M06, I4-M07 |
| RF-I4.3 | CU03, CU05 parcial / CA-I4.3 | `RoutinesScreen`, `RoutineViewer`, `RoutineEditor` | I4-03 · I4-M07–I4-M13 |
| RF-I4.4 | CU02–CU03 / CA-I4.4–CA-I4.5 | `Catalog.delete`, `CatalogApi.delete`, `PictogramEditor`, FK de `routine_step` | I4-04, I4-05 · I4-M14–I4-M16 · `0849ffb` |

Los resultados y commits funcionales se mantienen en las [evidencias de Iteración 4](evidence/iteration-4/README.md).

## Evidencia técnica previa a la implementación funcional

| Referencia | Código real | Evidencia | Límite |
|---|---|---|---|
| Preparación de persistencia | `backend/scaa_backend/database.py:Database`, `backend/tests/test_bootstrap.py` | [Resultados de la base técnica](evidence/iteration-0/test-results.md) | Conexiones, rollback y entornos; no verifica persistencia de perfiles, pictogramas ni rutinas |
| RF02.2 / CA02.3 | `backend/scripts/probe_integrations.py:probe_arasaac` | [Consulta e imagen reales](evidence/iteration-0/integrations/bootstrap-integrations.json) | Viabilidad externa en Iteración 0; integración real registrada en Iteración 2 |
| RF03.2 / CA03.2–CA03.3 | `backend/scripts/probe_integrations.py:probe_ollama` | [Tres propuestas reales](evidence/iteration-0/integrations/bootstrap-integrations.json) | JSON y orden verificados en la sonda inicial. Integración de CU03 y calidad provisional documentadas en Iteración 3 |
| Conectividad del cliente | `frontend/lib/backend_client.dart:BackendClient.check`, `backend/scaa_backend/main.py:create_app` | [Petición real desde Dart](evidence/iteration-0/flutter/bootstrap-dart-backend-http.log) | Endpoint técnico de salud; no es T16 ni el recorrido de los casos de uso |

Las sondas de Iteración 0 no equivalen a completar los RF de CU02/CU03. CU01 tiene [cobertura específica por criterio](evidence/iteration-1/cu01/acceptance.json), [código y pruebas](evidence/iteration-1/README.md); la aprobación manual consta en el [registro de CU01](evidence/iteration-1/manual-check.md). Los commits funcionales se enumeran en el índice de Iteración 1.

## Procedimiento de trazabilidad de cambios

Por cada subrequisito implementado, registrar **ruta y símbolo reales** (`archivo:función/clase`), ID de test, resultado, enlace/captura, commit SHA y versión/tag verificados. Si se modifica un RF, actualizar CU y test asociado antes de aceptar el cambio. Evitar registrar paths inventados como si fuesen reales.

**Ejemplo ilustrativo (NO realizado):** `RF03.3 → CU03 → CA03.4/03.5 → AssociationService → test de empate local / candidato externo → evidencia pytest → SHA → tag`.

## Trazabilidad de indicadores

- **OE1:** tiempo y número de interacciones en incorporación manual vs. CU02; meta ≥50 % de reducción.
- **OE2:** tiempo y número de interacciones en rutina manual vs. CU03; meta ≥50 % de reducción.
- **OE3:** recomendaciones pertinentes ≥70 % cuando se implemente CU04.
- **OE4:** tareas completadas sin asistencia ≥80 % con evaluación de usabilidad.

Estos umbrales son **metas, no resultados**. No afirmar mejora cuantitativa sin protocolo, muestra y evidencia.

Para RF01.1–RF01.3 / CA01.1–CA01.10, la [regresión de CU01 con el diseño SCAA](evidence/iteration-1/visual.md) vincula el tema `6eb2d40` y las pantallas `bca2e58` con los mismos casos de aceptación. La persona usuaria aprobó el aspecto visual en el simulador de iPad. Los escenarios funcionales manuales constan como aprobados en el [registro de CU01](evidence/iteration-1/manual-check.md). La exclusión de un borrador y el uso del contexto confirmado por CU03 se probaron a través del contrato de generación.
