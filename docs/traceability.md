# Matriz de trazabilidad — diseño v0.2

**Estado:** especificación prevista en la línea base documental v0.2, incorporada al repositorio. **Sin código, pruebas ejecutadas ni release de software verificados.** No completar referencias de implementación hasta comprobarlas en repositorio. `P0/P1/P2` son prioridades, **no resultados**.

| Requisito | CU | CA vinculados | Prioridad | Componente previsto (no código existente) | Prueba/evidencia esperada | Resultado/commit |
|---|---|---|---|---|---|---|
| RF01.1 | CU01 | CA01.1–CA01.3, CA01.8 | P0 | ProfilePage / ProfileService / ProfileRepository | API perfil + flujo en UI | Pendiente |
| RF01.2 | CU01 | CA01.10 | P0 | ProfileService / RoutineContextAdapter futuro | Solo información aprobada disponible | Pendiente |
| RF01.3 | CU01 | CA01.4–CA01.7, CA01.9 | P0 | ProfileSchema / ProfileService | Validación, duplicados y rollback | Pendiente |
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

## Cómo completar la trazabilidad con Codex

Por cada subrequisito implementado, registrar **ruta y símbolo reales** (`archivo:función/clase`), ID de test, resultado, enlace/captura, commit SHA y versión/tag verificados. Si se modifica un RF, actualizar CU y test asociado antes de aceptar el cambio. Evitar registrar paths inventados como si fuesen reales.

**Ejemplo ilustrativo (NO realizado):** `RF03.3 → CU03 → CA03.4/03.5 → AssociationService → test de empate local / candidato externo → evidencia pytest → SHA → tag`.

## Trazabilidad de indicadores

- **OE1:** tiempo y número de interacciones en incorporación manual vs. CU02; meta ≥50 % de reducción.
- **OE2:** tiempo y número de interacciones en rutina manual vs. CU03; meta ≥50 % de reducción.
- **OE3:** recomendaciones pertinentes ≥70 % cuando se implemente CU04.
- **OE4:** tareas completadas sin asistencia ≥80 % con evaluación de usabilidad.

Estos umbrales son **metas, no resultados**. No afirmar mejora cuantitativa sin protocolo, muestra y evidencia.
