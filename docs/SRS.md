# SRS — Especificación de requisitos de software

**Proyecto:** Sistema inteligente para la personalización asistida de SCAA mediante IA  
**Versión:** 0.2 — primera línea base documental publicada en Git  
**Estado:** Especificación consolidada tras revisiones locales; no certifica implementación.  
**Organización:** Inspirada en prácticas de especificación IEEE/ISO/IEC/IEEE 29148; **no se afirma conformidad formal certificada**.

## 1. Introducción

### 1.1 Propósito

Definir los requisitos verificables del prototipo y el alcance del incremento. La especificación sirve de referencia para diseño, implementación, pruebas, trazabilidad y aceptación.

### 1.2 Problema

El administrador de un SCAA puede enfrentar múltiples pasos para buscar, importar y organizar pictogramas, y para construir rutinas visuales. La propuesta busca disminuir esa carga operativa mediante reutilización, interfaces guiadas y asistencia inteligente, sin sustituir el criterio del cuidador o profesional.

### 1.3 Actores

- **Administrador:** familiar, cuidador o profesional que configura y valida recursos.
- **Persona usuaria de SCAA:** destinataria de los recursos comunicativos; no se presupone que administre el prototipo.

### 1.4 Terminología

- **SCAA:** Sistema de Comunicación Aumentativa y Alternativa.
- **Pictograma validado:** recurso incorporado por decisión explícita del administrador.
- **Propuesta:** secuencia o selección generada automáticamente, todavía no aprobada.
- **IA local:** inferencia realizada en equipo bajo control del proyecto, sin servicio remoto de inferencia; puede seguir necesitándose una red local entre cliente y servidor.
- **ARASAAC:** catálogo/API externos de pictogramas; **no es el modelo de IA**.

## 2. Alcance y supuestos

### 2.1 Entrega parcial (60 % comprometido)

Se **comprometen** CU01, CU02 y CU03. Las capacidades se priorizan como **P0** (flujo demostrable), **P1** (complementos comprometidos) y **P2** (después del 60 %). La prioridad **no modifica automáticamente el requisito**: un CU con criterios P1 sin verificar debe informarse como **parcial**. La equivalencia «3/5 CU = 60 %» es una convención inicial de alcance; no una medición del esfuerzo o de la aceptación real. Pueden existir vistas básicas de contenidos sin completar CU05.

### 2.2 Posterior al 60 %

CU04, CU05 integral, generación de nuevas imágenes con IA y entrada por voz quedan planificados para iteraciones posteriores del proyecto, sujetos a viabilidad, pruebas y priorización. La generación de imágenes mediante IA **permanece dentro de la visión del MVP completo**, no se considera descartada.

### 2.3 Restricciones y dependencias

- Un perfil activo para el prototipo; sin autenticación multiusuario en la entrega parcial.
- Cliente Flutter; servidor FastAPI/Python; almacenamiento SQLite más archivos locales.
- La búsqueda remota en ARASAAC requiere conectividad y cumplimiento de licencia/atribución aplicables.
- La IA de generación de rutinas se proyecta local; modelo concreto, consumo de memoria, latencia y calidad se deben evaluar antes de fijar implementación.
- La aplicación en iPad físico no es autónoma sin backend local disponible.

## 3. Requisitos funcionales

### RF01 — Perfil y contexto [60 %]

- **RF01.1:** Permitir registrar y modificar un perfil con alias obligatorio (1–50 caracteres) e intereses, actividades y rutinas frecuentes opcionales, en elementos individuales (máx. 50 caracteres cada uno).
- **RF01.2:** Utilizar para la personalización solo información registrada y confirmada por el administrador.
- **RF01.3:** Validar entradas: trim, rechazo de vacíos y duplicados por tipo sin distinguir mayúsculas/minúsculas; persistir cambios de manera íntegra.

### RF02 — Gestión de pictogramas [parcial en el 60 %]

