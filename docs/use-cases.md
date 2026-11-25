# Casos de uso — versión 0.2

**Actor principal común:** Administrador (familiar/cuidador/profesional).  
**Estado:** CU01–CU03 especificados y comprometidos para la entrega del 60 %; CU04–CU05 identificados, pendientes de especificación detallada para una iteración posterior.  
**Nota:** Los ejemplos ilustran comportamiento esperado, no evidencia de funcionalidad ya construida. Los criterios **P0** priorizan un flujo end-to-end; los **P1** son requisitos complementarios comprometidos cuyo incumplimiento debe reportarse, y los **P2** son posteriores al 60 %. Ver [UML de casos de uso](diagrams/use-cases.puml) y [secuencia CU03](diagrams/cu03-sequence.puml).

## CU01 — Gestionar perfil y contexto

- **RF:** RF01.1–RF01.3.
- **Objetivo:** Registrar información mínima para personalización posterior.
- **Diseño de Iteración 1:** [Secuencia de CU01](diagrams/cu01-sequence.puml), con contrato y evidencias en [Iteración 1](evidence/iteration-1/README.md).
- **Disparador:** Primer inicio sin perfil o acceso a «Perfil y contexto» desde Inicio.
- **Precondiciones:** Aplicación y backend disponibles. Primer inicio permite configurar el perfil sin autenticación.
- **Datos:** Alias obligatorio (1–50 caracteres); intereses, actividades y rutinas frecuentes opcionales, como tags individuales (máx. 50 caracteres por tag).

### Flujo principal

1. El sistema detecta ausencia de perfil y muestra configuración inicial; en visitas posteriores ofrece pantalla de edición.
2. El administrador introduce o modifica alias, intereses, actividades y rutinas frecuentes.
3. El administrador pulsa «Guardar».
4. El sistema valida alias y elementos, normaliza espacios y detecta duplicados por tipo ignorando mayúsculas.
5. El sistema persiste perfil/contexto de forma íntegra, sin diálogo de confirmación redundante.
6. El sistema confirma éxito; al crear el primer perfil navega a Inicio.

### Alternativas y errores

- **A1 — Cancelar edición posterior:** conservar información anterior; primer uso requiere alias para continuar.
- **A2 — Editar/eliminar tag:** cambios pendientes hasta guardar.
- **E1 — Alias vacío, valores inválidos/duplicados o >50:** mostrar error contextual, no persistir estado inválido.
- **E2 — Fallo de almacenamiento:** informar, conservar datos en edición y no reemplazar el estado persistido.

### Postcondiciones

- **Éxito:** perfil y elementos confirmados disponibles para consultas posteriores.
- **Cancelación/error:** estado persistido anterior intacto.

### Criterios de aceptación

- **CA01.1:** Crear perfil con alias válido.
- **CA01.2:** Añadir elementos individuales de los tres tipos.
- **CA01.3:** Editar y eliminar elementos.
- **CA01.4:** Bloquear alias vacío.
- **CA01.5:** Rechazar tags vacíos/duplicados por tipo sin distinguir mayúsculas.
- **CA01.6:** Normalizar espacios externos.
- **CA01.7:** Validar límite de 50 caracteres.
- **CA01.8:** Persistir datos y recuperarlos tras volver a la pantalla.
- **CA01.9:** Un fallo de guardado no modifica el estado anterior.
- **CA01.10:** Solo datos almacenados/confirmados quedan disponibles como contexto.

## CU02 — Gestionar pictogramas

- **RF del 60 %:** RF02.1, RF02.2, RF02.4–RF02.9. **RF02.3 generación de imágenes por IA:** posterior.
- **Objetivo:** Buscar/reutilizar, incorporar, categorizar y administrar pictogramas aprobados.
- **Disparador:** «Agregar pictograma» / «Mis pictogramas».
- **Precondiciones:** Perfil inicial configurado; backend disponible. ARASAAC puede estar temporalmente inaccesible.

### Flujo principal

1. Administrador ingresa descripción textual (por ejemplo «lavarse los dientes»).
2. Sistema valida descripción y busca coincidencias en pictogramas aprobados localmente.
3. Si necesita nuevas alternativas, consulta ARASAAC y muestra resultados con etiquetas e imágenes.
4. Administrador selecciona recurso; el sistema muestra vista previa, etiqueta editable, origen y categorías opcionales.
5. Administrador ajusta etiqueta y puede marcar cero, una o varias categorías.
6. Administrador confirma incorporación.
7. Backend valida entrada y duplicados, obtiene/prepara archivo de imagen, persiste metadatos y asociaciones y confirma éxito.
8. El pictograma queda disponible para uso y reutilización en CU03.

