# Iteración 3 — Verificación manual en simulador de iPad

Estado: la persona usuaria confirmó que ejecutó y aprobó todos los escenarios manuales de CU03 en el simulador y que prevé mejoras en la siguiente iteración. Las mejoras quedan por detallar en la siguiente iteración. El intento automatizado de compilación encontró restricciones de Xcode y CoreSimulator. La evidencia automatizada se conserva en el [registro de la iteración](README.md).

En una Terminal del Mac, inicia Ollama si el puerto local 11434 está libre y verifica que el modelo configurado figure en el listado:

```sh
ollama list
ollama serve
```

Si el ejecutable no está en PATH, usa `.venv/bin/ollama` desde la raíz donde está configurado.

En otra Terminal, desde la raíz del repositorio y con una versión anterior del backend detenida:

```sh
.venv/bin/python -m uvicorn scaa_backend.main:app --app-dir backend --env-file backend/.env.example --host 127.0.0.1 --port 8000
```

Desde el directorio `frontend`, vuelve a ejecutar Flutter con el iPad disponible. Sustituye el identificador si `flutter devices` lista otro dispositivo:

```sh
flutter run -d A8EF03DC-81E7-4B9A-AD7E-F9E4235468FC --dart-define=API_BASE_URL=http://localhost:8000
```

| Prueba | Escenario | Estado y resultado reportado |
|---|---|---|
| I3-IPAD-01 | Abrir **Rutinas → Crear rutina**, escribir «Lavarse las manos» y generar. Revisar si la secuencia y los pictogramas representan la tarea. Probar cancelación con un candidato externo sin guardar. | Ejecutado y aprobado |
| I3-IPAD-02 | Corregir nombre y pasos, agregar, quitar y reordenar. Cambiar un pictograma y repetir el mismo en dos pasos. Comprobar que guardar se bloquea hasta aprobar todos. | Ejecutado y aprobado |
| I3-IPAD-03 | Confirmar, recuperar la rutina y comprobar el orden. Probar que un pictograma que usa la rutina no puede borrarse. Eliminar la rutina y verificar que el catálogo conserva la imagen. | Ejecutado y aprobado |
| I3-IPAD-04 | Usar **Crear manualmente** y probar la opción después de una falla de IA. Seleccionar un pictograma guardado y confirmar. | Ejecutado y aprobado |
| I3-IPAD-05 | En la elección de pictogramas, abrir el catálogo, importar una imagen sintética y confirmarla en CU02. Volver a CU03 y cancelar. La imagen debe seguir disponible en el catálogo. | Ejecutado y aprobado |
| I3-IPAD-06 | Probar vertical y horizontal, teclado y texto ampliado. Comprobar lectura de estados y acceso táctil a botones y controles de orden. | Ejecutado y aprobado |

Registrar observaciones por prueba, requisito y commit. Usar datos sintéticos y evitar compartir contenido personal en capturas.
