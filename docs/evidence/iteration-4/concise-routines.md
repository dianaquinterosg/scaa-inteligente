# Iteración 4 · Propuestas breves y búsqueda contextual

La persona usuaria reportó esperas superiores a 20 s en Device Hub y pictogramas que no correspondían al paso. Los ejemplos incluyeron una imagen de cabello mojado para lavarse las manos y una imagen de los pies en la mesa para un paso de cepillado. La validación local usó las cinco descripciones cotidianas indicadas, un perfil sintético, el catálogo local vacío, Ollama real y ARASAAC real.

## Prueba de generación

El perfil `concise` solicita etiquetas breves, términos con acción y objeto y un máximo de cuatro pasos. El JSON Schema y Pydantic aplican ese máximo a la propuesta asistida. El editor y la API de rutinas guardadas conservan el límite de 12. Se usa el mismo modelo `qwen3:4b-instruct`, una sola inferencia y la misma temperatura y presupuesto de salida.

| Descripción | Pasos anterior / breve | Respuesta backend anterior / breve | Sugerencias textuales con filtro |
|---|---:|---:|---:|
| Lavarse las manos | 6 / 4 | 17,47 / 13,02 s | 0 |
| Cepillarse los dientes | 5 / 3 | 15,07 / 7,75 s | 2 |
| Prepararse para dormir | 5 / 4 | 13,10 / 11,02 s | 4 |
| Ir al baño | 5 / 4 | 13,38 / 9,45 s | 2 |
| Guardar los juguetes | 5 / 4 | 14,77 / 9,47 s | 0 |

La mediana de respuesta del backend fue 14,77 s con el perfil anterior y 9,47 s con la variante breve final. Estas mediciones terminan al entregar la propuesta HTTP. Excluyen la descarga de imágenes en Flutter. La sonda no reprodujo la espera superior a 20 s reportada en Device Hub. El [registro de resultados](concise-routines.json) separa inferencia y trabajo posterior, y conserva una prueba intermedia de generación breve con la política anterior de asociación.

## Prueba de asociación

La opción `contextual` filtra la misma respuesta de ARASAAC antes de preseleccionar. Exige que una etiqueta o palabra clave contenga la misma combinación de palabras relevantes de la consulta. Se conserva la prioridad del catálogo local. Si faltan coincidencias textuales, el editor deja el paso pendiente para selección manual.

Al comparar ambas políticas sobre la misma respuesta real de ARASAAC, «colocar cepillo» pasó de «colocar los pies en la mesa» a «poner el cepillo». «Cepillar dientes» pasó de «limpiar el cepillo de dientes» a «cepillar los dientes». «Mojar manos» quedó pendiente porque el catálogo consultado solo devolvió candidatos sin coincidencia suficiente. Esto verifica el criterio textual. La pertinencia visual se revisa en el editor.

## Límites y estado

La variante breve omitió el secado en lavado de manos e incluyó «enjuagar boca» en «Ir al baño». Una imagen puede coincidir con un paso que el propio modelo produjo fuera de la tarea. De 19 pasos, 8 recibieron sugerencias textuales y 11 quedaron pendientes. La aprobación humana sigue siendo obligatoria. La combinación es provisional y la revisión en Device Hub queda pendiente.

Las dos opciones se activan por separado. El perfil de generación y la política de asociación predeterminados conservan sus valores. Las pruebas de backend cubren los límites 4/12 y la exclusión de candidatos ajenos en los casos reportados. La regresión de Flutter y su análisis estático se ejecutaron sobre el cliente vigente.
