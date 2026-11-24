# Iteración 0 — alcance efectivamente implementado

**Estado:** cierre técnico confirmado por la persona usuaria.
**Commit asociado:** el commit de cierre identificado en [README](README.md).

Se prepararon FastAPI, conexiones SQLite, configuración dev/test/demo y el cliente Flutter iOS de salud. Se verificaron las 6 pruebas backend, 2 pruebas Flutter y las conexiones reales de ARASAAC, Ollama e iPad. El código de referencia es el incluido en el commit de cierre; al consultar otra iteración se debe usar ese commit para reproducir estas pruebas.

## Componentes

| Componente | Código | Límite del incremento |
|---|---|---|
| Configuración | `backend/scaa_backend/settings.py:Settings` | Entornos aislados |
| Conexiones | `backend/scaa_backend/database.py:Database` | Sin tablas de dominio en este cierre |
| API de salud | `backend/scaa_backend/main.py:create_app` | No implementa los casos de uso |
| Sondas externas | `backend/scripts/probe_integrations.py` | Sin incorporación de pictogramas o rutinas |
| Cliente HTTP | `frontend/lib/backend_client.dart:BackendClient` | Endpoint de salud |
| Pantalla inicial | `frontend/lib/main.dart` | Carga, error y reintento |

## Planificado frente a implementado

Todo el alcance técnico de este cierre se comprobó. CU01–CU03 permanecen fuera de esta implementación. El cierre no renumera los criterios del SRS ni cambia P0/P1/P2.

## Limitaciones para los siguientes incrementos

Modelo Ollama provisional y calidad pendiente; identificador iOS `com.example.scaaInteligente` provisional; iPad físico sin verificar; contratos funcionales por concretar. Antes de las primeras migraciones debe registrarse la elección de SQL/ORM y su mecanismo de versionado. El SRS describe endpoints como definitivos y arquitectura como preliminares: se conserva esa discrepancia editorial y se concretarán los contratos al implementar.

[Pruebas y evidencias](test-results.md). La preparación se cierra por alcance y resultados, sin una reconstrucción de la elaboración local del proyecto.
