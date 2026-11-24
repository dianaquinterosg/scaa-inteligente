# Iteración 1 — CU01, perfil y contexto

**Estado:** implementado y probado automáticamente; aspecto de CU01 aprobado por la persona usuaria en el simulador de iPad; pruebas funcionales manuales pendientes.
**Commit base real:** `db312e3592648a3b620d66b2ea22af018396112e` (cierre de Iteración 0).
**Commits de CU01:** esquema y migraciones `8486582`, API y validaciones `89647a9`, interfaz y widgets `f81d180`, prueba de integración `854180f`.

## Alcance planificado frente al implementado

| Funcionalidad | Alcance planificado | Alcance implementado | Resultado |
|---|---|---|---|
| Primer uso | Alias obligatorio; contexto opcional | GET distingue perfil ausente de error; formulario obligatorio; Inicio al guardar | Probado automáticamente |
| Perfil y contexto | Crear, consultar y editar perfil único | GET/PUT, edición de alias y elementos individuales de los tres tipos | API, widgets y HTTP real aprobados |
| Validaciones | Trim, límite 50 y duplicados por tipo | Validación independiente en API y Flutter; unicidad casefold en backend | Casos válidos e inválidos probados |
| Persistencia | Guardado íntegro | Migración SQL, transacción de perfil/contexto y rollback | Fallo real mediante trigger SQLite y recuperación tras reiniciar probados |
| Confirmación | Borradores sin incorporar y cancelación segura | Cancelar conserva datos previos; errores conservan edición; solo GET devuelve contexto confirmado | Probado automáticamente |
| Aceptación visual | Revisar el aspecto de CU01 en el simulador de iPad | La persona usuaria revisó y aprobó la interfaz | [Aprobación visual](visual.md); escenarios funcionales manuales pendientes |

La Iteración 1 se limitó a CU01. El acceso a contexto confirmado está probado para CU01; su consumo por personalización IA debe verificarse al implementar CU03.

## Evidencias por requisito y prueba

[CA01.1–CA01.10](cu01/acceptance.json), [45 pruebas backend](cu01/backend-tests.json), [15 pruebas Flutter](cu01/flutter-tests.json), [7 escenarios HTTP reales](cu01/live-http.json), [análisis Dart](cu01/analyze.json).

- [Diseño y contratos para AINC421](design.md).
- [Planificado frente a implementado y evidencias para AINC422](results.md).
- [Comprobación manual pendiente](manual-check.md).
- [Código entregado](cu01/source-snapshot.json): hashes de la base funcional `854180f`.

El [incremento visual y su regresión](visual.md) están asociados a `44a420c`, `6eb2d40` y `bca2e58`.

Los registros documentales omiten metadatos temporales. Los datos de las pruebas son sintéticos y las bases de prueba se aislaron del perfil dev/demo.
