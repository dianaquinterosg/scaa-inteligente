# Iteración 3 — Resultados de pruebas y evidencias de CU03

| Alcance planificado | Alcance implementado | Verificación |
|---|---|---|
| Propuesta real con contexto confirmado | Ollama local con JSON Schema y Pydantic. Filtrado por términos y omisión de alias | Tres escenarios reales. Prueba controlada inspecciona la solicitud al proveedor y descarta una edición de perfil no confirmada |
| Asociación automática revisable | Exacta, prefijo, inclusión, empate sin elección y candidatos ARASAAC | Ranking, deduplicación y fallo parcial con pruebas controladas. Servicio ARASAAC real en la sonda HTTP |
| Edición y creación manual | Editor Flutter con revisión por paso, reemplazo, reordenamiento y confirmación | Widgets y API controlada. Timeout, formato inválido e indisponibilidad permiten seguir manualmente |
| Transacción y administración | Guardado atómico, recuperación, edición, eliminación y reutilización | Rollback inyectado después de escribir dos imágenes, reapertura de la base y recorrido HTTP real |
| Integridad con CU01 y CU02 | Perfil confirmado, catálogo compartido y restricción de borrado por rutina | Regresiones HTTP y prueba CA02.12 con una rutina real y respuesta 409 |

## Resultados ejecutados

- **95 pruebas backend aprobadas.** Incluyen la regresión CU01/CU02 y la migración desde una base con perfil, catálogo y categorías. Continúa el aviso de deprecación de HTTPX con Starlette TestClient.
- **25 pruebas Flutter aprobadas**, con 4 de CU03 y 21 de regresión. El análisis estático terminó sin incidencias.
- **11 verificaciones HTTP de CU03 aprobadas** con proceso FastAPI, SQLite temporal, Ollama y ARASAAC reales. Se obtuvieron los bytes de vista previa de la referencia 8094 (9.593 bytes), se confirmó una sola incorporación para dos pasos y se volvió a leer el recurso desde disco.
- **7 verificaciones HTTP de CU01 y 4 de CU02 aprobadas** en bases separadas. La comprobación de recuperación tras reiniciar la aplicación backend de CU03 se realizó con una segunda instancia sobre la misma base en pruebas automatizadas.
- La compilación para simulador no terminó en este entorno. Xcode informó falta de conexión con CoreSimulator y `sandbox_apply: Operation not permitted` al resolver paquetes Swift. Por separado, la persona usuaria informó que realizó las pruebas de CU03 en el simulador. No comunicó resultados por escenario y reservó las mejoras para la siguiente iteración.

El cierre de RF01.2 confirma el consumo del contexto persistido y pertinente en generación. La prueba inspeccionó la solicitud HTTP construida para Ollama con transporte controlado. La integración real usó un perfil sintético persistido. La prueba funcional manual de CU01 permanece pendiente. Para CA02.12 se guardó una rutina con el pictograma y se intentó eliminarlo desde la API de CU02. Se obtuvo 409 y se conservó la imagen. Al eliminar la rutina también se conservó el pictograma.

## Evaluación del modelo

Modelo provisional `qwen2.5:1.5b` (Q4_K_M), Ollama `0.40.17`. Las tres respuestas finales cumplieron el contrato estructural y el orden. La revisión técnica de contenido y de términos produjo estas observaciones:

| Entrada | Resultado estructural | Observación semántica |
|---|---|---|
| Lavarse las manos | 3 pasos válidos | Empieza aplicando jabón, agrupa el lavado en un solo paso y omite mojar y enjuagar explícitamente. Los dos últimos pasos recurren al término genérico «manos». |
| Preparar la mochila para el colegio | 6 pasos válidos | Incluye libros y bolígrafos, pero «Encolir» resulta ininteligible, «Añadir regalos» carece de justificación y el uniforme no obtuvo candidatos. |
| Preparar una colación de manzana y agua | 3 pasos válidos | Supone poner la manzana en agua y colarla. Falta una secuencia clara para preparar la fruta y servir el agua por separado. |

La primera ejecución del servidor desde el entorno restringido falló al asignar memoria Metal. Las sondas con el servidor local disponible por fuera de ese proceso completaron la inferencia. La [salida registrada](results.json) conserva las propuestas del ensayo inicial y del flujo final. El ajuste de instrucciones redujo algunas acciones ajenas, como encender una computadora o hervir agua, y quedaron errores de contenido y términos que requieren corrección humana. Estas muestras son una revisión técnica, con calidad pendiente de validar en tareas y con usuarios representativos. No se midieron los objetivos del SRS.

## Cobertura

| Criterios | Verificación |
|---|---|
| CA03.1–CA03.3 | Entrada escrita, JSON Schema, validación estricta, posiciones explícitas y tres respuestas Ollama reales |
| CA03.4–CA03.6 | Ranking local, empate, consulta remota real y cambio de candidato en widgets |
| CA03.7–CA03.8 | Agregar, editar, quitar y ordenar. La API exige aprobación de cada paso y confirmación de la rutina |
| CA03.9–CA03.10 | Recuperación HTTP, reapertura en pruebas y actualización/eliminación |
| CA03.11 | Respuestas 502/503/504, opción manual comprobada y guardado con la IA sustituida por un fallo controlado |
| CA03.12–CA03.14 | Conservación de imágenes, rechazo de pasos incompletos y repetición de pictogramas |
| CA03.15 | Propuestas sin escritura, deduplicación, rollback de imágenes y preservación de recursos aprobados en CU02 |

[Casos, salidas y comandos reproducibles](results.json) · [Registro y protocolo manual](manual-check.md). T16 requiere el recorrido completo con la interfaz y permanece pendiente.
