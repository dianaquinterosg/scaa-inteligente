# Iteración 4 · Cierre de v0.3.0

El incremento consolida los refinamientos de CU01–CU03 y la visualización básica de contenido aprobado como avance parcial de CU05. La [línea base de requisitos](../../SRS.md) se conserva en v0.2.

| Alcance | Resultado y evidencia |
|---|---|
| Visualización y administración · RF-I4.1–RF-I4.3 / CA-I4.1–CA-I4.3 | Bienvenida adaptada a tablet, inicio en visualización, acceso deliberado a los editores, catálogo por categoría y visor horizontal. [Diseño y pruebas de la bienvenida](welcome.md) |
| Integridad del catálogo · RF-I4.4 / CA-I4.4–CA-I4.5 | El conflicto HTTP 409 identifica las rutinas que usan el pictograma y SQLite protege sus referencias. [Prueba HTTP con dependencias](conflict-http.json) |
| Generación · RF-I4.5 / CA-I4.6 | Una inferencia de Qwen3 4B Instruct con el perfil `linguistic` genera entre tres y cinco pasos. El backend copia la etiqueta al término de búsqueda y el editor manual admite doce pasos. [Límites y resultados](routine-label-fallback.md) |
| Asociación · RF-I4.6 / CA-I4.7–CA-I4.8 | Prioridad local, consulta literal a ARASAAC, cotejo del primer resultado y revisión de candidatos siguientes cuando difiere. Se mantienen selección manual y aprobación humana. [Resultados y latencias](routine-label-fallback.json) |

## Verificación de la liberación

| Comprobación | Resultado |
|---|---|
| Backend · `.venv/bin/python -m pytest backend -q` | 135 aprobadas |
| Flutter · `flutter test --no-pub --reporter expanded` | 36 aprobadas |
| Flutter · `flutter analyze --no-pub` | Sin incidencias |
| Configuración demo | Arranque HTTP 200, FastAPI v0.3.0 y SQLite con esquema 3 en almacenamiento aislado. Perfil `linguistic` y modelo `qwen3:4b-instruct` comprobados. |
| Validación final en Device Hub | Aprobada por la persona usuaria. [Registro manual](manual-check.md) |

La [regresión de cierre](release-regression.json) registra los resultados y el [instructivo](../../development-setup.md#demo-v030-en-el-simulador-de-ipad) describe la configuración validada. La instalación en iPad físico pasa a la siguiente iteración.

## Evidencias de evolución

- [Diagnóstico de generación y casos reservados](generation-quality.md).
- [Propuestas breves y filtro contextual](concise-routines.md).
- [Ensayo de etiquetas exactas y primera sugerencia](linguistic-routines.md).
- [Rango definitivo y revisión de candidatos siguientes](routine-label-fallback.md).

Las notas de v0.3.0 registran el alcance, los requisitos de ejecución y el trabajo futuro. [Notas de la versión](../../releases/v0.3.0.md)
