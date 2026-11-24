# Iteración 3 — CU03, gestión de rutinas inteligentes

CU03 cuenta con pruebas de backend, widgets e integración HTTP con Ollama y ARASAAC reales. El modelo sigue siendo provisional. Quedan pendientes la revisión manual de CU03 en el simulador y la verificación integrada T16.

| Unidad | Commit | Alcance |
|---|---|---|
| Alineación documental previa | `2ebc9d9` | Estados y contratos CU01/CU02 |
| Modelo y migración SQLite | `49e61e2` | Rutinas y pasos, posiciones únicas y referencias restrictivas |
| Unidad de trabajo de catálogo | `62a3e80` | Inserción en la transacción del llamador y compensación de archivos |
| Generación y asociación | `7456158`, `51c191b` | Esquema, contexto, ranking y refinamiento de instrucciones |
| Confirmación y administración | `7c588ac` | API, persistencia de rutinas y pruebas de transacción |
| Revisión en Flutter | `0212ce4` | Crear, corregir, aprobar, consultar y eliminar |
| Integración real reproducible | `c3ad225` | Dart → FastAPI → Ollama/ARASAAC → SQLite y archivos |

[Diseño y contratos](design.md) · [Cobertura y resultados](results.md) · [Resultados por caso](results.json) · [Validación manual en iPad](manual-check.md).
