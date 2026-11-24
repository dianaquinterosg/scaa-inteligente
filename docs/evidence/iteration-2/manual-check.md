# Iteración 2 · Revisión en iPad pendiente

**CU02.** Interfaz `d89abad` y vista previa `c311854`, integración `7a0acd5`. La compilación automatizada del simulador se intentó y no se completó por restricciones de Xcode/SPM y CoreSimulator en el entorno de ejecución. No se obtuvo revisión en iPad de CU02.

Desde la raíz y con el servidor anterior detenido, instalar las dependencias en el entorno virtual existente y arrancar:

```sh
.venv/bin/python -m pip install -r backend/requirements.txt
.venv/bin/python -m uvicorn scaa_backend.main:app --app-dir backend --env-file backend/.env.example --host 127.0.0.1 --port 8000
```

En otra Terminal, arrancar Flutter de nuevo para registrar el plugin del selector nativo:

```sh
cd frontend
flutter pub get
flutter run -d A8EF03DC-81E7-4B9A-AD7E-F9E4235468FC --dart-define=API_BASE_URL=http://localhost:8000
```

Desde Inicio, abrir **Pictogramas**. Usar imágenes sintéticas para la evidencia.

| Escenario | Resultado esperado | Resultado en iPad |
|---|---|---|
| Buscar «agua» y abrir alternativa | Vista previa, etiqueta y atribución visibles | Pendiente |
| Rechazar alternativa | El recurso no aparece guardado | Pendiente |
| Importar PNG/JPG/WebP desde Archivos | Selector nativo, vista previa y aprobación explícita | Pendiente |
| Cancelar selección o rechazar desde la vista previa | Regreso al catálogo sin guardar | Pendiente |
| Crear, asignar, filtrar, renombrar y eliminar categoría | Catálogo y otras asociaciones se conservan | Pendiente |
| Guardar, cerrar y volver a abrir | Se recuperan texto, imagen y categorías | Pendiente |
| Vertical, horizontal y texto ampliado | Rejilla, botones y mensajes legibles y alcanzables | Pendiente |