### Alternativas

- **A1:** No existen coincidencias locales → buscar en ARASAAC.
- **A2:** Sin resultados adecuados de ARASAAC → importar imagen propia.
- **A3:** Importación directa de archivo propio sin consultar ARASAAC.
- **A4:** Editar etiqueta/categorías antes o después de incorporar.
- **A5:** Recurso ARASAAC ya incorporado → reutilizarlo, evitando duplicado por fuente+ID externo.
- **A6:** Cancelar incorporación → no guardar nuevo recurso definitivo.
- **A7:** Eliminar pictograma sin dependencias → eliminar registro y archivo administrado si corresponde.
- **A8:** Crear categoría (nombre único normalizado), renombrar y filtrar.
- **A9:** Asignar o retirar varias categorías de un pictograma.
- **A10:** Eliminar categoría con confirmación → borrar asociaciones, preservar pictogramas y otras categorías.

### Excepciones

- **E1:** descripción o etiqueta vacía → bloquear búsqueda/guardado respectivamente.
- **E2:** ARASAAC inaccesible → informar, reintentar o usar archivo propio.
- **E3:** imagen inválida → informar formato/tamaño; configuración inicial propuesta PNG/JPG/WebP, máximo 5 MB, a verificar durante implementación.
- **E4:** error de persistencia/archivo → no dejar recurso parcialmente incorporado; ofrecer reintento.
- **E5:** pictograma referenciado por rutina → bloquear eliminación, informar dependencia.
- **E6:** categoría duplicada/vacía → rechazo sin modificar datos.

### Postcondiciones

- **Éxito:** pictograma aprobado guardado con origen y atribución aplicable; asociaciones a categorías disponibles.
- **Cancelación/error:** sin incorporación definitiva del nuevo recurso.

### Criterios de aceptación

- **CA02.1:** Búsqueda textual.
- **CA02.2:** Reutilización de recursos locales.
- **CA02.3:** Consulta y presentación de resultados ARASAAC.
- **CA02.4:** Vista previa y revisión antes de guardar.
- **CA02.5:** Importación de imagen propia.
- **CA02.6:** Validación de archivo y etiqueta.
- **CA02.7:** Confirmación humana obligatoria.
- **CA02.8:** Persistencia y recuperación.
- **CA02.9:** No duplicar misma referencia ARASAAC.
- **CA02.10:** Alternativa manual si ARASAAC falla.
- **CA02.11:** Eliminar pictograma no referenciado.
- **CA02.12:** Bloquear eliminación si existen rutinas dependientes.
- **CA02.13:** Crear categoría válida.
- **CA02.14:** Bloquear categoría vacía/duplicada.
- **CA02.15:** Renombrar categoría.
- **CA02.16:** Asignar múltiples categorías o ninguna; modificar asociaciones.
- **CA02.17:** Filtrar por categoría.
- **CA02.18:** Eliminar categoría sin eliminar recursos ni otras asociaciones.
- **CA02.19:** Persistencia de categorías y sus asociaciones.

## CU03 — Gestionar rutinas inteligentes

- **RF:** RF03.1–RF03.8.
- **Objetivo:** Convertir una descripción escrita en una propuesta de rutina visual, con preselección automática de pictogramas, revisión y confirmación humanas.
- **Disparador:** «Crear rutina».
- **Precondiciones:** Perfil configurado; backend disponible. Puede faltar conexión a ARASAAC; un modelo local de IA requiere estar instalado/operativo para generación automática.

### Flujo principal

1. El administrador escribe una descripción («prepararse para ir al colegio») y solicita generar propuesta.
2. Backend valida descripción y solicita al adaptador IA local nombre y lista ordenada de pasos, cada uno con etiqueta y término de búsqueda.
3. Backend verifica estructura y contenido; no persiste aún la propuesta como rutina definitiva.
4. El motor de asociación aplica la política determinística definida en `architecture.md`: prioriza coincidencias locales; ante ausencia de candidato suficiente consulta ARASAAC y propone provisionalmente el primer resultado para revisión. En empate local o falta de resultados, mantiene el paso sin selección automática.
5. Sistema presenta pasos editables y resalta aquellos sin pictograma seleccionado.
6. Administrador revisa, reordena, añade, modifica o elimina pasos; puede reemplazar pictogramas, consultar ARASAAC o subir recurso propio desde CU02.
7. El sistema comprueba nombre, al menos un paso, posiciones válidas y **un pictograma seleccionado explícitamente por el administrador (o una preselección revisada y aceptada) para cada paso**.
8. Administrador confirma guardar rutina.
9. Backend incorpora, dentro de una operación consistente, nuevos pictogramas aprobados y rutina/pasos; devuelve la rutina guardada.

