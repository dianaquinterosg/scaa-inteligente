# Plan de pruebas y evidencias — MVP 60 % (v0.2)

**Estado:** T01–T03 tienen pruebas automáticas aprobadas para CU01; pruebas funcionales manuales en iPad pendientes. T08 se ejecutó como sonda técnica de inferencia real. Los demás casos funcionales siguen sin ejecutar. Ver [Iteración 0](evidence/iteration-0/test-results.md) e [Iteración 1](evidence/iteration-1/results.md); no se declara CU02 ni CU03 completo.

## 1. Niveles y herramientas tentativas

| Nivel | Qué verificar | Implementación propuesta | Estado |
|---|---|---|---|
| Unitarias | Normalizaciones, validaciones, clasificación, integridad de pasos | `pytest` + `pytest-asyncio` si aplica | CU01 probado; restantes pendientes |
| Integración API/BD | FastAPI, SQLite, transacciones, persistencia y FKs | `TestClient`/cliente ASGI, BD de test aislada | CU01 y migraciones probados |
| Integración servicios externos controlada | Timeout/respuesta/error ARASAAC y adaptador IA | Fake/stubs en tests automatizados | Pendiente |
| Smoke test REAL | ARASAAC conectado e IA ejecutándose localmente | Script/endpoint manual con evidencias y datos sintéticos | Sondas de Iteración 0 aprobadas; integración funcional CU02/CU03 pendiente |
| Sistema E2E | Flutter→FastAPI→persistencia→consulta | Recorrido manual reproducible y capturas | CU01 HTTP real probado; aspecto de CU01 aprobado en simulador; recorrido funcional manual y T16 pendientes |
| Instalación release/demo | Instalación desde instrucciones y arranque | Procedimiento documentado tras verificación | Pendiente |

## 2. Casos mínimos concretos

| ID de prueba | CU / CA | Escenario y resultado esperado | Estado | Evidencia |
|---|---|---|---|---|
| T01 | CU01 / CA01.1, CA01.8 | Guardar perfil y recuperar alias/tags | Aprobado automáticamente; prueba funcional manual pendiente | [Criterios y pruebas CU01](evidence/iteration-1/cu01/acceptance.json) |
| T02 | CU01 / CA01.4–CA01.7 | Rechazar alias vacío, tags inválidos y duplicados normalizados | Aprobado automáticamente; prueba funcional manual pendiente | [Criterios y pruebas CU01](evidence/iteration-1/cu01/acceptance.json) |
| T03 | CU01 / CA01.9 | Error simulado de BD no reemplaza perfil existente | Aprobado automáticamente; prueba funcional manual pendiente | [Criterios y pruebas CU01](evidence/iteration-1/cu01/acceptance.json) |
| T04 | CU02 / CA02.2–CA02.3 | Coincidencia local sin llamada externa; ausencia local consulta ARASAAC | No ejecutado | — |
| T05 | CU02 / CA02.5–CA02.7 | Archivo propio válido se incorpora solo tras aprobar; inválido se rechaza | No ejecutado | — |
| T06 | CU02 / CA02.8–CA02.9 | Pictograma ARASAAC persistido; intento duplicado no crea nueva fila | No ejecutado | — |
| T07 | CU02 / CA02.13–CA02.19 | Categorías N:M y filtrado; nombre duplicado no aceptado | No ejecutado | — |
| T08 | CU03 / CA03.2 | IA local REAL entrega 3 rutinas estructuradas válidas (registrar modelo, equipo y resultado) | Ejecutado como sonda técnica; integración CU03 y calidad pendientes | [Inferencia real](evidence/iteration-0/integrations/bootstrap-integrations.json), [equipo y entorno](evidence/iteration-0/environment/environment-audit.md) |
| T09 | CU03 / CA03.4–CA03.5 | Exacta local > prefijo > contiene; empate local sin selección arbitraria | No ejecutado | — |
| T10 | CU03 / CA03.4, CA03.15 | ARASAAC sugiere candidato temporal; cancelar propuesta no crea filas | No ejecutado | — |
| T11 | CU03 / CA03.7, CA03.13–CA03.14 | Reordenar/repetir recurso, bloquear guardado de paso sin pictograma | No ejecutado | — |
| T12 | CU03 / CA03.8–CA03.9 | Confirmación guarda rutina/pasos/imágenes aprobadas y permite recuperarlos | No ejecutado | — |
| T13 | CU03 / CA03.15 | Falla simulada de persistencia deja BD consistente y limpia temporales | No ejecutado | — |
| T14 | CU03 / CA03.11 (P1) | IA caída → posibilidad de creación manual; si no se implementa, documentar brecha | No ejecutado | — |
| T15 | CU02/CU03 / P1 | Editar/borrar con integridad: imagen usada no se elimina; borrar rutina conserva imagen | No ejecutado | — |
| T16 | E2E | Primera configuración → incorporar pictograma → rutina IA → revisar → guardar → recuperar | No ejecutado | — |

## 3. Validación de calidad de la asociación (sin cifras inventadas)

Preparar una lista identificada por iteración y prueba, con descripciones y pasos esperados. En cada ejecución registrar: `search_term`, candidato local/ARASAAC, decisión humana (`adecuado`, `corregir`, `sin resultado`) y número de correcciones. El orden de resultados de ARASAAC no implica que el primer pictograma sea correcto. La regla de desempate no usa IA ni umbrales inventados.

## 4. Entornos y línea base

- **Dev:** configuración local, BD y archivos de desarrollo.
- **Test:** BD de test aislada, pruebas con fakes y servicios reales **solo** en smoke tests identificados.
- **Release/demo:** ejecutables/servicios y BD separada de prueba; publicar únicamente cuando se haya verificado procedimiento de instalación y haya resultados de tests documentados.

El entregable de control debe incluir: SHA de commit, tag (por ejemplo `v0.6.0-mvp` **solo cuando exista**), contenido de release notes, versión de Python/Flutter/modelo, comandos de instalación *probados*, variables de entorno necesarias sin secretos, resultados de suite y capturas identificadas por iteración, funcionalidad, requisito, prueba y commit. No afirmar «producción desplegada» si solo existe demo local.

## 5. Registro de ejecución por alcance

| Iteración / funcionalidad | Commit asociado | Pruebas y resultado | Evidencia | Pendiente |
|---|---|---|---|---|
| 0 — preparación técnica | `db312e3592648a3b620d66b2ea22af018396112e` | 6 backend, 2 Flutter y sondas reales aprobadas; iPad confirmado por la persona usuaria | [Cierre](evidence/iteration-0/README.md) | Limitaciones del modelo provisional |
| 1 — CU01 | Implementación funcional `854180f` y adaptación visual `bca2e58` | 45 backend, 17 Flutter y 7 escenarios HTTP reales aprobados. Análisis sin incidencias | [Regresión visual](evidence/iteration-1/visual.md) | Aspecto aprobado en simulador; pruebas funcionales manuales pendientes |

Los registros documentales excluyen metadatos temporales. Los resultados se asocian al alcance y al código real, sin atribuir un commit inexistente.

## 6. Evaluación de objetivos

OE1/OE2 requieren comparar tareas equivalentes del proceso de referencia y del prototipo en condiciones definidas y registrar **tiempo e interacciones**. OE4 requiere participantes y tareas de usabilidad con asistencia observada. No usar porcentajes como «resultados» mientras no hayan sido medidos.
