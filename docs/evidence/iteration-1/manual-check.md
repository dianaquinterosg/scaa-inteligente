# Iteración 1 — aceptación manual pendiente de CU01

**Estado:** pendiente. **Commit base:** `db312e3592648a3b620d66b2ea22af018396112e`; implementación funcional `854180f` y visual `bca2e58`.

La Iteración 0 tiene confirmación visual de conectividad. Esta lista corresponde al nuevo CU01 y no se marca realizada sin su resultado real.

## Ejecutar el código actual

En la Terminal del backend, detener la instancia anterior con Ctrl+C y ejecutar desde la raíz:

```sh
.venv/bin/python -m uvicorn scaa_backend.main:app --app-dir backend --env-file backend/.env.example --host 127.0.0.1 --port 8000
```

La migración de CU01 se aplica al iniciar, sin eliminar el archivo anterior. No borrar bases ni reinicializar el repositorio.

En la Terminal donde continúa `flutter run`, pulsar `R` para hot restart. Si el cliente ya está cerrado:

```sh
cd frontend
flutter run -d A8EF03DC-81E7-4B9A-AD7E-F9E4235468FC --dart-define=API_BASE_URL=http://localhost:8000
```

Abrir DeviceHub si la ventana no está visible. Un perfil todavía no creado muestra «Configurar perfil»; uno guardado muestra Inicio.

## Escenarios a registrar

Probar en vertical y horizontal, con teclado abierto y texto ampliado desde los ajustes de accesibilidad. Revisar la lectura de las tarjetas, el ancho del formulario, el desplazamiento y la ubicación de Guardar y Cancelar. Con VoiceOver, comprobar el orden de lectura, los nombres de los controles para eliminar ítems y el anuncio de los avisos. Registrar el resultado por escenario y commit.

| Caso | Resultado esperado | Resultado manual |
|---|---|---|
| Alias vacío | Guardar bloqueado y mensaje visible | Pendiente |
| Alias válido sin contexto | Guardar y navegar a Inicio | Pendiente |
| Elementos de los tres tipos | Añadir, editar y eliminar individualmente | Pendiente |
| Duplicado por tipo o valor inválido | Rechazo sin sustituir datos confirmados | Pendiente |
| Cancelar edición posterior | Regresar al perfil confirmado anterior | Pendiente |
| Reiniciar cliente/backend | Recuperar el perfil y contexto guardados | Pendiente |
| Backend no disponible | Informar y conservar borrador si estaba en edición | Pendiente |

Usar datos sintéticos para las capturas académicas. Asociar las evidencias a CU01, CA y commit real. No registrar datos personales innecesarios ni metadatos temporales.