### Alternativas y excepciones

- **A1 — IA no disponible/respuesta inválida:** informar y ofrecer crear secuencia manual.
- **A2 — ARASAAC no disponible:** utilizar recursos locales o carga propia; mantener pasos no resueltos pendientes.
- **A3 — Coincidencia ambigua:** si dos pictogramas locales empatan en la mayor prioridad de búsqueda, mostrar alternativas sin elegir una automáticamente; nunca afirmar pertinencia sin revisión.
- **A4 — Paso sin imagen:** permitir resolverlo mediante CU02 o eliminarlo; **bloquear guardado mientras falte pictograma**.
- **A5 — Reordenar/repetir pictograma:** el mismo pictograma puede referenciarse en más de un paso; posiciones únicas.
- **A6 — Cancelación:** descartar propuesta de edición sin guardar rutina definitiva.
- **A7 — Editar rutina guardada:** modificar pasos/pictogramas, validando integridad al confirmar.
- **A8 — Eliminar rutina:** eliminar pasos y rutina, preservar pictogramas compartidos.
- **E1 — Persistencia falla:** reversión lógica de registros y limpieza de archivos temporales; no dejar rutina incompleta.

### Postcondiciones

- **Éxito:** rutina definitiva aprobada, nombre y pasos ordenados, cada paso con pictograma existente y válido.
- **Cancelación/error:** no se agrega rutina incompleta; no se incorporan candidatos de ARASAAC no aprobados.

### Criterios de aceptación

- **CA03.1:** Introducir descripción escrita.
- **CA03.2:** IA local real devuelve propuesta estructurada interpretable.
- **CA03.3:** Pasos con orden explícito.
- **CA03.4:** Búsqueda y preselección automáticas revisables.
- **CA03.5:** Priorizar pictogramas aprobados locales.
- **CA03.6:** Reemplazar pictograma sugerido.
- **CA03.7:** Agregar, modificar, eliminar y reordenar pasos.
- **CA03.8:** Confirmación explícita antes de persistir.
- **CA03.9:** Recuperar rutina guardada.
- **CA03.10:** Editar y eliminar rutina guardada.
- **CA03.11:** Fallo IA permite creación manual.
- **CA03.12:** Eliminar rutina conserva pictogramas compartidos.
- **CA03.13:** Bloqueo de guardado con pasos sin pictograma aprobado.
- **CA03.14:** Una misma imagen puede aparecer en múltiples pasos.
- **CA03.15:** No persistir candidatos ARASAAC preseleccionados antes de aprobación de rutina.

## CU04 — Gestionar recomendaciones contextuales [posterior]

**Definición preliminar:** Administrador solicita/revisa recomendaciones basadas en contexto autorizado y acepta o rechaza contenido. Vinculado a RF04.1–RF04.3 y OE3. Pendiente expandir flujos, excepciones y criterios antes de implementar.

## CU05 — Navegar y utilizar contenido validado [posterior]

**Definición preliminar:** Acceder al contenido previamente validado desde una interfaz destinada al uso comunicativo. Vinculado a RF05.1–RF05.2. Las pantallas de administración incluidas en CU02/CU03 son soporte mínimo y no certifican CU05 completo.

## Matriz de prioridad de criterios de aceptación — entrega del 60 %

Los criterios mantienen los IDs de v0.1. Un criterio en **P1** no se elimina del alcance funcional; su falta de implementación debe registrarse como desviación.

| Caso | P0 — flujo end-to-end verificable | P1 — complementos de la especificación | P2 — posterior a entrega |
|---|---|---|---|
| CU01 | CA01.1–CA01.10 | — | — |
| CU02 | CA02.1–CA02.10, CA02.13–CA02.14, CA02.16–CA02.17, CA02.19 | CA02.11–CA02.12, CA02.15, CA02.18 | RF02.3 (generación de imágenes IA), voz |
| CU03 | CA03.1–CA03.9, CA03.13–CA03.15 | CA03.10–CA03.12 | Asociación contextual avanzada |
| CU04, CU05 integral | — | — | Especificación detallada e implementación posterior |

