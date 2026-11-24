# Iteración 3 — Diseño y contratos de CU03

La [línea base SRS v0.2](../../SRS.md) define RF03.1–RF03.8. El [caso de uso](../../use-cases.md) conserva CA03.1–CA03.15. El [diagrama de secuencia](../../diagrams/cu03-sequence.puml) muestra generación, revisión y guardado. La pantalla usa los componentes compartidos del [diseño visual inicial](../../design/README.md).

| Responsabilidad | Componente encargado |
|---|---|
| Solicitar propuesta e interpretar la respuesta | `OllamaGenerator`, `GeneratedRoutine`, `GeneratedStep` |
| Obtener contexto confirmado | `ProfileRepository.load` y `relevant_context` |
| Buscar y priorizar pictogramas | `associate`, `best_local`, `Catalog.list` y `ArasaacClient.search` |
| Reglas de aprobación y coordinación | `RoutineApproval`, `ApprovedStep` y `routine_api` |
| Guardado y recuperación | `RoutineRepository`, migración 003 y unidad de trabajo de `Catalog` |
| Presentación y corrección | `RoutinesScreen`, `RoutineEditor`, `RoutinePictograms` y `RoutineApi` |

## Generación y contexto

`POST /api/v1/routines/proposals` carga el perfil persistido. Se excluye el alias y se seleccionan hasta dos elementos por grupo cuando comparten términos relevantes con la descripción. La selección es textual y puede omitir relaciones semánticas. La petición al servicio Ollama se limita a loopback. Solo incluye descripción y contexto pertinente y el modelo no recibe herramientas para escribir datos.

El adaptador usa `POST /api/chat` con `stream: false` y un JSON Schema en `format`. Pydantic valida estrictamente nombre, tipos, campos y posiciones consecutivas. Límites del piloto: descripción de hasta 500 caracteres, nombre/etiqueta/término de hasta 100 caracteres, y entre 1 y 12 pasos. Los mensajes de indisponibilidad, salida inválida y timeout ofrecen el editor manual. [Contrato de salida estructurada de Ollama](https://docs.ollama.com/capabilities/structured-outputs).

## Asociación y aprobación

La comparación normaliza espacios, mayúsculas y diacríticos. Aplica exacta, prefijo e inclusión, en orden. El empate en el nivel más alto conserva las alternativas locales sin preselección. Cada término remoto normalizado se consulta una vez por propuesta y hasta tres consultas se ejecutan en paralelo. Una falla externa queda asociada al paso y conserva los demás resultados.

La primera alternativa externa se muestra como candidato revisable. El usuario puede aprobarla, elegir otra, buscar o abrir CU02 para incorporar una imagen propia. Los candidatos marcados individualmente en CU03 se guardan solo al confirmar la rutina. La incorporación independiente en CU02 se confirma dentro de ese flujo y se conserva si se cancela CU03.

## Persistencia y transacción

Las consultas de IA, las búsquedas externas y la descarga y validación de imágenes se completan antes de abrir la unidad de escritura. En SQLite, `BEGIN IMMEDIATE` serializa la incorporación de referencias externas. `Catalog.insert` usa la conexión del llamador, escribe el archivo administrado y registra su ruta para compensación. `RoutineRepository.save` agrega o actualiza la rutina, reutiliza referencias externas ya guardadas e inserta los pasos. Un fallo revierte la base y elimina los archivos nuevos. La reconciliación existente de catálogo recupera restos gestionados tras una interrupción.

Las posiciones son únicas por rutina y las respuestas las devuelven ordenadas. Se puede usar el mismo pictograma en varios pasos y rutinas. La FK de paso restringe el borrado del pictograma. Al borrar una rutina, SQLite borra sus pasos en cascada y deja intacto el catálogo.

## Contrato REST

| Método y ruta | Entrada y resultado |
|---|---|
| POST `/api/v1/routines/proposals` | `description`. Devuelve 200 con `name`, `description` y pasos con `order`, `label`, `search_term`, `association`, `candidates`, `selected` y `approved: false`. |
| GET `/api/v1/routines` | Lista rutinas confirmadas con su ID, nombre, descripción y pasos. |
| POST `/api/v1/routines` | Guarda con confirmación explícita. Devuelve 201 y la rutina persistida. |
| GET `/api/v1/routines/{id}` | Recupera la rutina y los pictogramas confirmados por paso. |
| PUT `/api/v1/routines/{id}` | Reemplaza nombre, descripción y pasos con las mismas validaciones de creación. Devuelve 200. |
| DELETE `/api/v1/routines/{id}` | Elimina rutina y pasos. Devuelve 204. |

Para guardar, enviar `name`, `description` opcional, `confirmed: true` y `steps` en posiciones consecutivas desde 1. Cada paso incluye `order`, `label`, `approved: true` y `pictogram_id` local o `external_id` con `pictogram_label`. Se exige un perfil confirmado. Los errores de entrada devuelven 422, los recursos ausentes 404 y la falta de perfil o un conflicto 409. Ollama devuelve fallo controlado a través de 502, 503 o 504 según el caso. El cliente valida asimismo el orden que devuelve la API.

## Interfaz

Inicio enlaza con Rutinas. La entrada muestra descripción escrita, generar y crear manualmente. El editor mantiene un ancho de lectura limitado, tarjetas ordenadas y acciones alcanzables por desplazamiento. Reusa paneles informativos, botones de confirmación y etiquetas de accesibilidad. Las flechas con nombre de paso ofrecen una alternativa táctil directa para reordenar. Un diálogo confirma el guardado y el estado del borrador se conserva ante error. El mockup inspira la composición; voz y otros módulos quedan para su alcance previsto.
