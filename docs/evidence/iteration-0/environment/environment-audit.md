# Iteración 0 — entorno verificado

**Commit asociado:** commit de cierre definido en [README](../README.md).

| Herramienta | Versión verificada | Resultado |
|---|---|---|
| Mac | Apple M1, 16 GB, ARM64 | Inventario de hardware comprobado |
| macOS | 27.2.1, build 26B131 | Verificado |
| Git | 2.39.5, Apple Git-154 | Funcional |
| Python de .venv | 3.13.7 ARM64, Homebrew | Pruebas de entorno y backend aprobadas |
| Otros Python | Anaconda 3.13.5; Apple 3.9.6 | No utilizados para el backend |
| pip | 25.2 | Comprobación de dependencias satisfactoria |
| SQLite de Python | 3.50.4 | Integridad y rollback comprobados |
| OpenSSL de Python | 3.5.2 | HTTPS a PyPI respondió 200 |
| Flutter / Dart | 3.47.1 stable / 3.13.1 | Análisis, pruebas y detección de iPad correctos |
| DevTools | 2.60.0 | Versión informada por Flutter |
| Xcode | 27.2, build 27B52 | Seleccionado; primer inicio y SDK comprobados |
| Simulador | iOS 27.2 ARM64, iPad (A16) | Arranque y detección Flutter confirmados |
| CocoaPods / Ruby | 1.17.0 / 4.0.10 | Instalados con autorización; TLS al CDN respondió 200 |
| Homebrew | 6.0.21 | Instalaciones registradas |
| Ollama | 0.40.17 | API y generación local comprobadas |
| Modelo provisional | qwen2.5:1.5b, Q4_K_M | Descarga y tres respuestas estructuradas comprobadas |

Las versiones de paquetes Python verificadas están en `backend/requirements-lock.txt` y en el inventario de esta carpeta. El modelo no se ha seleccionado como definitivo y sus propuestas no se aprobaron como contenido de SCAA.

## Comandos reproducibles y resultados

`git --version`, `python --version`, `pip check`, `flutter --version --machine`, `dart --version`, `flutter doctor -v`, `xcodebuild -version`, `xcode-select -p`, `xcodebuild -checkFirstLaunchStatus`, `simctl list runtimes`, `simctl list devices available`, `simctl bootstatus`, `pod --version` y las sondas locales tienen resultados conservados en los archivos de esta carpeta y las carpetas de [backend](../backend/) y [Flutter](../flutter/).

La [guía de desarrollo](../../../development-setup.md) detalla los comandos de arranque. Python usa un entorno local; no se modificó Anaconda. Ollama se instaló desde la distribución oficial y se comprobó su firma. Las instalaciones globales y las descargas importantes se realizaron con autorización. No se instalaron IDEs adicionales.

## Restricciones y resolución

El entorno restringido bloquea sysctl, CoreSimulatorService, algunas cachés y el acceso a /dev/tty de Homebrew. Las verificaciones correspondientes se repitieron desde Terminal normal por la persona usuaria, con resultados explícitos. Flutter reconoció ARM64; Xcode/CocoaPods quedaron aprobados; el iPad arrancó y mostró la pantalla conectada. Los registros distinguen la procedencia del resultado y conservan los errores iniciales normalizados.

Los modelos, bases de datos, entornos virtuales y salidas brutas no se incorporan a Git. Los registros versionados omiten metadatos temporales; se conservan los códigos de salida, resultados y datos técnicos de las verificaciones. El único aviso pendiente de Flutter doctor corresponde al SDK Android, ajeno al destino iPad solicitado.

## Limitaciones

Calidad de las propuestas IA pendiente; iPad físico sin verificar; no se probaron todavía los casos de uso. La comprobación de salud no equivale al recorrido T16 ni a una evaluación con usuarios.