**Condición de reporte:** demostrar P0 permite mostrar un núcleo funcional integrado; **no autoriza a afirmar CU02/CU03 completos** si falta P1. Antes de la entrega, marcar cada criterio con `Aprobado / Fallido / No ejecutado / Fuera del alcance de esta entrega` y enlazar evidencia verificable. 

### Escenarios transversales críticos

- **CU02/CU03 — candidatos externos:** seleccionar o preseleccionar un resultado ARASAAC **no lo persiste**. Si el administrador lo aprueba **junto con la rutina**, se registra al confirmar la rutina. Si abre CU02 e **incorpora expresamente un pictograma por separado**, ese recurso queda aprobado y persistido desde CU02 aunque luego cancele el borrador de rutina. Ambos caminos deben diferenciarse en la UI y las pruebas.
- **CU03 — asociación local:** coincidencia exacta normalizada se prioriza frente a prefijo/inclusión. Si existe empate en el nivel de mayor prioridad se muestran opciones sin asignación automática; ARASAAC se consulta si no hay candidato local apropiado.
- **CU03 — ARASAAC:** el primer resultado de la API se puede **preseleccionar como candidato**, con etiqueta «revisar»; el orden de la API **no equivale a pertinencia comprobada**.
- **CU03 — repetición:** no hay restricción `UNIQUE(routine_id, pictogram_id)`; sí hay `UNIQUE(routine_id, position)`.
- **CU03 — fallos IA:** el modo manual es comportamiento especificado (P1); si no se alcanza, documentar explícitamente como brecha.

## Refinamientos y criterios de la Iteración 4

| Criterio | Requisito / CU | Resultado observable |
|---|---|---|
| CA-I4.1 | RF-I4.1 / CU01–CU03 | Un arranque muestra visualización, incluso con perfil ausente. Abrir el acceso y cancelar preserva el modo. Confirmar activa administración e identifica el modo. Volver a visualización oculta los controles de modificación. Un nuevo arranque vuelve a visualización. |
| CA-I4.2 | RF-I4.1–RF-I4.2 / CU01, CU02 y CU05 parcial | Visualización permite filtrar pictogramas aprobados por categoría y muestra imagen y etiqueta. La configuración del perfil y las acciones de búsqueda externa, alta, edición y borrado se abren desde administración. |
| CA-I4.3 | RF-I4.1, RF-I4.3 / CU03 y CU05 parcial | Una rutina de 1 o 12 pasos abre un visor con etiquetas e imágenes ordenadas en una fila horizontal. El último paso es alcanzable al desplazar en la orientación que lo requiera. En administración se conserva el editor vertical. |
| CA-I4.4 | RF-I4.4 / CU02–CU03 | HTTP 409 devuelve una entrada por rutina, con ID y nombre, incluso si comparte la imagen en varios pasos. Flutter muestra el detalle y conserva el editor y el recurso. |
| CA-I4.5 | RF-I4.4 / CU02–CU03 | Se conserva la prohibición de borrar referencias activas y se admite el borrado después de retirar la última dependencia. Las pruebas de regresión cubren los flujos de CU01–CU03. |

La experiencia de visualización permite consultar secuencias guardadas. El alcance de esta iteración se limita a navegación y lectura y excluye seguimiento de ejecución.

## Criterios del ensayo lingüístico de CU03

| Criterio | Requisito | Resultado observable |
|---|---|---|
| CA-I4.6 | RF-I4.5 | Una inferencia produce entre uno y cuatro pasos consecutivos. Los pasos contienen orden y etiqueta. Pydantic valida la estructura y el servidor conserva la etiqueta intacta en `search_term`. Las etiquetas se revisan según las reglas lingüísticas del SRS. El editor y la confirmación de rutinas admiten doce pasos. |
| CA-I4.7 | RF-I4.6 | Una coincidencia local pertinente tiene prioridad. Si falta, se consulta por la etiqueta exacta con artículos y preposiciones, una vez por texto idéntico. El primer resultado de ARASAAC se sugiere para aprobación humana. Una búsqueda vacía deja el paso pendiente. |
| CA-I4.8 | RF-I4.5–RF-I4.6 | Para cinco rutinas cotidianas, se registran tiempos de inferencia, consulta local, ARASAAC, asociación y respuesta total, además de etiquetas, consultas, IDs y palabras clave. La pertinencia visual se confirma durante la revisión manual. |
