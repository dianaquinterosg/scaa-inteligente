# Iteración 1 — diseño de CU01 para AINC421

**Identificación documental:** v0.2. **Estado:** diseño implementado en `8486582`, `89647a9` y `f81d180`.

## Requisito → iteración → componente

| Requisito | Iteración | Componente real | Responsabilidad |
|---|---|---|---|
| RF01.1 | 1 | `ProfileGate`, `ProfileEditor`, `ProfileApi`; GET/PUT `/api/v1/profile` | Primer uso, alias, contexto opcional, consulta y edición |
| RF01.2 | 1 | `ProfileRepository.load`, estado confirmado de `ProfileGate` | Exponer contexto persistido; el consumo en IA es posterior |
| RF01.3 | 1 | `ProfilePayload`, validadores del editor, transacción SQLite | Tipos, trim, longitud, duplicados y guardado íntegro |

## Contrato de perfil

GET `/api/v1/profile` devuelve 404 con «Perfil no configurado» si todavía no existe. Una indisponibilidad de almacenamiento devuelve 503 y no se trata como primer uso. PUT reemplaza íntegramente el perfil único y su contexto; devuelve 200 con el contenido confirmado. Datos inválidos devuelven 422 sin cambios. No existe autenticación multiusuario ni endpoint para crear un segundo perfil.

```json
{
  "alias": "Ana",
  "interests": ["Música"],
  "activities": ["Caminar"],
  "frequent_routines": ["Lectura"]
}
```

La respuesta añade `id: 1`. Las listas pueden estar vacías. Cada elemento es texto individual, de 1 a 50 caracteres tras trim. Se rechazan duplicados por tipo sin distinguir mayúsculas; el mismo texto en tipos distintos es válido. La API usa casefold para cubrir variantes Unicode y sigue siendo la autoridad sobre la validación.

## Persistencia e integridad

La migración `001_profile_context.sql` crea `profile` y `context_item`. El perfil tiene id fijo 1. Los tipos almacenados son INTEREST, ACTIVITY y ROUTINE; la clave normalizada es única por perfil y tipo. Las claves foráneas están activadas en cada conexión. Se conserva el modelo conceptual; el contexto ROUTINE no equivale a una rutina visual CU03.

La actualización del alias, la eliminación del contexto previo y las nuevas asociaciones forman una sola transacción. Una inserción fallida revierte todo. Las migraciones también son transaccionales y no se admite una versión de esquema posterior a la soportada. ADR-018 y ADR-019 registran estas elecciones.

## Controles del cliente

El editor mantiene un borrador independiente. Primer uso no permite continuar sin alias. Guardar valida todos los controladores, incluidos campos fuera del área visible. Los errores se muestran sin perder los datos en edición; cancelar una edición posterior descarta el borrador y conserva el perfil confirmado. La navegación a Inicio y la confirmación ocurren después de la respuesta satisfactoria, sin diálogo redundante.

## UML y modelo

[Secuencia CU01](../../diagrams/cu01-sequence.puml), [modelo de datos](../../data-model.md), [arquitectura](../../architecture.md), [matriz de criterios](cu01/acceptance.json).

El UML se comprobó estructuralmente; no se ejecutó un renderizador PlantUML. La conformidad funcional está respaldada por pruebas automáticas y por los contratos efectivamente implementados; la revisión visual en iPad de CU01 sigue pendiente.

La [referencia visual del anteproyecto](../../design/README.md) y la [adaptación de CU01](visual.md) complementan este diseño funcional para AINC421.
