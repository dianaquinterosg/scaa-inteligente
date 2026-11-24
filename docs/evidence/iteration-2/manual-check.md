# Iteración 2 · Verificación manual en el simulador de iPad

**CU02.** Interfaz `d89abad` y vista previa `c311854`, integración `7a0acd5`. La compilación automatizada del simulador se intentó y no se completó por restricciones de Xcode/SPM y CoreSimulator en el entorno de ejecución. La persona usuaria confirmó que completó con éxito todos los pasos del recorrido propuesto en el simulador. La comprobación manual se registra por separado del intento automatizado de compilación.

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

| Prueba | Escenario comprobado | Estado y resultado reportado |
|---|---|---|
| I2-IPAD-01 | Buscar «agua», abrir una alternativa de ARASAAC, revisar imagen, etiqueta y atribución, rechazar y comprobar que no queda guardada | Ejecutado y aprobado |
| I2-IPAD-02 | Abrir de nuevo una alternativa, aprobar y guardar, y recuperarla como resultado local | Ejecutado y aprobado |
| I2-IPAD-03 | Descargar `vaso-prueba.png` desde Safari, seleccionarlo en Archivos, revisar la vista previa y guardarlo con etiqueta propia | Ejecutado y aprobado |
| I2-IPAD-04 | Crear «Higiene», asignarla a un pictograma, filtrar y eliminar la categoría conservando el pictograma | Ejecutado y aprobado |
| I2-IPAD-05 | Revisar la lectura de tarjetas y el acceso a botones en vertical y horizontal | Ejecutado y aprobado |

La confirmación corresponde a ese recorrido. JPG/WebP, renombrado, validaciones negativas, recuperación tras reinicio y dependencias SQLite se comprobaron en las pruebas automáticas indicadas en los [resultados](results.md). La verificación de una dependencia con una rutina real queda para CU03.
