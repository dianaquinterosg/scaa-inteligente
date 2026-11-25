# Iteración 4 · Diagnóstico de generación de rutinas

## Configuración y regresión investigada

Se compararon `c86a635` (antes de Iteración 4) y `be7d359`. La comparación incluyó el envío de la descripción desde Flutter, la ruta de propuestas, el filtro de contexto confirmado, el prompt, las opciones de Ollama, el esquema Pydantic y la interpretación del resultado. No se encontró un cambio en ese recorrido. El cambio de FastAPI en ese intervalo se limitó al formato del error de catálogo.

El backend de demostración en `127.0.0.1:8014` respondió con SQLite disponible. Una propuesta sintética con contexto efectivo vacío obtuvo HTTP 200. Antes de la petición Ollama estaba sin modelos residentes. Después apareció `qwen2.5:1.5b` con contexto efectivo de 4096 y el mismo digest que figura en las [evidencias de Iteración 3](../iteration-3/results.md). Ollama respondió en loopback, versión `0.40.17`. La consulta del entorno del proceso activo quedó bloqueada por el sandbox. El timeout de ese proceso se desconoce. La sonda aislada reprodujo las opciones y el prompt predeterminados del código que ejecutaba esa versión.

Al pedir ordenar un escritorio, la API activa devolvió doce veces «estirar la sábana». La petición completa tardó 12,84 s e incluyó la asociación vigente. El backend aislado reprodujo esa salida con el mismo modelo y la línea base. La frase coincide con el ejemplo del prompt. Esa coincidencia documenta el fallo observado y queda abierta su atribución entre modelo y prompt. La evidencia disponible no demuestra que los cambios de usabilidad hayan causado una regresión.

## Casos reservados y comparación controlada

La sonda ejecutó la ruta de propuestas del producto con SQLite temporal y Ollama real. La asociación siguió su código habitual con un adaptador ARASAAC de prueba sin resultados, para aislar la generación. Las propuestas no produjeron escrituras en el catálogo ni en las rutinas.

| Caso | Línea base `qwen2.5:1.5b` | Candidato `qwen3:4b-instruct` | Inferencia base / candidato | Coincidencia del candidato con el laboratorio |
|---|---|---|---|---|
| Llenar y cerrar una botella con agua fría | Menciona agua fría y cierre, pero omite abrir y repite la idea de llenado. | Abre, llena con agua fría y cierra. Utilizable en la revisión técnica. | 5,33 / 11,87 s | Exacta |
| Preparar dos libros para devolverlos | Propone encuadernarlos y alinearlos. Desvío sustantivo. | Extiende la tarea hasta devolverlos en la biblioteca y no explicita la cantidad de dos. Desvío sustantivo. | 2,63 / 16,74 s | Exacta |
| Ordenar un escritorio con el cuaderno abierto | Repite «estirar la sábana» doce veces. Desvío sustantivo. | Organiza objetos y abre el cuaderno. Falta indicar con claridad que se libera el espacio. Requiere corrección. | 11,37 / 13,74 s | Exacta |

Los seis resultados superaron estructura y posiciones consecutivas. Las tres salidas candidatas validadas por el backend coincidieron exactamente con las tres guardadas en el laboratorio. Las latencias corresponden al tiempo de pared de cada llamada a Ollama. La primera llamada de cada grupo incluye carga del modelo y el JSON registra ese componente por separado. La revisión de esta tabla es técnica. La calificación humana de los casos reservados sigue pendiente.

Ambos modelos usaron cuantización Q4_K_M, una inferencia por propuesta, temperatura 0, límite de 800 tokens, timeout de 60 s y el mismo JSON Schema. Se omitieron semilla y modo de razonamiento explícitos, igual que en la configuración seleccionada del laboratorio. El candidato usa el [prompt alternativo exacto](../../../backend/scaa_backend/routine-alternate.txt), con SHA-256 `c5afb881834bf68a805610787a06db74d2afaec03cab00eca8444950f8f43873`. Los digests de los modelos, respuestas y latencias están en el [registro JSON](generation-quality.json).

## Decisión

El candidato queda disponible como opción local provisional. Produjo una secuencia utilizable de tres según la revisión técnica y conserva un desvío sustantivo. La línea base permanece como predeterminada y el cambio de perfil se realiza mediante configuración. La edición y la aprobación humana son obligatorias para guardar. El algoritmo de asociación conserva su configuración vigente.

Reproducción desde la raíz con Ollama y los registros reservados del laboratorio disponibles:

```sh
PYTHONPATH=backend .venv/bin/python backend/scripts/probe_routine_variants.py \
  ../scaa-ai-lab /tmp/scaa-routine-variants.json
.venv/bin/python -m pytest backend -q
```

La regresión backend terminó con 96 pruebas aprobadas.
