# Iteración 1 — resultados y evidencias para AINC422

**Funcionalidad:** CU01. **Commit base:** `db312e3592648a3b620d66b2ea22af018396112e`. **Commits asociados:** API `89647a9`, widgets `f81d180`, integración `854180f`.

## Pruebas ejecutadas

| Prueba | Alcance | Resultado real | Evidencia |
|---|---|---|---|
| I1-BE | API, normalización, límites, duplicados, persistencia y migraciones | 45 aprobadas, incluida regresión de infraestructura | [Casos y resultados](cu01/backend-tests.json) |
| I1-FE | Primer uso, tres tipos, edición/borrado, cancelación, límites, errores y reintento | 15 aprobadas: 13 de CU01 y 2 de regresión de conexión | [Casos y resultados](cu01/flutter-tests.json) |
| I1-HTTP | Cliente Dart real → FastAPI → SQLite aislado | 7 escenarios aprobados; creación, recuperación, edición y rechazo sin pérdida de estado | [Resultados](cu01/live-http.json) |
| I1-AN | Análisis del cliente | Sin incidencias | [Resultado](cu01/analyze.json) |

## Cobertura de criterios

| Criterio | Comportamiento | Resultado | Nivel probado |
|---|---|---|---|
| CA01.1 | Crear perfil con alias válido | Aprobado automáticamente | API y widgets + HTTP real |
| CA01.2 | Elementos individuales de los tres tipos | Aprobado automáticamente | API y widgets + HTTP real |
| CA01.3 | Editar y eliminar elementos | Aprobado automáticamente | API y widgets + HTTP real |
| CA01.4 | Bloquear alias vacío | Aprobado automáticamente | API y widgets |
| CA01.5 | Rechazar elementos vacíos o duplicados por tipo | Aprobado automáticamente | API y widgets + HTTP real |
| CA01.6 | Normalizar espacios externos | Aprobado automáticamente | API y widgets + HTTP real |
| CA01.7 | Límite de 50 caracteres | Aprobado automáticamente | API y widgets |
| CA01.8 | Persistir y recuperar el perfil | Aprobado automáticamente | API y widgets + HTTP real |
| CA01.9 | Fallo de guardado sin reemplazar datos anteriores | Aprobado automáticamente | API y widgets |
| CA01.10 | Solo contexto confirmado disponible | Aprobado automáticamente | API y widgets + HTTP real |

Las asociaciones concretas entre criterio y nombre de prueba están en [acceptance.json](cu01/acceptance.json). No se afirma aceptación manual en iPad ni se convierten las pruebas con almacén controlado en pruebas de servidor real.

## Fallos controlados y desviaciones

- El rollback se comprobó con un trigger SQLite que aborta una inserción después de actualizar el alias y eliminar el contexto anterior. La respuesta fue 503 y la lectura mantuvo exactamente el perfil confirmado previo.
- El editor conserva el borrador ante errores y permite reintentar. Se verificó también que el error sea visible cuando se guarda desde el final de un formulario desplazado.
- Una prueba del formulario desplazado inicialmente buscaba un widget aún no construido por ListView. Se corrigió la sonda para desplazar la lista hasta construirlo; se conserva el [resultado de esa incidencia](cu01/flutter-scroll-issue.json) y el resultado final aprobado por separado.
- La primera sonda de entrada Unicode inválida fue rechazada por la codificación del cliente de pruebas antes de llegar al servidor. Se utilizó un cuerpo JSON escapado para comprobar realmente el rechazo de la API, evitando reflejar datos de entrada en el error.
- Se corrigieron avisos de llaves del análisis Dart. El análisis final pasó.
- Persiste la advertencia de deprecación HTTPX/Starlette ya detectada en Iteración 0; no impidió las pruebas y no se ocultó.
- No se agregaron dependencias globales, funciones P2 ni cambios de alcance. SQL directo y migraciones numeradas concretan la decisión técnica pendiente de persistencia dentro del stack acordado.

## Pendientes y límites

La persona usuaria aprobó el aspecto de CU01 en el simulador de iPad. Los escenarios funcionales de la lista manual siguen pendientes porque no se reportaron resultados individuales.

El consumo del perfil confirmado por la personalización IA será probado al integrar CU03. No se midieron indicadores académicos, no se ejecutó el recorrido T16 y no se avanzó a CU02. La implementación de CU01 está versionada localmente.

La [regresión del incremento visual](visual.md) conserva por separado los resultados de las pruebas sobre `bca2e58`, incluida la comprobación de los enlaces entre criterios y pruebas.
