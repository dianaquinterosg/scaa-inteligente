# Registro de cambios

## Desarrollo local — Iteración 3 CU03

- Generación estructurada con Ollama y contexto de perfil confirmado. Asociación determinística y revisión humana por paso.
- Editor guiado, creación manual, confirmación transaccional, recuperación, edición y borrado de rutinas.
- Regresión del catálogo con bloqueo de borrado por rutina real e integración con ARASAAC. Modelo provisional y revisión en iPad pendiente.

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