- **RF02.1 [60 %]:** Buscar pictogramas a partir de descripción textual. La entrada por voz queda posterior.
- **RF02.2 [60 %]:** Buscar primero recursos ya guardados y, cuando corresponda, consultar ARASAAC y mostrar alternativas.
- **RF02.3 [posterior]:** Ofrecer generación de una propuesta de pictograma mediante IA cuando no exista recurso adecuado, sujeta a validación del administrador. Debe evaluarse calidad, seguridad visual, recursos de ejecución y derechos/licencia.
- **RF02.4 [60 %]:** Permitir importar una imagen propia y validar su formato/tamaño/etiqueta.
- **RF02.5 [60 %]:** Mostrar vista previa y permitir editar etiqueta, seleccionar categorías opcionales y aceptar o rechazar antes de incorporar.
- **RF02.6 [60 %]:** Guardar pictogramas aprobados con su origen, referencia externa si corresponde, atribución y archivo local; consultar y eliminar cuando no estén referenciados por rutinas.
- **RF02.7 [60 %]:** Crear, renombrar y eliminar categorías configurables.
- **RF02.8 [60 %]:** Asignar cero, una o varias categorías a un pictograma y modificar asociaciones sin duplicar el recurso.
- **RF02.9 [60 %]:** Filtrar pictogramas guardados por categorías.

### RF03 — Rutinas asistidas [60 %]

- **RF03.1:** Recibir descripción escrita de una rutina en lenguaje natural.
- **RF03.2:** Solicitar a un modelo de IA una propuesta estructurada de nombre y pasos ordenados, sin incorporarla automáticamente.
- **RF03.3:** Buscar y **preseleccionar provisionalmente** para cada paso pictogramas aprobados localmente y, cuando no haya candidato local suficiente, consultar ARASAAC. El criterio inicial es determinístico y auditable: coincidencia exacta normalizada local; luego coincidencia por prefijo o inclusión, sin desempate arbitrario; finalmente primer candidato devuelto por ARASAAC **marcado para revisión**, nunca como elección validada. Si hay empate local en el mejor nivel o no hay resultados, el paso queda sin selección automática o pendiente. El algoritmo se documenta en `architecture.md`.
- **RF03.4:** Permitir agregar, editar, quitar y reordenar pasos.
- **RF03.5:** Permitir reemplazar el pictograma preseleccionado o incorporar uno mediante el flujo CU02.
- **RF03.6:** Guardar solo una rutina confirmada, con nombre y al menos un paso, y **un pictograma explícitamente aprobado para cada paso al confirmar**. Los candidatos de ARASAAC siguen siendo temporales hasta el guardado aprobado de la rutina.
- **RF03.7:** Consultar, editar y eliminar rutinas, conservando los pictogramas compartidos.
- **RF03.8:** Ante indisponibilidad o salida inválida de la IA, informar y ofrecer creación manual.

### RF04 — Recomendaciones contextuales [posterior]

- **RF04.1:** Proponer vocabulario con base en información contextual confirmada, actividades y rutinas pertinentes.
- **RF04.2:** Permitir revisar, aceptar o rechazar sugerencias.
- **RF04.3:** Incorporar solamente sugerencias aceptadas.

### RF05 — Uso de contenido validado [posterior como CU integral]

- **RF05.1:** Facilitar acceso al conjunto de pictogramas y rutinas aprobados.
- **RF05.2:** Organizar y presentar contenido para su utilización desde la interfaz comunicativa. Las vistas CRUD básicas de CU02/CU03 no equivalen a completar este requisito integral.

## 4. Requisitos no funcionales

- **RNF01 — Usabilidad y accesibilidad:** interfaz consistente, clara, con controles legibles y flujos que minimicen pasos; validación con tareas representativas.
- **RNF02 — Privacidad:** minimizar datos personales y evitar información clínica innecesaria; restringir acceso a archivos y base de datos según el despliegue.
- **RNF03 — Compatibilidad:** cliente previsto para tablet/iPad mediante Flutter y acceso al backend documentado.
- **RNF04 — Mantenibilidad:** separar presentación, API, reglas de negocio, persistencia, integración ARASAAC y adaptador IA; permitir pruebas aisladas.
- **RNF05 — Integridad:** no dejar guardados parciales de rutinas/pictogramas ante fallos; manejar transacciones y archivos temporales.

## 5. Reglas de negocio transversales

