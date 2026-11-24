# Iteración 1 — diseño visual y regresión de CU01

La [lámina original](../../design/mockups-originales.png) y sus [lineamientos](../../design/README.md) se incorporaron en `44a420c`. El tema y los componentes compartidos corresponden a `6eb2d40`. Las pantallas y sus pruebas de adaptación corresponden a `bca2e58`. La persona usuaria confirmó que revisó CU01 en el simulador de iPad y aprobó su aspecto visual. La confirmación corresponde a la interfaz de `bca2e58`. No se reportaron resultados por escenario funcional, orientación, teclado ni VoiceOver.

## AINC421 · diseño

| Planificado | Implementado |
|---|---|
| Identidad de los flujos del anteproyecto | Material 3 con cabeceras azules, fondo celeste, tarjetas blancas, paneles de estado, acciones azules y confirmación verde |
| Aplicar la identidad a perfil y contexto | Alias en bloque propio, tres tarjetas de contexto, acciones visibles y avisos con icono y texto |
| Tablet vertical y horizontal | Ancho máximo para lectura y edición, dos columnas en el resumen amplio, formulario desplazable y barra de acciones adaptable |
| Navegación coherente con los módulos | Acceso real desde Inicio al perfil y regreso al resumen confirmado. Las demás entradas de la lámina quedan para sus iteraciones |
| Accesibilidad táctil y visual | Controles con etiquetas y ayuda en español, botón circular de eliminación con etiqueta accesible, avisos anunciables y texto ampliable |

La lámina muestra flujos de teléfono y carece de una pantalla de CU01. Su contraste y jerarquía guiaron un diseño propio para el formulario. La API, las validaciones de dominio y las migraciones son las de los commits funcionales de CU01.

## AINC422 · verificación ejecutada

| Prueba | Resultado real |
|---|---|
| Flutter, I1-FE | 17 aprobadas, incluidas 2 de conectividad y 2 de tablet con texto al 200 % |
| Backend, I1-BE | 45 aprobadas. Permanece la advertencia de deprecación HTTPX/Starlette |
| Dart → FastAPI → SQLite, I1-HTTP | 7 escenarios aprobados con datos aislados |
| I1-AN | `flutter analyze` sin incidencias |
| Contraste calculado de la paleta | 6,77:1 para cabecera, 6,44:1 para guardar, 11,45:1 para información y 10,35:1 para confirmación |
| CA01.1–CA01.10 | Se comprobó que las pruebas vinculadas en la matriz funcional pasaron en esta regresión |

Las pruebas de tablet usan superficies lógicas de 820 × 1180 y 1180 × 820. Comprueban el ancho del formulario, el objetivo táctil de eliminación de al menos 48 puntos, la cancelación y la ausencia de desbordamientos en el recorrido probado. La primera corrida de widgets detectó que la barra de acciones ocupaba el espacio del formulario. Al ajustar su altura quedó un fallo del mensaje de alias. Mantener estable la posición del campo al mostrar el aviso conservó su validación visible. La corrida final aprobó los 17 casos.

[Comandos y resultados por prueba](cu01/visual-regression.json) · [Matriz de aceptación](cu01/acceptance.json) · [Lista de comprobación manual en iPad](manual-check.md).
