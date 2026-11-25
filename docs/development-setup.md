# Preparación y ejecución de desarrollo

Flutter iOS → FastAPI → SQLite. CU01 implementado y probado automáticamente; aspecto aprobado por la persona usuaria en el simulador de iPad; pruebas funcionales manuales aprobadas según la persona usuaria. CU02 está implementado y el recorrido manual en el simulador de iPad fue confirmado por la persona usuaria. CU03 está implementado con Ollama local y creación manual. La persona usuaria confirmó la aprobación de los escenarios de CU03 en el simulador de iPad. La persona usuaria reportó 16 comprobaciones aprobadas de la [Iteración 4 en Device Hub](evidence/iteration-4/manual-check.md). La documentación mantiene su identificación v0.2; el valor de desarrollo `0.0.0` del código no representa una release.

## Estructura

```text
backend/
  scaa_backend/   # configuración, migraciones, perfil, catálogo, rutinas y salud
  tests/         # pruebas de la base técnica
  scripts/       # sondas reales de ARASAAC y Ollama
frontend/        # cliente Flutter con destino iOS
docs/evidence/   # comandos, resultados y limitaciones observadas
```

## Entorno Python

Solo en un checkout nuevo que todavía no tenga `.venv`, desde la raíz del repositorio y con Python 3.13 (verificado con 3.13.7 ARM64):

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r backend/requirements-lock.txt
cp backend/.env.example backend/.env
```

El entorno `.venv` ya existe en este Mac. No volver a crearlo para ejecutar los comandos siguientes. El archivo de versiones fijadas incluye dependencias de desarrollo y pruebas. Para instalar por separado, las dependencias directas están en `requirements.txt` y `requirements-dev.txt`. La reconstrucción desde cero con el archivo de versiones todavía no se ejecutó en una segunda máquina.

## Backend

Desde la raíz:

```sh
.venv/bin/python -m uvicorn scaa_backend.main:app --app-dir backend --env-file backend/.env --host 127.0.0.1 --port 8000
```

Durante la comprobación inicial se utilizó `backend/.env.example` directamente con `--env-file`; no se necesita información secreta. Se comprobó HTTP 200 en `http://127.0.0.1:8000/api/v1/health`, con estado y SQLite disponibles. La API expone GET y PUT `/api/v1/profile` para CU01; Para CU02, las rutas de pictogramas y categorías se describen en el [contrato](evidence/iteration-2/design.md).

`SCAA_ENV` admite `dev`, `test` o `demo`. Bajo `SCAA_DATA_ROOT` se crea un directorio por entorno y una base `scaa.sqlite3` distinta. Por defecto se utiliza `.localdata/` en la raíz. Al iniciar se aplican las migraciones 001 de perfil, 002 de catálogo y 003 de rutinas, según la versión de la base. Las conexiones activan claves foráneas y cierran la transacción con commit o rollback.

Para una configuración de demo, establecer explícitamente `SCAA_ENV=demo`; eso separa sus archivos, pero no certifica una instalación de liberación. Las pruebas utilizan directorios temporales aislados.

```sh
cd backend
../.venv/bin/python -m pytest -q
```

## Flutter

```sh
cd frontend
flutter pub get
flutter analyze
flutter test --reporter expanded
```

Estos tres comandos pasaron en este entorno. Se conserva `pubspec.lock`. El cliente usa `dart:io` para HTTP y tiene destino iOS; no se preparó una versión web.

Con el backend abierto en otra Terminal, desde `frontend`:

```sh
dart run tool/check_backend.dart
```

Esta sonda usa el transporte HTTP compartido y pasó contra el backend real. El recorrido de salud se comprobó en iPad en Iteración 0; CU01 tiene además una sonda HTTP real aislada, descrita más abajo.

Para compilar y ejecutar en el simulador existente desde Terminal normal:

```sh
flutter build ios --simulator --debug --no-codesign
flutter run -d A8EF03DC-81E7-4B9A-AD7E-F9E4235468FC --dart-define=API_BASE_URL=http://localhost:8000
```

La compilación iOS encontró bloqueos de cachés y CoreSimulatorService dentro de la sesión restringida. La persona usuaria ejecutó después `flutter run` desde Terminal normal y confirmó mediante su salida el build y el arranque, junto con HTTP 200 en el backend. Consultar los [resultados](evidence/iteration-0/test-results.md). La persona usuaria confirmó «Servidor disponible» en la pantalla de salud de Iteración 0. La aplicación inicia en visualización. Para configurar el perfil por primera vez, abre «Acceso de administración» y pulsa «Confirmar acceso». Consulta el [recorrido de Iteración 4](evidence/iteration-4/manual-check.md) para validar el incremento.

El identificador `com.example.scaaInteligente` es el valor provisional del generador Flutter; debe definirse el identificador definitivo antes de distribución. Los iconos son los del esqueleto generado, no una identidad gráfica final.

## Conectividad local

Por defecto, el cliente consulta `http://localhost:8000`. En el simulador iOS corresponde al Mac anfitrión. Para otro servidor se utiliza `--dart-define=API_BASE_URL=...`.

En un iPad físico, localhost corresponde al propio iPad. Ese escenario requiere un backend accesible en la red local, la dirección del Mac, confianza/firma y los permisos del dispositivo; no se ha verificado todavía. No utilizar una IP inventada ni exponer el servidor a Internet para resolver esta conexión.

El cliente declara acceso a red local y `NSAllowsLocalNetworking`; no se habilitó una excepción general para todas las conexiones HTTP. El arranque comprobado del backend se limita a `127.0.0.1`.

## Sondas reales de servicios

