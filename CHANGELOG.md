# Registro de cambios

## v0.3.0 — Incremento de Iteración 4

- Bienvenida adaptada a iPad y separación entre visualización y administración.
- Catálogo de consulta y visor horizontal de rutinas. El borrado protegido informa las rutinas dependientes.
- Demo con Qwen3 4B Instruct y perfil `linguistic`. Incluye de tres a cinco pasos por propuesta y revisión de candidatos de ARASAAC.
- 135 pruebas de backend y 36 de Flutter aprobadas, análisis estático sin incidencias y validación final aprobada en Device Hub.
- Instalación en iPad físico pendiente para la siguiente iteración. La línea base documental se conserva en v0.2.

[Notas de la versión](docs/releases/v0.3.0.md) · [Evidencias de Iteración 4](docs/evidence/iteration-4/README.md)

## Desarrollo local — Iteración 3 CU03

- Generación estructurada con Ollama y contexto de perfil confirmado. Asociación determinística y revisión humana por paso.
- Editor guiado, creación manual, confirmación transaccional, recuperación, edición y borrado de rutinas.
- Regresión del catálogo con bloqueo de borrado por rutina real e integración con ARASAAC. Modelo provisional. Ejecución manual en simulador reportada por la persona usuaria.

## Desarrollo local — Iteración 2 CU02

- Búsqueda local y ARASAAC, selección y revisión, importación, catálogo con archivos locales y categorías N:M.
- Regresión automática aprobada y sonda HTTP con ARASAAC real. Recorrido manual de CU02 confirmado en el simulador de iPad.

## Desarrollo local — Iteración 1, CU01 (sin release)

- Perfil único y contexto: frontend, GET/PUT, validaciones y persistencia atómica con migración SQL.
- Evidencias automáticas de API, widgets y HTTP real organizadas por criterio; aspecto aprobado en el simulador de iPad y pruebas funcionales manuales pendientes.
- Iteración 0 cerrada en un commit local; CU01 se conserva en commits locales por responsabilidad.
- La identificación documental sigue siendo v0.2; no se declara el MVP completo ni CU02/CU03 implementados.

## docs-v0.2 — revisión de consistencia, sin implementación

Primera línea base documental publicada en Git, consolidada tras revisiones locales.

- Se introduce P0/P1/P2 para gestionar alcance sin presentar casos de uso parciales como completos.
- Se precisa la política determinística de asociación de pictogramas y los límites de la preselección.
- Se agregan diagramas UML fuente (casos de uso y secuencia CU03).
- Se estructura la planificación en iteraciones funcionales, identificando dependencias, entregables y criterios de salida, e incorporando un registro para documentar la ejecución real y sus desviaciones respecto de lo planificado.
- Se amplía trazabilidad por subrequisito con evidencias aún pendientes.
- Se agrega plan de pruebas y checklist de release/instalación con estados sin verificar.
- Se actualizan referencias internas a `docs-v0.2`; no se afirma ejecución de código ni pruebas.

## docs-v0.1 — versión de trabajo local (antecedente no publicado)

- Se consolidan los requisitos RF01–RF05, casos de uso CU01–CU03 y alcance posterior CU04–CU05.
- Se registra que la generación de imágenes con IA queda **después de la entrega del 60 %, no fuera del MVP completo**.
- Se documentan categorías N:M, reutilización de pictogramas, propuesta de IA local, validación humana y pruebas pendientes.
- Se crea plan de iteraciones, modelo de datos, arquitectura preliminar y matriz de trazabilidad.

**Importante:** Esta versión corresponde exclusivamente a documentación y no es una release funcional.
