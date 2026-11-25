# Iteración 4 · Validación manual en iPad

**Estado:** 16 comprobaciones ejecutadas y aprobadas en el simulador de iPad mediante Device Hub, según el reporte de la persona usuaria. La [regresión automatizada](README.md) se registra por separado.

1. Inicia el backend desde la raíz del proyecto. Ejecuta Flutter en otra terminal con el simulador de iPad abierto.

   ```sh
   SCAA_ENV=demo SCAA_DATA_ROOT="$(mktemp -d)" .venv/bin/python -m uvicorn scaa_backend.main:app --app-dir backend --env-file backend/.env.example --host 127.0.0.1 --port 8014
   ```

   ```sh
   cd frontend
   flutter run -d A8EF03DC-81E7-4B9A-AD7E-F9E4235468FC --dart-define=API_BASE_URL=http://localhost:8014
   ```

2. Comprueba el modo visualización al iniciar. Abre el acceso a administración y cancela. Comprueba que la pantalla permanece en visualización. Para preparar los datos sintéticos, entra luego a administración, configura un alias, importa una imagen y crea manualmente dos rutinas (1 y 12 pasos), reutilizando ese pictograma. Regresa a visualización.
3. En Pictogramas, cambia de categoría. Comprueba que se muestran imágenes y etiquetas, sin botones para abrir, editar o importar.
4. En Rutinas, abre una de un paso y otra de doce. Comprueba el orden de izquierda a derecha y que el último paso sea alcanzable. Gira el iPad y repite la comprobación en la otra orientación.
5. Confirma el acceso a administración. Abre Perfil y contexto, comprueba que los editores del catálogo estén disponibles y abre una rutina con el editor vertical. Para preparar una rutina de prueba, usa «Crear manualmente».
6. Vincula un pictograma a dos rutinas de prueba e intenta eliminarlo desde el catálogo. Comprueba el mensaje con ambos nombres e identificadores y vuelve a abrir las dos rutinas.
7. Usa «Volver a visualización» y comprueba que los controles de modificación queden ocultos. Reinicia la aplicación y comprueba que inicia en visualización.

## Resultados manuales reportados

| Prueba | Criterio relacionado | Comprobación | Resultado |
|---|---|---|---|
| I4-M01 | CA-I4.1 | La aplicación inicia en modo visualización. | Ejecutada y aprobada |
| I4-M02 | CA-I4.1–CA-I4.2 | En visualización se ocultan los botones de creación, edición y eliminación. | Ejecutada y aprobada |
| I4-M03 | CA-I4.2 | Se consultan pictogramas y se filtran por categoría. | Ejecutada y aprobada |
| I4-M04 | CA-I4.1 | El acceso a administración solicita confirmación. | Ejecutada y aprobada |
| I4-M05 | CA-I4.1 | Se puede regresar a visualización desde administración. | Ejecutada y aprobada |
| I4-M06 | CA-I4.2 | Se mantienen las operaciones de gestión del perfil. | Ejecutada y aprobada |
| I4-M07 | CA-I4.2–CA-I4.3 | Se mantienen los editores de pictogramas y rutinas. | Ejecutada y aprobada |
| I4-M08 | CA-I4.3 | Los pasos aparecen horizontalmente y en orden. | Ejecutada y aprobada |
| I4-M09 | CA-I4.3 | Las imágenes y etiquetas son legibles. | Ejecutada y aprobada |
| I4-M10 | CA-I4.3 | El visor funciona en orientación vertical. | Ejecutada y aprobada |
| I4-M11 | CA-I4.3 | El visor funciona en orientación horizontal. | Ejecutada y aprobada |
| I4-M12 | CA-I4.3 | Es posible desplazarse hasta el paso 12. | Ejecutada y aprobada |
| I4-M13 | RF-I4.3 | El visor se limita a presentar los pasos, con ausencia de controles de seguimiento de progreso. | Ejecutada y aprobada |
| I4-M14 | CA-I4.4 | Al intentar eliminar un pictograma utilizado, se muestran las rutinas dependientes. | Ejecutada y aprobada |
| I4-M15 | CA-I4.4–CA-I4.5 | Tras el rechazo, el pictograma y su imagen permanecen disponibles. | Ejecutada y aprobada |
| I4-M16 | CA-I4.5 | El pictograma se puede eliminar después de retirar sus referencias. | Ejecutada y aprobada |

I4-M01–I4-M13 se vinculan con la implementación `0fbf0dc`. I4-M14–I4-M16 se vinculan con `0849ffb`.

Quedan sin confirmación manual específica la cancelación del diálogo, el reinicio desde administración, el visor de una rutina de un paso y el cotejo de IDs y cantidad de dependencias. Esos casos conservan su [evidencia automatizada](README.md). La liberación permanece pendiente de aprobación.