Con Ollama abierto y el modelo descargado:

```sh
.venv/bin/python backend/scripts/probe_integrations.py --output docs/evidence/otra-ejecucion-integraciones.json
```

Ejecutar desde la raíz; el ejemplo permite elegir un archivo nuevo. La sonda rechaza sobrescribir evidencia existente. `--service arasaac` o `--service ollama` permite comprobar un solo servicio. Carga `backend/.env` si existe, respetando las variables de entorno explícitas.

La ejecución real inicial está en [bootstrap-integrations.json](evidence/iteration-0/integrations/bootstrap-integrations.json): búsqueda ARASAAC y descarga de imagen, más tres generaciones Ollama con validación Pydantic y posiciones consecutivas. Ningún resultado se incorpora al catálogo ni se guarda como rutina aprobada. El modelo es provisional; la evaluación de calidad continúa pendiente.

## Gestión de configuración

`.env`, bases SQLite, cachés, builds, `.venv` y trabajo temporal están excluidos de Git. Los archivos de ejemplo y versiones quedan disponibles para revisión. La preparación no modifica el alcance del SRS ni crea tags o releases.

## Cierre de Iteración 0

La persona usuaria cerró funcionalmente la preparación técnica tras confirmar «Servidor disponible» en el iPad. Las [evidencias de Iteración 0](evidence/iteration-0/README.md) organizan versiones, comandos, pruebas y limitaciones por alcance y commit asociado.

## Comprobar CU01 sin modificar el perfil real

Desde la raíz:

```sh
.venv/bin/python backend/scripts/run_profile_probe.py --output docs/evidence/iteration-1/cu01/otra-sonda-http.json
```

El ejecutor crea un backend de prueba y datos temporales aislados, usa el cliente Dart real y detiene su propio proceso al terminar. No modifica el perfil dev/demo ni el backend que la persona usuaria tenga abierto. Rechaza sobrescribir resultados anteriores.

Para probar manualmente CU01, reiniciar el backend anterior y realizar hot restart (`R`) en la Terminal de Flutter. Seguir la [lista de aceptación manual](evidence/iteration-1/manual-check.md). Las versiones de dependencias no cambiaron respecto a Iteración 0.

Para el selector nativo de archivos y el recorrido de CU02, consultar la [lista de iPad](evidence/iteration-2/manual-check.md). Es necesario volver a ejecutar Flutter con el plugin instalado.

## Ejecutar CU03

Configurar `OLLAMA_BASE_URL` con una dirección local de loopback. `OLLAMA_MODEL` selecciona el modelo y `OLLAMA_TIMEOUT` admite entre 1 y 120 segundos para la respuesta de inferencia. Usar el modelo provisional disponible `qwen2.5:1.5b` o uno configurado y verificado por el equipo. Arrancar Ollama en Terminal del sistema si no está en ejecución. La migración 003 se aplica al reiniciar FastAPI. La opción manual funciona también cuando el servicio de IA está caído.

Desde la raíz, la sonda usa un proceso HTTP y una base aislados:

```sh
.venv/bin/python backend/scripts/run_profile_probe.py --flow routine --output work/cu03/http-reproduccion.json
```

La revisión de la UI se realiza con el [protocolo del simulador](evidence/iteration-3/manual-check.md).

## Perfil provisional de generación para validación

Con Ollama en ejecución y `qwen3:4b-instruct` instalado, inicia otro backend en un entorno aislado. Este comando selecciona una sola inferencia con el prompt alternativo del laboratorio.

```sh
SCAA_ENV=demo SCAA_DATA_ROOT="$(mktemp -d)" \
  OLLAMA_MODEL=qwen3:4b-instruct OLLAMA_PROMPT_PROFILE=alternate \
  .venv/bin/python -m uvicorn scaa_backend.main:app --app-dir backend \
  --env-file backend/.env.example --host 127.0.0.1 --port 8015
```

Para probarlo en el simulador, inicia Flutter con `--dart-define=API_BASE_URL=http://localhost:8015` y configura un perfil de prueba. Para volver a la línea base, inicia el backend con `OLLAMA_MODEL=qwen2.5:1.5b` y `OLLAMA_PROMPT_PROFILE=baseline`. Ambas son las opciones predeterminadas. Consulta el [diagnóstico de generación](evidence/iteration-4/generation-quality.md) para conocer los resultados y límites del ensayo.

### Ensayo opcional con hasta cuatro pasos y filtro de ARASAAC

Para repetir la validación con propuestas breves en el puerto `8015`, detén el backend de prueba y arráncalo desde la raíz:

```sh
SCAA_ENV=demo SCAA_DATA_ROOT="$(mktemp -d)" \
  OLLAMA_MODEL=qwen3:4b-instruct OLLAMA_PROMPT_PROFILE=concise \
  SCAA_ROUTINE_EXTERNAL_MATCH=contextual \
  .venv/bin/python -m uvicorn scaa_backend.main:app --app-dir backend \
  --env-file backend/.env.example --host 127.0.0.1 --port 8015
```

Reutiliza la ejecución de Flutter apuntada a `http://localhost:8015` y configura un alias de prueba si usas un directorio temporal nuevo. Para comparar solo la longitud, usa `SCAA_ROUTINE_EXTERNAL_MATCH=provider`. Para volver a la configuración del ensayo anterior, usa `OLLAMA_PROMPT_PROFILE=alternate` y `SCAA_ROUTINE_EXTERNAL_MATCH=provider`. Los [resultados de propuestas breves](evidence/iteration-4/concise-routines.md) detallan las omisiones y los pasos que quedaron pendientes de imagen.
