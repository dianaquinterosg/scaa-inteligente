# Iteración 0 — cierre de la preparación técnica

**Estado:** cerrada funcionalmente por la persona usuaria.
**Commit asociado:** commit local que introduce esta carpeta, con asunto `chore: close iteration 0 technical baseline`. Obtener el SHA real mediante `git log -1 --format=%H --grep="^chore: close iteration 0 technical baseline$"`.

## Alcance planificado frente al implementado

| Funcionalidad | Alcance planificado | Alcance implementado y comprobado | Prueba / evidencia | Requisito relacionado |
|---|---|---|---|---|
| Backend y persistencia | FastAPI, configuración y SQLite aislado | Salud HTTP, archivos por entorno, FK, commit y rollback | [6 pruebas backend](backend/bootstrap-backend-tests.json) | Preparación de RNF04/RNF05; no cobertura funcional completa |
| Cliente | Flutter iOS y conexión al backend | Pantalla de salud, carga, error y reintento | [2 pruebas Flutter](flutter/bootstrap-flutter-test.log), [análisis](flutter/bootstrap-flutter-analyze.log) | Preparación técnica |
| ARASAAC | Consulta real y obtención de imagen | HTTP 200, alternativas y PNG comprobados | [Sonda real](integrations/bootstrap-integrations.json) | RF02.2 / CA02.3: viabilidad, CU02 pendiente |
| Ollama | Inferencia local estructurada | Tres propuestas reales con JSON y orden válidos | [Sonda real](integrations/bootstrap-integrations.json) | RF03.2 / CA03.2–CA03.3: viabilidad, CU03 pendiente |
| iPad | Compilar, arrancar y conectar | Build y arranque reportados; HTTP 200 y texto «Servidor disponible» confirmados por la persona usuaria | [Confirmación iPad](flutter/bootstrap-ipad-run-user.json) | Recorrido de salud, no T16 |

Los resultados corresponden a la preparación técnica y a las sondas de integración. La verificación de CU01–CU03 y de los objetivos del SRS requiere pruebas específicas. El diseño y análisis de la línea base permanecen como referencia; esta carpeta utiliza la numeración de Iteración 0 solicitada para el cierre técnico.

## Organización y procedencia

- `backend/`: pruebas de infraestructura y HTTP.
- `flutter/`: análisis, widgets, conectividad y arranque iPad.
- `integrations/`: resultados reales de ARASAAC y Ollama.
- `environment/`: versiones, instalación, restricciones y sondas de auditoría.
- [Resultados](test-results.md), [registro de alcance](implementation-log.md) y [entorno](environment/environment-audit.md).

Las copias documentales excluyen metadatos temporales y direcciones efímeras del depurador. Los originales brutos se conservaron localmente en `work/evidence-raw/iteration-0/`, fuera de Git. Las omisiones se señalan sin cambiar aprobaciones, fallos, códigos de salida ni contenido funcional de las respuestas. Los valores que son versiones de paquetes se conservan como identificadores técnicos.
