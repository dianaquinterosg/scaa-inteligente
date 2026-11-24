# AINC422 · Resultados de CU02

| Alcance planificado | Alcance implementado | Verificación real |
|---|---|---|
| Reutilización local y consulta remota | Catálogo local primero, alternativas ARASAAC y aviso ante caída | API con transporte controlado, widgets e integración HTTP con ARASAAC real |
| Importación, revisión y confirmación | Validación de archivo y etiqueta, vista previa, aprobación o rechazo explícitos | API prueba PNG/JPG/WebP y rechazos. Los widgets usan un archivo sintético |
| Persistencia y consistencia | SQLite, archivo local, atribución, deduplicación y recuperación | Recuperación tras reiniciar, escritura fallida, recuperación de archivos tras interrupción y sonda HTTP |
| Categorías y borrado P1 | Crear, renombrar, filtrar, asignar y borrar categorías. Eliminar recursos con protección de FK | API, widgets y HTTP. La dependencia del pictograma se simuló con una FK restrictiva |
| Aplicación del diseño y revisión en tablet | Tema compartido, rejilla adaptable y navegación desde Inicio | Widgets en dos superficies lógicas. Revisión nativa en iPad pendiente |

## Pruebas ejecutadas

- Backend: **68 aprobadas**, entre ellas las regresiones de CU01. Se mantuvo el aviso de deprecación HTTPX/Starlette.
- Flutter: **21 aprobadas**, con 4 de CU02 y 17 del incremento anterior. `flutter analyze` sin incidencias.
- Sonda HTTP con ARASAAC real: **4 escenarios aprobados**. La app obtuvo 24 alternativas para «agua» en el límite de resultados del servicio, obtuvo los bytes de vista previa de la referencia 32464 mediante la API y recuperó su imagen de 5.566 bytes después de confirmar. El cliente Dart usó un proceso independiente y SQLite aislado.
- Regresión HTTP de CU01: **7 escenarios aprobados** en el mismo esquema de desarrollo, con base aislada.
- Compilación para simulador: `flutter build ios --simulator --debug` no completó la resolución de paquetes Swift. El entorno devolvió `sandbox-exec: sandbox_apply: Operation not permitted` y CoreSimulatorService inaccesible. La selección en Archivos y la revisión visual de CU02 quedan pendientes en Terminal normal.

En la primera corrida backend, Pydantic aceptó el número 1 como equivalente al literal booleano. Se agregó una comprobación estricta y el caso pasó con rechazo 422. Los widgets de vista previa necesitaron esperar la decodificación del motor y la transición de ruta en forma separada. También se ajustó el desplazamiento del catálogo para dejar visible el aviso de guardado. Los resultados finales se conservan por caso y commit.

## Cobertura

| Criterio | Alcance verificado |
|---|---|
| CA02.1–CA02.3 | Descripción válida, local primero, alternativas y recuperación de imagen en ARASAAC real |
| CA02.4–CA02.7 | Vista previa, archivo propio, validación y aprobación explícita. Flutter con archivo sintético; selector nativo pendiente |
| CA02.8–CA02.10 | Recuperación, referencia única y vía manual ante fallo remoto |
| CA02.11 | Borrado de registro y archivo sin dependencias |
| CA02.12 | Protección de FK y respuesta 409 verificadas con dependencia de prueba. Falta validar con una rutina real de CU03 |
| CA02.13–CA02.19 | Creación, validación de nombre, renombrado, asociación N:M, filtro, eliminación que preserva recursos y recuperación |

[Comandos, pruebas y cobertura por criterio](results.json) · [Diseño AINC421](design.md) · [Protocolo manual pendiente](manual-check.md). T16 y los indicadores académicos del recorrido completo corresponden a la evaluación integrada.
