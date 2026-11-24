# Iteración 0 — pruebas y verificaciones

**Commit asociado:** commit de cierre indicado en [README](README.md).

| Prueba | Funcionalidad / alcance | Resultado real | Evidencia |
|---|---|---|---|
| I0-BE | Infraestructura FastAPI/SQLite | 6 aprobadas, una advertencia Starlette/HTTPX | [Resumen](backend/bootstrap-backend-tests.json) |
| I0-FE | Carga y reintento del cliente | 2 aprobadas | [Flutter](flutter/bootstrap-flutter-test.log) |
| I0-AN | Análisis Dart | Sin incidencias | [Análisis](flutter/bootstrap-flutter-analyze.log) |
| I0-HTTP | Dart → FastAPI → SQLite | Comprobación real satisfactoria | [Dart](flutter/bootstrap-dart-backend-http.log), [HTTP 200](backend/bootstrap-backend-http.json) |
| I0-AR | Servicio ARASAAC | Consulta HTTP 200; 54 alternativas; imagen PNG de 5566 bytes | [Resultados](integrations/bootstrap-integrations.json) |
| I0-IA | Modelo local Ollama | Tres JSON válidos, posiciones consecutivas; sin aprobación de contenido | [Resultados](integrations/bootstrap-integrations.json) |
| I0-IPAD | Compilación y ejecución en iPad | Build y arranque compartidos por la persona usuaria; mensaje «Servidor disponible» confirmado | [Evidencia](flutter/bootstrap-ipad-run-user.json) |

## Comandos reproducibles

```sh
cd backend
../.venv/bin/python -m pytest -q
```

```sh
cd frontend
flutter analyze
flutter test --reporter expanded
dart run tool/check_backend.dart
```

Desde la raíz, con Ollama activo:

```sh
.venv/bin/python backend/scripts/probe_integrations.py --output docs/evidence/iteration-0/integrations/nueva-ejecucion.json
```

La sonda no sobrescribe evidencia. No ejecutarla solo para reproducir el cierre si los servicios no están disponibles.

## Límites y desviaciones

- La suite de widgets usa respuestas controladas; las sondas HTTP y de servicios se ejecutaron por separado con servicios reales.
- El build iOS falló dentro de la sesión restringida por cachés y CoreSimulatorService. La persona usuaria lo ejecutó satisfactoriamente desde Terminal normal; la evidencia identifica esa procedencia. No se recibió captura.
- El modelo provisional produce resultados poco específicos: añadió ropa interior a una mochila y una toalla al poner la mesa. JSON válido no implica pertinencia; no se eligió un modelo definitivo.
- Starlette advierte sobre deprecación de HTTPX con TestClient; las pruebas pasaron y no se ocultó el aviso.
- No se ejecutaron los recorridos funcionales T01–T07 ni T09–T16. T08 tiene evidencia de sonda técnica, no de integración completa de CU03.
- No se midieron OE1–OE4 ni se validó un iPad físico.
