# Iteración 2 — CU02, gestión de pictogramas

CU02 está implementado y cuenta con pruebas automáticas en API, widgets e integración HTTP real. La persona usuaria confirmó el recorrido manual en el simulador de iPad, incluida la importación de un PNG desde Archivos. La comprobación con rutinas reales queda para CU03.

| Unidad | Commit | Evidencia |
|---|---|---|
| Esquema y migración desde CU01 | `c114015` | [Casos de backend](results.json) |
| API, reglas y almacenamiento local | `9c2ad18`, `7bc35fc` | [Contrato y diseño](design.md) |
| Flutter y pruebas de widgets | `d89abad`, `c311854` | [Regresión](results.md) |
| Sonda Dart → FastAPI → SQLite y ARASAAC real | `7a0acd5` | [Resultados reproducibles](results.json) |

- **AINC421.** [Diseño, modelo, contrato y flujo](design.md).
- **AINC422.** [Plan frente a implementación, cobertura y resultados](results.md).
- **Revisión.** [Resultados de la comprobación manual en iPad](manual-check.md).

El SRS v0.2 define el alcance. Los registros técnicos de esta iteración se organizan por caso de uso, criterio, prueba y commit.
