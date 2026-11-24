# Registro de decisiones — v0.2

**Propósito:** preservar decisiones conocidas y comparar planificación versus realización. Los acuerdos funcionales de diseño se documentan como **propuestos para la implementación**, no como resultados.

| ID | Decisión | Motivo / impacto | Estado |
|---|---|---|---|
| ADR-001 | Entrega parcial incluye CU01, CU02, CU03 | Incremento de 3/5 CU para demostrar personalización, recursos y rutina con IA; no equivale a 60 % de esfuerzo demostrado | Acordado |
| ADR-002 | Alias obligatorio, contexto opcional y tags individuales | Reducir errores y favorecer reutilización estructurada | Acordado |
| ADR-003 | Buscar local antes de ARASAAC | Reutilización, menor dependencia y menos operaciones externas | Acordado |
| ADR-004 | Importar imagen propia para alternativa del 60 % | Permitir completar recursos sin segundo modelo de generación de imágenes | Acordado |
| ADR-005 | Generación de pictogramas/imágenes con IA **posterior al 60 %, prevista hacia MVP completo** | Mantiene visión inicial; requiere validación técnica y visual | Acordado en alcance; no implementado |
| ADR-006 | Categorías configurables N:M | Un pictograma puede facilitar acceso en distintos contextos sin duplicar datos | Acordado |
| ADR-007 | Mismo pictograma reutilizable en varias rutinas y pasos | Evitar copias y soportar repeticiones reales | Acordado |
| ADR-008 | IA propone pasos, no aprueba datos | Validación humana y responsabilidad clara del módulo | Acordado |
| ADR-009 | Preselección automática básica de pictogramas en CU03 | Minimizar trabajo manual; no confundir con recomendación contextual avanzada | Acordado |
| ADR-010 | Todos los pasos necesitan pictograma aprobado para guardar rutina | Mantener utilidad visual; pasos incompletos siguen en edición | Acordado |
| ADR-011 | Flutter + FastAPI + SQLite + archivos | Arquitectura sencilla y comprobable | Diseño propuesto |
| ADR-012 | Ollama como adaptador de IA local, modelo por seleccionar | Control de datos e independencia de nube de IA; latencia/calidad pendientes | **Sujeto a prueba** |
| ADR-013 | RF04/CU04, RF05/CU05 integral y voz para iteraciones posteriores | Priorizar funciones centrales del MVP parcial | Acordado |
| ADR-014 | No confundir IA local con producto iPad totalmente offline | Backend necesita red local; ARASAAC necesita Internet | Acordado |
| ADR-015 | Priorizar criterios P0/P1/P2 sin eliminar alcance | Evitar dispersión por plazo; registrar cualquier criterio no logrado y no declarar CU completo sin evidencia | Acordado |
| ADR-016 | Política de preselección textual determinística | Normalización, ranking exacta/prefijo/contiene, empate sin selección y candidato ARASAAC marcado para revisión | Acordado para diseño; evaluar pertinencia real |
| ADR-017 | Documentar UML y evidencia plan/real antes de implementación | Los diagramas, el control de configuración, el procedimiento de instalación y la trazabilidad permiten contrastar la implementación verificada con lo planificado | Acordado |
| ADR-018 | CU01 usa sqlite3 y migraciones SQL numeradas con PRAGMA user_version | Reutiliza SQLite sin incorporar ORM; cada migración se aplica en transacción y se rechaza un esquema posterior al soportado | Implementado y probado en Iteración 1 |
| ADR-019 | Validación independiente en Flutter y API; unicidad por tipo mediante clave casefold | El backend es autoridad sobre entradas y duplicados Unicode; el borrador no se incorpora hasta guardar íntegramente | Implementado y probado en Iteración 1 |
| ADR-020 | Compartir unidad de escritura de SQLite y archivos para catálogo y rutinas | Completar red y validación antes de la transacción, reutilizar referencias y compensar nuevos archivos en un rollback | Implementado y probado en Iteración 3 |
| ADR-021 | Usar Ollama local con esquema y mantener creación manual | Validar respuestas estrictamente, limitar contexto y exigir revisión humana. La calidad observada no justifica consolidar el modelo provisional | Implementado y probado con modelo provisional |

## Plantilla de futuras desviaciones

```text
ID:
Iteración / funcionalidad:
Plan original:
Resultado/modificación:
Motivo y evidencia:
RF/CU afectados:
Impacto en alcance, criterios y pruebas:
Decisión y responsable:
Commit/PR/tag:
```

## Riesgos no resueltos

- Modelo local, memoria/latencia, confiabilidad de estructura JSON y criterios para detectar asociaciones ambiguas.
- Licenciamiento/atribución aplicables al almacenamiento y distribución de imágenes ARASAAC.
- Instalación reproducible en un entorno de release/demo y accesibilidad desde iPad.
