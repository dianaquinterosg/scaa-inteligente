# Matriz de trazabilidad — diseño v0.2

**Estado:** especificación prevista en la línea base documental v0.2. Existe una base técnica y se ejecutaron sondas de servicios y pruebas de infraestructura; CU01 está implementado con pruebas automáticas aprobadas y aceptación visual pendiente; CU02–CU03 siguen pendientes. No hay release de software verificada. `P0/P1/P2` son prioridades, **no resultados**.

| Requisito | CU | CA vinculados | Prioridad | Componente real de CU01 / previsto para otros CU | Prueba/evidencia esperada | Resultado/commit |
|---|---|---|---|---|---|---|
| RF01.1 | CU01 | CA01.1–CA01.3, CA01.8 | P0 | `ProfileGate`, `ProfileEditor`, `ProfileApi`; `ProfileRepository` | API, widgets y HTTP real; recuperación tras reiniciar | [Pruebas aprobadas](evidence/iteration-1/cu01/acceptance.json); revisión iPad pendiente; API `89647a9`, Flutter `f81d180` |
| RF01.2 | CU01 | CA01.10 | P0 | `ProfileRepository.load`, estado confirmado de `ProfileGate` | Borrador/cancelación sin persistencia; solo contexto confirmado disponible | [Exposición de contexto probada](evidence/iteration-1/cu01/acceptance.json); consumo por IA pendiente de CU03 |
| RF01.3 | CU01 | CA01.4–CA01.7, CA01.9 | P0 | `ProfilePayload`, validadores de `ProfileEditor`, transacción de `ProfileRepository.save` | Entradas, límites, duplicados y rollback real SQLite | [Pruebas aprobadas](evidence/iteration-1/cu01/acceptance.json); API `89647a9`, Flutter `f81d180` |
| RF02.1 | CU02 | CA02.1 | P0 | PictogramPage | Búsqueda textual en UI/API | Pendiente |
| RF02.2 | CU02 | CA02.2–CA02.3, CA02.10 | P0 | PictogramSearchService / ArasaacClient | Local primero; ARASAAC real y mock/error | Pendiente |
| RF02.3 | CU02 (extensión futura) | Por definir | P2 | ImageGenerator futuro | Calidad visual/integración IA por planificar | Posterior al 60 % |
| RF02.4 | CU02 | CA02.5–CA02.6 | P0 | MediaUploadService | Archivo válido, inválido y tamaño máximo | Pendiente |
| RF02.5 | CU02 | CA02.4, CA02.7 | P0 | PictogramForm / PictogramService | No guardar sin confirmación; etiqueta editable | Pendiente |
| RF02.6 | CU02 | CA02.8–CA02.9 | P0 | PictogramRepository / MediaStorage | Persistencia y no duplicado ARASAAC | Pendiente |
| RF02.6 (eliminación) | CU02 | CA02.11–CA02.12 | P1 | PictogramService / RoutineStepRepository | Eliminación protegida por dependencia | Pendiente |
| RF02.7 (crear) | CU02 | CA02.13–CA02.14 | P0 | CategoryService | Categoría válida y duplicados | Pendiente |
| RF02.7 (editar/borrar) | CU02 | CA02.15, CA02.18 | P1 | CategoryService | Renombrar y borrar preservando pictogramas | Pendiente |
| RF02.8 | CU02 | CA02.16, CA02.19 | P0 | PictogramCategoryRepository | N:M y persistencia asociaciones | Pendiente |
| RF02.9 | CU02 | CA02.17 | P0 | PictogramSearchService | Filtro por categoría | Pendiente |
| RF03.1 | CU03 | CA03.1 | P0 | RoutinePage | Descripción escrita válida | Pendiente |
| RF03.2 | CU03 | CA03.2–CA03.3 | P0 | RoutineGenerator / OllamaAdapter | 3 salidas JSON IA real + esquema válido | Pendiente |
| RF03.3 | CU03 | CA03.4–CA03.5, CA03.15 | P0 | AssociationService / ArasaacClient | Reglas de ranking, preselección provisional | Pendiente |
| RF03.4 | CU03 | CA03.7, CA03.14 | P0 | RoutineEditor | Agregar, modificar, ordenar, repetir | Pendiente |
| RF03.5 | CU03 | CA03.6, CA03.13 | P0 | RoutineEditor / CU02 | Reemplazo y resolución de paso pendiente | Pendiente |
| RF03.6 | CU03 | CA03.8–CA03.9, CA03.13, CA03.15 | P0 | RoutineService / RoutineRepository | Confirmación, rollback y recuperación | Pendiente |
| RF03.7 | CU03 | CA03.10, CA03.12 | P1 | RoutineService / Repository | Editar, borrar, conservar imágenes | Pendiente |
| RF03.8 | CU03 | CA03.11 | P1 | RoutinePage / RoutineService | IA indisponible → edición manual | Pendiente |
| RF04.1–RF04.3 | CU04 | Por definir | P2 | RecommendationService futuro | Pertinencia ≥70 % tras implementación | Posterior al 60 % |
| RF05.1–RF05.2 | CU05 | Por definir | P2 | CommunicationView futuro | Navegación/comunicación con recursos aprobados | Posterior al 60 % |

