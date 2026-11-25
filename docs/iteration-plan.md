# Plan de iteraciones funcionales — línea base documental v0.2

**Estado:** planificación funcional con resultados reales registrados por alcance en la sección 4; las actividades propuestas no se consideran ejecutadas sin evidencia. La v0.2 es la primera línea base documental publicada en Git.
**Método:** iteraciones funcionales con dependencias técnicas, entregables y criterios de salida, sin fechas ni estimaciones horarias.

Esta organización no reconstruye la cronología del proyecto ni atribuye un calendario a las revisiones locales anteriores. La publicación de la línea base documental no demuestra la ejecución de las actividades de desarrollo y pruebas previstas aquí.

## 1. Objetivo del incremento

Mostrar un recorrido funcional integrado de CU01, CU02 y CU03; demostrar inferencia local de IA **real** en CU03 (si supera la prueba de viabilidad), búsqueda ARASAAC, guardado con SQLite, pruebas, instalación reproducible, comparación plan/real y trazabilidad a código. El **60 % se define inicialmente por alcance de 3/5 CU, no por esfuerzo demostrado**.

## 2. Prioridades y condiciones de salida

- **P0 — esencial para demo end-to-end:** CU01 completo; CU02 consulta local/ARASAAC, archivo propio, vista previa, confirmación, persistencia y categorías N:M básicas; CU03 IA real→pasos→preselección revisable→corrección→guardado y recuperación. Incluye verificación de que ninguna propuesta no confirmada se persiste.
- **P1 — complementario comprometido:** mantenimiento avanzado de categorías, edición/borrado protegido de pictogramas y rutinas, y algunos fallbacks. Si queda pendiente, declarar **CU parcial**, aunque P0 pase.
- **P2 — posterior:** CU04, CU05 integral, voz, generación de imágenes IA y asociación contextual avanzada. RF02.3 permanece en la visión del MVP completo.

La lista precisa de criterios se encuentra en [use-cases.md](use-cases.md), sección «Matriz de prioridad». De los **44 criterios de CU01–CU03**, **37 son P0 y 7 son P1**; este conteo describe la distribución de prioridades. El esfuerzo y la cobertura se verifican por separado.

## 3. Iteraciones funcionales propuestas

| Iteración | Objetivo y entregables previstos | Prioridad | Dependencias técnicas |
|---|---|---|---|
| 0 — Análisis, requisitos y diseño | Consolidar SRS, casos de uso, diagramas UML, arquitectura, modelo de datos, decisiones, trazabilidad y plan de pruebas de la línea base v0.2 | P0; identificación de P1/P2 | Coherencia entre requisitos, casos de uso y criterios de aceptación; revisiones locales como antecedentes, sin atribuirles fechas ni evidencias de ejecución |
| 1 — CU01: perfil y contexto | Configurar entornos dev/test/demo y esqueleto Flutter/FastAPI/SQLite; implementar perfil/contexto en backend y pantalla, persistencia y pruebas | P0 | Iteración 0; API y persistencia disponibles antes de integrar la pantalla |
| 2 — CU02: pictogramas y ARASAAC | Búsqueda local/ARASAAC, selección, importación, revisión, persistencia, categorías N:M y pruebas; administración avanzada y borrado protegido según los criterios P1 | P0/P1 | Iteración 1; prueba técnica real de la API ARASAAC; almacenamiento de imágenes y relaciones N:M |
| 3 — CU03: rutinas asistidas por IA | Propuesta IA local, asociación provisional, edición, confirmación, persistencia y pruebas; edición/borrado de rutinas y creación manual ante fallo IA según los criterios P1 | P0/P1 | Iteración 2; prueba de viabilidad Ollama→JSON validado; recursos aprobados de CU02 y consistencia SQLite/archivos |
| 4 — Integración, pruebas y liberación | Integrar CU01–CU03, ejecutar pruebas y recopilar evidencias; verificar instalación release/demo, registrar resultados y desviaciones, preparar release notes, tag y video cuando corresponda | P0; verificación y reporte de P1 | Incrementos de las iteraciones 1–3; criterios de salida verificados y brechas documentadas antes de declarar cobertura |

Las pruebas técnicas de ARASAAC y de IA local pueden prepararse tras el diseño y deben verificarse antes de aceptar los flujos que dependen de ellas. Su inclusión en el plan no afirma que hayan sido ejecutadas.

Las pruebas de cada caso de uso se preparan y ejecutan en su iteración; la iteración 4 verifica además la integración y la liberación. P1 permanece comprometido en CU02/CU03; P2 conserva el alcance posterior al 60 % definido en la sección 2.

## 4. Registro de ejecución real, evidencia y desviaciones

Los campos se completarán únicamente con hechos y evidencia verificable. Los guiones significan información no registrada; no permiten inferir actividades realizadas ni resultados históricos.

