# Iteración 4 · Validación manual en iPad

**Estado:** pendiente de verificación y aprobación. Utiliza datos de prueba. Los tamaños de tablet verificados en widgets están documentados en [las evidencias](README.md).

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

| Escenario | Resultado |
|---|---|
| Arranque, acceso, cancelación y salida | Pendiente |
| Catálogo aprobado y filtro | Pendiente |
| Visor en ambas orientaciones con 1 y 12 pasos | Pendiente |
| Edición administrativa y conflicto con dependencias | Pendiente |
