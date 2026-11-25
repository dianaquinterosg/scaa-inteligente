# Iteración 4 · Propuestas de tres a cinco pasos y revisión de candidatos

El perfil `linguistic` incorpora los ejemplos de higiene propuestos por la persona usuaria. El esquema y Pydantic exigen de tres a cinco pasos en las propuestas automáticas. El editor y almacenamiento de rutinas conservan el máximo de doce.

Se conserva la consulta literal a ARASAAC y la prioridad local. Se sugiere el primer resultado si su etiqueta coincide literalmente. Si difiere, se examinan los resultados siguientes del proveedor en el mismo orden. Sus etiquetas y palabras clave se cotejan conservando el verbo y las preposiciones. Si falta una coincidencia, se deja pendiente la selección manual. La confirmación humana se conserva.

## Sonda con Ollama y ARASAAC reales

| Rutina | Resultado | Pasos | Respuesta HTTP |
|---|---|---:|---:|
| Lavarse las manos | 200 | 3 | 9,08 s |
| Cepillarse los dientes | 200 | 4 | 7,32 s |
| Prepararse para dormir | 200 | 3 | 4,40 s |
| Ir al baño | 200 | 4 | 6,40 s |
| Guardar los juguetes | 502. Pydantic rechazó «cierra la caja» por estar conjugado. | — | 4,02 s |

Se sugirieron doce pictogramas para catorce pasos. Quedaron pendientes «poner el pijama» y «levantar el váter». Para «echar el jabón» se descartó «burbuja» y se encontró «echar jabón» (37409). Para «echar la pasta de dientes» se descartó «ensalada de pasta» y se encontró «echar pasta de dientes» (30087). La pertinencia visual y la calidad semántica requieren revisión humana.

Pasaron 135 pruebas de backend. El [registro JSON](routine-label-fallback.json) conserva las consultas, etiquetas, sugerencias originales, resoluciones y latencias. El [ensayo anterior](linguistic-routines.md) guarda los resultados obtenidos con la política anterior y el máximo de cuatro pasos.