- **RT01:** Ningún pictograma generado/importado o propuesta de rutina/recomendación se incorpora como contenido definitivo sin confirmación del administrador.
- **RT02:** Una misma imagen/pictograma puede ser usada por varios pasos y rutinas, inclusive repetidamente dentro de una misma rutina.
- **RT03:** Un pictograma puede pertenecer a cero, una o varias categorías.
- **RT04:** Al eliminar una categoría se conservan los pictogramas; solo se eliminan las asociaciones de la categoría.
- **RT05:** No se elimina un pictograma que está siendo referenciado por un paso de rutina.
- **RT06:** Los candidatos de ARASAAC propuestos durante CU03 no se incorporan al catálogo definitivo hasta la confirmación de la rutina. Si el administrador confirma explícitamente un pictograma **mediante CU02 por separado**, ese recurso permanece almacenado aunque se cancele la edición de rutina.

## 6. Interfaces externas

- **Interfaz del cliente:** formularios y controles Flutter; REST JSON.
- **Servidor:** FastAPI, validación del contrato y lógica de autorización/negocio; endpoints definitivos en `architecture.md`.
- **ARASAAC:** búsqueda externa y recuperación de imágenes con referencia/atribución; manejo de timeout y error.
- **Motor IA local:** adaptador para generación de estructura de rutinas. La especificación del JSON debe ser validada por el servidor, independientemente del modelo.

## 7. Objetivos medibles de calidad y usabilidad

- OE1: aspiración de reducción ≥50 % del tiempo e interacciones para incorporar un pictograma frente al proceso manual de referencia.
- OE2: aspiración de reducción ≥50 % del tiempo e interacciones para crear una rutina.
- OE3: pertinencia ≥70 % de recomendaciones, evaluable tras implementar CU04.
- OE4: ≥80 % de tareas de usabilidad completadas sin asistencia, sujeto a pruebas reales.

Estos valores son objetivos. Para informar resultados, registrar la línea base, el protocolo, la muestra y las mediciones obtenidas.

## 8. Casos de uso, trazabilidad y aceptación

Las especificaciones completas, prioridades y criterios están en [`use-cases.md`](use-cases.md). Los diagramas fuente UML están en [`diagrams/use-cases.puml`](diagrams/use-cases.puml) y [`diagrams/cu03-sequence.puml`](diagrams/cu03-sequence.puml). La vinculación por **subrequisito** RF→CU→componentes→pruebas→evidencias se mantiene en [`traceability.md`](traceability.md); el protocolo está en [`test-plan.md`](test-plan.md).

## 9. Control de cambios

Los cambios de alcance se registran en [`decisions.md`](decisions.md). La línea base documental se versiona antes de implementar; modificaciones posteriores deberán indicar motivo, impacto, RF/CU/CA afectados y commit asociado.

### Refinamientos de la Iteración 4

Los siguientes refinamientos proceden de la validación del incremento anterior. Se registran sobre la línea base v0.2 y mantienen los identificadores y prioridades originales.

| Referencia | Requisitos y casos de uso relacionados | Comportamiento requerido |
|---|---|---|
| RF-I4.1 | RF01.1, RF02.6–RF02.9 y RF03.7 | Iniciar en visualización. Pedir una confirmación explícita para entrar a administración y ofrecer una salida visible. Reservar creación, edición, eliminación y configuración al modo administración. El control actúa en Flutter. |
| RF-I4.2 | RF02.9 y avance parcial de RF05.1 | Navegar por las categorías del catálogo aprobado y mostrar tarjetas con imagen y etiqueta en visualización. |
| RF-I4.3 | RF03.7 y avance parcial de RF05.2 | Mostrar de izquierda a derecha los pasos aprobados de una rutina en un visor horizontal de solo lectura, con desplazamiento cuando corresponda y compatibilidad vertical y horizontal. Mantener de 1 a 12 pasos y conservar el editor vertical en administración. |
| RF-I4.4 | RF02.6 y RF03.7 | Ante un borrado bloqueado por rutinas dependientes, devolver HTTP 409 con sus identificadores y nombres, mostrar el detalle a la persona administradora y conservar todas las referencias y archivos. |

El estado de administración vive en memoria del cliente. El incremento incorpora consulta básica de contenido aprobado como avance parcial de CU05. CU04 y CU05 integral permanecen planificados. La política vigente de Ollama y de asociación textual continúa en CU03.
