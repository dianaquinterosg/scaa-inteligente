# SCAA Inteligente — MVP

**Proyecto:** Sistema inteligente para la personalización asistida de Sistemas de Comunicación Aumentativa y Alternativa mediante inteligencia artificial.

**Versión del incremento:** [v0.3.0](docs/releases/v0.3.0.md). **Línea base de requisitos:** v0.2. CU01–CU03 se validaron en el simulador de iPad.

La v0.2 es la primera línea base documental publicada en Git, consolidada tras revisiones locales que incluyeron una versión de trabajo v0.1.

## Problema y propuesta

La personalización de recursos de comunicación aumentativa y alternativa puede requerir búsquedas, importación de imágenes, organización manual y construcción de secuencias de varios pasos. Este proyecto plantea un prototipo para que familiares, cuidadores y profesionales administren pictogramas y rutinas mediante una interfaz guiada, búsqueda de recursos estandarizados y generación asistida de propuestas de rutinas, siempre bajo control humano.

## Alcance

**Entrega del 60 % (tres casos de uso comprometidos; no equivale a un 60 % de esfuerzo comprobado):**
- **CU01:** configurar un perfil y su contexto.
- **CU02:** buscar/reutilizar pictogramas, consultar ARASAAC, importar imágenes propias, validar, categorizar y administrar los recursos.
- **CU03:** describir una rutina, generar pasos con IA local, preseleccionar pictogramas y revisar/guardar una rutina visual completa.

**Iteraciones posteriores hacia el MVP completo:**
- **CU04:** recomendaciones contextuales y su aceptación/rechazo.
- **CU05:** navegación y uso integral del contenido validado.
- Generación de imágenes/pictogramas mediante IA, después de probar su viabilidad y adecuación visual (extensión de RF02). La carga de imágenes propias **no reemplaza definitivamente** esta funcionalidad.
- Entrada por voz y mejoras de asociación contextual, según priorización.

La equivalencia «3 de 5 casos de uso = 60 %» identifica el alcance planificado del incremento. La cobertura real se verifica por requisito y criterio de aceptación con las pruebas registradas.

## Arquitectura

Flutter (cliente) → FastAPI (API REST y reglas de negocio) → SQLite y archivos locales; FastAPI integra ARASAAC (servicio externo) y Ollama para generar propuestas de CU03. «IA local» significa inferencia en el equipo que ejecuta el backend, **no necesariamente en el iPad**; un dispositivo físico necesita acceso de red al backend.

## Documentación

- [Especificación de requisitos (SRS)](docs/SRS.md)
- [Casos de uso](docs/use-cases.md)
- [Diagrama UML de casos de uso](docs/diagrams/use-cases.puml)
- [Secuencia UML de CU03](docs/diagrams/cu03-sequence.puml)
- [Arquitectura](docs/architecture.md)
- [Modelo de datos](docs/data-model.md)
- [Plan inicial de iteraciones](docs/iteration-plan.md)
- [Decisiones y cambios](docs/decisions.md)
- [Matriz de trazabilidad](docs/traceability.md)
- [Plan de pruebas y evidencias](docs/test-plan.md)
- [Instalación y ejecución de la demo v0.3.0](docs/development-setup.md#demo-v030-en-el-simulador-de-ipad)
- [Registro de implementación](docs/evidence/iteration-0/implementation-log.md)
- [Registro de cambios documentales](CHANGELOG.md)

## Estado de implementación

La Iteración 4 incorpora la bienvenida y los modos de visualización y administración, la consulta de pictogramas, el visor horizontal de rutinas, y el detalle de dependencias al intentar eliminar un pictograma. La demo utiliza Qwen3 4B Instruct con el perfil `linguistic`, que propone de tres a cinco pasos con revisión humana.

La regresión final aprobó **135 pruebas de backend y 36 de Flutter**. `flutter analyze` quedó sin incidencias y la persona usuaria aprobó la validación final en Device Hub. La instalación en iPad físico pasa a la siguiente iteración. [Evidencias de Iteración 4](docs/evidence/iteration-4/README.md)

## Prioridades de implementación

- **P0 (flujo demostrable):** requisitos y criterios indispensables para ejecutar CU01, incorporación real de pictogramas con CU02 (incluye categorías N:M básicas) y generación/validación de una rutina con IA real y preselección editable en CU03.
- **P1 (complementos comprometidos):** administración avanzada, manejo de dependencias, recuperación y errores adicionales. Forman parte de la especificación; si no se terminan, **el caso de uso se declara parcial**, no completo.
- **P2:** funcionalidades explícitamente posteriores al 60 %, entre ellas generación de imágenes por IA, CU04, CU05 integral y voz.

La matriz de prioridad y aceptación está en [casos de uso](docs/use-cases.md) y el [plan de iteraciones](docs/iteration-plan.md). P0 indica prioridad de implementación. La cobertura se determina con la matriz de trazabilidad y los resultados de las pruebas de P0 y P1.

La [referencia visual SCAA](docs/design/README.md) documenta los mockups y su adaptación a CU01 en tablet.

El [registro de Iteración 2](docs/evidence/iteration-2/README.md) reúne el diseño, las pruebas y el recorrido confirmado de CU02 en el simulador de iPad.

El [registro de Iteración 3](docs/evidence/iteration-3/README.md) documenta CU03 y sus verificaciones.