## Evidencia técnica previa a la implementación funcional

| Referencia | Código real | Evidencia | Límite |
|---|---|---|---|
| Preparación de persistencia | `backend/scaa_backend/database.py:Database`, `backend/tests/test_bootstrap.py` | [Resultados de la base técnica](evidence/iteration-0/test-results.md) | Conexiones, rollback y entornos; no verifica persistencia de perfiles, pictogramas ni rutinas |
| RF02.2 / CA02.3 | `backend/scripts/probe_integrations.py:probe_arasaac` | [Consulta e imagen reales](evidence/iteration-0/integrations/bootstrap-integrations.json) | Viabilidad del servicio externo; CU02 no implementado |
| RF03.2 / CA03.2–CA03.3 | `backend/scripts/probe_integrations.py:probe_ollama` | [Tres propuestas reales](evidence/iteration-0/integrations/bootstrap-integrations.json) | JSON y orden verificados en sonda; calidad e integración CU03 pendientes |
| Conectividad del cliente | `frontend/lib/backend_client.dart:BackendClient.check`, `backend/scaa_backend/main.py:create_app` | [Petición real desde Dart](evidence/iteration-0/flutter/bootstrap-dart-backend-http.log) | Endpoint técnico de salud; no es T16 ni el recorrido de los casos de uso |

Las sondas de Iteración 0 no equivalen a completar los RF de CU02/CU03. CU01 tiene [cobertura específica por criterio](evidence/iteration-1/cu01/acceptance.json), [código y pruebas](evidence/iteration-1/README.md); la aceptación manual en iPad sigue pendiente. Los commits funcionales se enumeran en el índice de Iteración 1.

## Cómo completar la trazabilidad con Codex

Por cada subrequisito implementado, registrar **ruta y símbolo reales** (`archivo:función/clase`), ID de test, resultado, enlace/captura, commit SHA y versión/tag verificados. Si se modifica un RF, actualizar CU y test asociado antes de aceptar el cambio. Evitar registrar paths inventados como si fuesen reales.

**Ejemplo ilustrativo (NO realizado):** `RF03.3 → CU03 → CA03.4/03.5 → AssociationService → test de empate local / candidato externo → evidencia pytest → SHA → tag`.

## Trazabilidad de indicadores

- **OE1:** tiempo y número de interacciones en incorporación manual vs. CU02; meta ≥50 % de reducción.
- **OE2:** tiempo y número de interacciones en rutina manual vs. CU03; meta ≥50 % de reducción.
- **OE3:** recomendaciones pertinentes ≥70 % cuando se implemente CU04.
- **OE4:** tareas completadas sin asistencia ≥80 % con evaluación de usabilidad.

Estos umbrales son **metas, no resultados**. No afirmar mejora cuantitativa sin protocolo, muestra y evidencia.
