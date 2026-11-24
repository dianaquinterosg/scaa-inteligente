# SCAA Inteligente — MVP

**Proyecto:** Sistema inteligente para la personalización asistida de Sistemas de Comunicación Aumentativa y Alternativa mediante inteligencia artificial.

**Estado:** Línea base documental revisada `docs-v0.2`. **No representa software implementado ni validado.**

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

La equivalencia «3 de 5 casos de uso = 60 %» es una **convención de alcance de planificación**, no una medición comprobada de esfuerzo o cobertura de funcionalidades. Debe verificarse frente a la rúbrica y las pruebas.

## Arquitectura prevista

Flutter (cliente) → FastAPI (API REST y reglas de negocio) → SQLite y archivos locales; FastAPI integra ARASAAC (servicio externo) y un adaptador de IA local para CU03 (Ollama como opción a validar). «IA local» significa inferencia en el equipo que ejecuta el backend, **no necesariamente en el iPad**; un dispositivo físico necesita acceso de red al backend.

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

Base técnica inicial en desarrollo: cliente Flutter iOS, endpoint de salud FastAPI y conexión SQLite con entornos separados. Las sondas de ARASAAC e IA local y las pruebas de esta base están registradas en [resultados técnicos](docs/evidence/iteration-0/test-results.md). CU01–CU03 todavía no están implementados. Los estados «comprometido», «previsto» y «validado» no son intercambiables. El cliente compiló y arrancó en iPad simulado; la persona usuaria confirmó «Servidor disponible» y FastAPI registró HTTP 200 en la comprobación de salud. Esto verifica la base técnica, no los casos de uso del MVP.

## Prioridades de implementación

- **P0 (flujo demostrable):** requisitos y criterios indispensables para ejecutar CU01, incorporación real de pictogramas con CU02 (incluye categorías N:M básicas) y generación/validación de una rutina con IA real y preselección editable en CU03.
- **P1 (complementos comprometidos):** administración avanzada, manejo de dependencias, recuperación y errores adicionales. Forman parte de la especificación; si no se terminan, **el caso de uso se declara parcial**, no completo.
- **P2:** funcionalidades explícitamente posteriores al 60 %, entre ellas generación de imágenes por IA, CU04, CU05 integral y voz.

La matriz de prioridad y aceptación está en [casos de uso](docs/use-cases.md) y el [plan de iteraciones](docs/iteration-plan.md). **P0 no es sinónimo de 60 % aprobado**: la cobertura final se calcula a partir de evidencia y rubricación académica.
