# Iteración 4 · Usabilidad, controles y estabilización

Los cambios responden a la [validación del incremento anterior](../iteration-3/manual-check.md). Se registran como refinamientos sobre la [línea base v0.2](../../SRS.md).

| Alcance previsto | Implementación y evidencia |
|---|---|
| Proteger CU01–CU03 frente a cambios accidentales | Inicio en visualización, confirmación de acceso a administración y salida visible. El control reside en Flutter. `0fbf0dc` |
| Navegar por recursos aprobados | Catálogo de solo lectura con categorías y visor horizontal de pasos guardados, con el editor vertical disponible en administración. Avance parcial de CU05. `0fbf0dc` |
| Informar dependencias al eliminar pictogramas | HTTP 409 con código, mensaje e IDs y nombres de las rutinas deduplicados. Flutter muestra las dependencias y SQLite conserva su restricción. `0849ffb` |
| Estabilizar el incremento | Regresión automatizada de CU01–CU03 y prueba de la API por HTTP real. 16 comprobaciones manuales aprobadas en Device Hub según la persona usuaria. Liberación pendiente. |

## Resultados verificados

| Prueba | Resultado observado |
|---|---|
| I4-01 · CA-I4.1 | Widgets aprobaron arranque sin perfil, cancelación, entrada, salida, reinicio y salida durante una lectura administrativa en curso. |
| I4-02 · CA-I4.2 | Widgets aprobaron filtro por categoría, catálogo sin controles administrativos en visualización y acceso a controles existentes en administración. |
| I4-03 · CA-I4.3 | Widgets aprobaron 1 y 12 pasos en 820 × 1180 y 1180 × 820 píxeles lógicos, a escala de texto 2. Se verificaron el orden horizontal, el desplazamiento y el acceso al último paso. La regresión cubre el editor administrativo. |
| I4-04 · CA-I4.4–CA-I4.5 | Backend comprobó una y varias rutinas dependientes, deduplicación de pasos y rechazo SQLite. Una prueba de widgets comprobó nombres e IDs en el editor. [La prueba HTTP real](conflict-http.json) verificó que se conservaron las rutinas y la imagen al rechazar el borrado y que la última eliminación de pictograma devolvió 204. |
| I4-05 · CA-I4.5 | 95 pruebas backend y 33 pruebas Flutter aprobadas. `flutter analyze` sin incidencias. Pytest informó un aviso deprecatorio de Starlette sobre su cliente de pruebas. |

Comandos de regresión desde la raíz del repositorio:

```sh
.venv/bin/python -m pytest backend -q
cd frontend
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
```

La prueba HTTP usó Uvicorn y almacenamiento temporal aislado. Los widgets usaron almacenes de prueba. El modelo provisional de Ollama y el algoritmo de asociación continúan vigentes. CU04 y CU05 integral siguen planificados.

## Validación manual en Device Hub

La persona usuaria informó 16 comprobaciones ejecutadas y aprobadas. El [registro manual](manual-check.md) detalla cada resultado y los casos con evidencia automatizada que quedaron sin confirmación manual específica. La liberación permanece pendiente.

## Refinamientos previos a publicación

- [Diagnóstico y perfil provisional de generación](generation-quality.md). Comparación real con Ollama sobre los casos reservados.
- [Pantalla de bienvenida](welcome.md). Resultados de orientación, legibilidad y navegación mediante widgets. Aprobación visual en Device Hub pendiente.
- [Propuestas breves y filtro contextual de pictogramas](concise-routines.md). Comparación de las cinco rutinas cotidianas con Ollama y ARASAAC reales. Revisión en Device Hub pendiente.
- [Ensayo lingüístico con etiquetas exactas](linguistic-routines.md). Compara las cinco rutinas y las primeras sugerencias de ARASAAC. Incluye latencias por componente. Pertinencia visual pendiente.
- [Rango de tres a cinco pasos y revisión de candidatos](routine-label-fallback.md). Registra el contraste con los primeros resultados de ARASAAC y la ejecución manual confirmada por la persona usuaria. Las oportunidades de mejora pasan a la siguiente iteración.