| Iteración | Ejecución real / resultado | Estado (`Logrado/Parcial/No logrado`) | Evidencia (commit, issue, test) | Desviación / causa | RF/CU/CA afectados | Decisión / responsable |
|---|---|---|---|---|---|---|
| 0 — Análisis, requisitos y diseño | Línea base y preparación técnica cerradas funcionalmente por la persona usuaria | Logrado para el cierre técnico autorizado | [Iteración 0](evidence/iteration-0/README.md), `db312e3592648a3b620d66b2ea22af018396112e` | El cierre técnico usa la numeración solicitada sin reconstruir la elaboración local | Preparación previa a CU01–CU03 | Cierre funcional confirmado por la persona usuaria |
| 1 — CU01: perfil y contexto | Frontend, API, persistencia, validaciones y pruebas automáticas implementados | Cierre documental: aspecto aprobado en simulador | [Iteración 1](evidence/iteration-1/README.md); base funcional `854180f` y adaptación visual `bca2e58` | Escenarios funcionales manuales aprobados según la persona usuaria | RF01.1–RF01.3 / CA01.1–CA01.10 | Aprobación visual registrada; CU02 habilitado |
| 2 — CU02: pictogramas y ARASAAC | Búsqueda local y real, revisión, importación, persistencia, administración y categorías N:M | Implementado, con pruebas automáticas y recorrido manual confirmados | [Iteración 2](evidence/iteration-2/README.md) | Build automatizado bloqueado en el entorno. La revisión en simulador fue confirmada por la persona usuaria. Dependencia con rutina real verificada en las iteraciones 3 y 4 | RF02.1–RF02.2, RF02.4–RF02.9 / CA02.1–CA02.19 | Revisión antes de CU03 |
| 3 — CU03: rutinas asistidas por IA | Generación local, asociación, editor manual, revisión y persistencia transaccional | Implementado y probado automáticamente | [Iteración 3](evidence/iteration-3/README.md) | Modelo provisional. La persona usuaria confirmó la aprobación de los escenarios manuales. T16 pendiente | RF03.1–RF03.8 / CA03.1–CA03.15; RF01.2 y CA02.12 integrados | Mejoras reservadas para la siguiente iteración |
| 4 — Usabilidad, controles y estabilización | Visualización predeterminada, acceso deliberado a administración, catálogo de consulta, visor horizontal y conflicto con dependencias | Pruebas automáticas aprobadas y 16 comprobaciones manuales aprobadas según reporte | [Iteración 4](evidence/iteration-4/README.md) | Liberación pendiente de aprobación | RF-I4.1–RF-I4.4 / CA-I4.1–CA-I4.5; CU05 parcial | Estabilizar el incremento sin sustituir modelo ni asociación |

Registrar el motivo y la evidencia de cada desviación, el RF/CU/CA afectado y su impacto en los criterios de salida. No presentar esta planificación propuesta como una reconstrucción de la ejecución histórica.

## 5. Criterios de salida por punto de control

1. **Análisis y diseño (iteración 0):** SRS, casos de uso, diagramas, modelo de datos, decisiones, trazabilidad y plan de pruebas coherentes; distinguir especificación documental de implementación verificada.
2. **Viabilidad IA (previa a la aceptación de CU03):** ejecutar un modelo local realmente y obtener **tres** propuestas JSON válidas para rutinas distintas, registrando modelo, equipo, latencia observada, fallos y calidad revisada. Si no funciona, registrar decisión; un fake de tests **no** sustituye evidencia de IA real.
3. **CU01 (iteración 1):** perfil se crea/edita/recupera desde Flutter→API→BD, con tests de duplicados y errores.
4. **CU02 (iteración 2):** consulta real ARASAAC, respuesta con imagen, revisión/guardado, carga propia, categorías N:M y recuperación; fallos externos cubiertos por pruebas controladas.
5. **CU03 (iteración 3):** propuesta de IA real, asociaciones automáticas **provisionales**, posibilidad de corregir, bloqueo de pasos sin recurso, confirmación/persistencia, reconsulta de rutina. Tests con `FakeRoutineGenerator` son **adicionales**, no la prueba de IA real.
6. **Estabilización (iteración 4):** regresión automática y validación manual de los refinamientos. La liberación prevista en la línea base se mantiene pendiente de aprobación, con instrucciones verificadas, entorno demo independiente, tag y notas de versión.

## 6. Estrategia de contingencia

- Priorizar flujos de valor completos: búsqueda de pictograma y generación visual de rutina. **No declarar cumplimiento del 60 % simplemente por contar tres CU**.
- Si falla la IA local, validar alternativa técnica y documentar desviación antes de sustituir el componente; no presentar un generador fijo como IA.
- Si quedan criterios P1 pendientes, registrar la desviación y reportar los casos de uso afectados como **parciales**, sin retirar esos criterios del compromiso. No ocultar restricciones offline/de instalación.
- Mientras el incremento se ejecute localmente, documentar el entorno **release/demo** con un procedimiento de instalación verificable. Registrar un despliegue de producción únicamente cuando se haya comprobado.

## 7. Artefactos de verificación y liberación

- Alcance y diagramas UML; modelo de datos y funcionalidades realmente evaluadas.
- Planificación propuesta, registro de resultados reales y desviaciones respaldadas por evidencia.
- Análisis y diseño finales *as-built*, diferenciados de versión propuesta.
- Pruebas unitarias/integración, smoke test externo/IA real, captura de UI y ejecución.
- Instructivo de instalación verificado, línea base/tag, release notes, matriz RF→código→test→evidencia.
- Demo con datos sintéticos y conclusiones respaldadas, sin inventar métricas.

Véase [test-plan.md](test-plan.md) para el detalle de pruebas y release.
