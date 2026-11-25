# Iteración 4 · Ensayo lingüístico de rutinas

Se ejecutó una propuesta por rutina mediante Uvicorn HTTP local, con SQLite aislado, catálogo aprobado vacío, Ollama real y ARASAAC real. Ollama 0.40.17 confirmó `qwen3:4b-instruct` residente antes de las llamadas. El perfil pidió `keep_alive: 10m`, temperatura 0, un máximo estructural de cuatro pasos y una sola inferencia. El hash del prompt, digest, respuestas textuales, resultados de pruebas preliminares y tiempos por consulta están en el [registro JSON](linguistic-routines.json).

## Latencia observada

| Rutina | Inferencia | Catálogo local | ARASAAC | Asociación sin búsqueda (aprox.) | Asociación total | HTTP total | Tokens generados |
|---|---:|---:|---:|---:|---:|---:|---:|
| Lavarse las manos | 10,72 s | 0,0017 s | 1,85 s | 0,0013 s | 1,85 s | 12,58 s | 23 |
| Cepillarse los dientes | 1,88 s | 0,0011 s | 1,07 s | 0,0009 s | 1,07 s | 2,96 s | 28 |
| Prepararse para dormir | 3,40 s | 0,0014 s | 1,64 s | 0,0026 s | 1,64 s | 5,05 s | 56 |
| Ir al baño | 2,69 s | 0,0011 s | 1,01 s | 0,0000 s | 1,01 s | 3,71 s | 43 |
| Guardar los juguetes | 1,96 s | 0,0014 s | 1,06 s | 0,0006 s | 1,07 s | 3,03 s | 26 |

La mediana HTTP fue 3,71 s. Cuatro de las cinco peticiones bajaron de diez segundos. La petición de lavado de manos superó el objetivo pese a tener el modelo residente. La medición abarca inferencia, acceso a SQLite, búsquedas y respuesta HTTP. ARASAAC se mide desde la primera consulta hasta que termina la última, porque se ejecutan con concurrencia. La asociación total incluye catálogo y ARASAAC. La cifra sin búsqueda es la diferencia entre los componentes redondeados del registro. La carga de imágenes en el cliente se mide aparte en una futura prueba manual.

## Etiquetas, consultas y sugerencias

### Lavarse las manos

La consulta coincide con una palabra clave del primer pictograma. La rutina repite la tarea en un único paso y omite acciones como enjuagar y secar.

| Paso | Etiqueta | Consulta exacta | Sugerencia de ARASAAC | Palabras clave |
|---:|---|---|---|---|
| 1 | lavar las manos | lavar las manos | [8975](https://static.arasaac.org/pictograms/8975/8975_300.png) · lavar las manos | lavar las manos, lavado de manos |

### Cepillarse los dientes

El primer resultado contiene la etiqueta exacta entre sus palabras clave. Quedaron fuera la preparación del cepillo con pasta y el escupido.

| Paso | Etiqueta | Consulta exacta | Sugerencia de ARASAAC | Palabras clave |
|---:|---|---|---|---|
| 1 | cepillar los dientes | cepillar los dientes | [2326](https://static.arasaac.org/pictograms/2326/2326_300.png) · cepillar los dientes | cepillar los dientes |

### Prepararse para dormir

En la secuencia, «acostar» antecede a «vestir el pijama». Para «ir al baño», ARASAAC sugirió «quedarse solo».

| Paso | Etiqueta | Consulta exacta | Sugerencia de ARASAAC | Palabras clave |
|---:|---|---|---|---|
| 1 | acostar | acostar | [6027](https://static.arasaac.org/pictograms/6027/6027_300.png) · acostar | acostar |
| 2 | vestir el pijama | vestir el pijama | [2781](https://static.arasaac.org/pictograms/2781/2781_300.png) · vestir | vestir |
| 3 | ir al baño | ir al baño | [27541](https://static.arasaac.org/pictograms/27541/27541_300.png) · quedarse solo | quedarse solo, quedarse solo en el baño |
| 4 | dormir | dormir | [6479](https://static.arasaac.org/pictograms/6479/6479_300.png) · dormir | dormir |

### Ir al baño

Se generaron tres acciones y se conservó la expresión «sentar en el váter». Faltaron la descarga y el lavado de manos.

| Paso | Etiqueta | Consulta exacta | Sugerencia de ARASAAC | Palabras clave |
|---:|---|---|---|---|
| 1 | sentar en el váter | sentar en el váter | [10177](https://static.arasaac.org/pictograms/10177/10177_300.png) · sentar en el váter | sentar en el váter |
| 2 | orinar | orinar | [16713](https://static.arasaac.org/pictograms/16713/16713_300.png) · hacer pis | hacer pis, orinar, pis, pipí, hacer pipí |
| 3 | defecar | defecar | [39599](https://static.arasaac.org/pictograms/39599/39599_300.png) · defecar | defecar, cagar |

### Guardar los juguetes

La única etiqueta repite la tarea. El primer resultado se describe como «saco de juguetes».

| Paso | Etiqueta | Consulta exacta | Sugerencia de ARASAAC | Palabras clave |
|---:|---|---|---|---|
| 1 | guardar los juguetes | guardar los juguetes | [11363](https://static.arasaac.org/pictograms/11363/11363_300.png) · saco de juguetes | saco de juguetes |

## Verificación y límites

- Pydantic aceptó las cinco secuencias finales. Se confirmó el orden consecutivo, el rango 1–4 y la igualdad de etiqueta, término y consulta para todos los pasos de la sonda. El control automático verifica la estructura y las formas lingüísticas codificadas. El vocabulario y la calidad semántica se revisan por separado.
- Las consultas de los ejemplos muestran que los artículos y preposiciones se conservaron y que el primer resultado puede describir otra situación.
- Las pruebas controladas verificaron prioridad local, reutilización de consultas idénticas, primera sugerencia, búsqueda vacía, aprobación humana y creación y edición manual de doce pasos.
- La regresión terminó con 129 pruebas de backend y 36 de Flutter aprobadas. `flutter analyze` quedó sin incidencias.
- La lectura técnica encontró omisiones y problemas de orden. La pertinencia visual queda pendiente de revisión manual.

## Reproducción

```sh
PYTHONPATH=backend .venv/bin/python backend/scripts/probe_linguistic_routines.py /tmp/scaa-linguistic-results.json
```

Pictogramas de Sergio Palao, Gobierno de Aragón, ARASAAC, CC BY-NC-SA.
