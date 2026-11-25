# SCAA Inteligente — MVP

**Proyecto:** Sistema inteligente para la personalización asistida de Sistemas de Comunicación Aumentativa y Alternativa mediante inteligencia artificial.

**Línea base de requisitos:** v0.2. **Implementación:** CU01–CU03 implementados, con los niveles de verificación detallados en el registro de implementación.

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
- [Preparación y ejecución del entorno de desarrollo](docs/development-setup.md)
- [Registro de implementación](docs/evidence/iteration-0/implementation-log.md)
- [Registro de cambios documentales](CHANGELOG.md)

## Estado de implementación

La Iteración 0 cerró funcionalmente en `db312e3592648a3b620d66b2ea22af018396112e`. CU01–CU03 cuentan con pruebas automatizadas y recorridos manuales aprobados por la persona usuaria en el simulador para el incremento anterior. La calidad semántica del modelo local continúa bajo evaluación independiente. La Iteración 4 añadió controles de administración y visualización básica de recursos aprobados como avance parcial de CU05. La persona usuaria reportó 16 comprobaciones manuales aprobadas en iPad mediante Device Hub. La liberación permanece pendiente.

Consulta las [evidencias por iteración](docs/evidence/README.md) y la [guía de ejecución](docs/development-setup.md).

## Prioridades de implementación

- **P0 (flujo demostrable):** requisitos y criterios indispensables para ejecutar CU01, incorporación real de pictogramas con CU02 (incluye categorías N:M básicas) y generación/validación de una rutina con IA real y preselección editable en CU03.
- **P1 (complementos comprometidos):** administración avanzada, manejo de dependencias, recuperación y errores adicionales. Forman parte de la especificación; si no se terminan, **el caso de uso se declara parcial**, no completo.
- **P2:** funcionalidades explícitamente posteriores al 60 %, entre ellas generación de imágenes por IA, CU04, CU05 integral y voz.

La matriz de prioridad y aceptación está en [casos de uso](docs/use-cases.md) y el [plan de iteraciones](docs/iteration-plan.md). P0 indica prioridad de implementación. La cobertura se determina con la matriz de trazabilidad y los resultados de las pruebas de P0 y P1.

La [referencia visual SCAA](docs/design/README.md) documenta los mockups y su adaptación a CU01 en tablet.

El [registro de Iteración 2](docs/evidence/iteration-2/README.md) reúne el diseño, las pruebas y el recorrido confirmado de CU02 en el simulador de iPad.

El [registro de Iteración 3](docs/evidence/iteration-3/README.md) documenta CU03 y sus verificaciones.

El [registro de Iteración 4](docs/evidence/iteration-4/README.md) describe el modo visualización predeterminado, la administración deliberada, el visor de rutinas y el detalle de dependencias al eliminar pictogramas. La navegación de contenido aprobado es un avance parcial de CU05. CU04, CU05 integral y la liberación permanecen pendientes.
