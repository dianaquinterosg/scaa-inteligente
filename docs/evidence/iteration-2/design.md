# AINC421 · Diseño de CU02

**Iteración 2.** [SRS v0.2](../../SRS.md), [criterios CU02](../../use-cases.md), [modelo conceptual](../../data-model.md), [secuencia](../../diagrams/cu02-sequence.puml) y [mockups originales](../../design/mockups-originales.png).

| Requisitos | Diseño y componentes |
|---|---|
| RF02.1–RF02.2 | `PictogramScreen` consulta `GET /api/v1/pictograms/search?q=...`. `Catalog` busca subcadenas en etiquetas locales con casefold. `ArasaacClient` consulta español cuando no hay coincidencias o se solicitan alternativas. |
| RF02.4–RF02.5 | El selector nativo del paquete oficial Flutter `file_selector` abre archivos PNG, JPG y WebP. `PictogramEditor` decodifica la vista previa y permite editar etiqueta y categorías, rechazar o aprobar. |
| RF02.6 | La API exige el booleano explícito `confirmed: true` para crear. Guarda la referencia y atribución de ARASAAC o el origen propio. Sirve la imagen local a través de una ruta del catálogo. |
| RF02.7–RF02.9 | `CategoryScreen` crea, renombra y elimina con confirmación. Las asociaciones N:M son opcionales. Se filtran pictogramas guardados desde `PictogramScreen`. |
| RF02.3 | Generación de imágenes reservada a la planificación posterior del SRS. |

## Contrato y consistencia

Las rutas usan el prefijo `/api/v1`. `GET /pictograms` lista recursos confirmados y acepta `category_id`. `GET /pictograms/search` devuelve `local`, `alternatives` y `remote_status`. Un filtro por categoría aplica al catálogo guardado. `alternatives=true` permite buscar opciones externas tras una coincidencia local. La caída de ARASAAC conserva resultados locales y habilita reintento e importación propia.

`GET /pictograms/arasaac/{id}/image` muestra una vista previa sin incorporación. `POST /pictograms` guarda una referencia ARASAAC o un archivo propio en Base64, junto con `label`, `category_ids` y la confirmación. El cliente envía el identificador numérico en la modalidad remota. El backend construye la URL a partir del dominio de ARASAAC. `PUT /pictograms/{id}` modifica etiqueta y categorías del recurso existente. `GET /pictograms/{id}/image` lee su imagen local. `DELETE /pictograms/{id}` elimina el recurso si se puede retirar su archivo y SQLite admite el borrado. `GET/POST /categories` y `PUT/DELETE /categories/{id}` gestionan categorías.

La migración `002_pictograms.sql` preserva perfil y contexto. La clave única de fuente y referencia evita duplicados ARASAAC. La eliminación de categoría solo quita sus asociaciones. Los nombres se normalizan con trim y casefold para unicidad. Una categoría inexistente aborta el guardado o edición. Validaciones adoptadas para el piloto: descripción y etiqueta de 1 a 100 caracteres, nombre de categoría de 1 a 50, archivos estáticos decodificables con Pillow de hasta 5 × 1024² bytes y 16 megapíxeles.

Cada imagen se guarda bajo un nombre generado dentro de `pictograms/` junto a la base del entorno. Una escritura fallida revierte metadatos y asociaciones. El borrado retira temporalmente el archivo durante la transacción y lo restaura si falla. Al reiniciar se reconcilian archivos gestionados tras una interrupción. La futura FK de pasos de rutina debe usar `ON DELETE RESTRICT`. CU02 convierte el conflicto en una respuesta 409 comprensible, verificada con una dependencia SQLite de prueba.

## Adaptación del mockup

La pantalla mantiene la cabecera azul, las tarjetas blancas, la búsqueda textual y la presentación diferenciada de recursos guardados y alternativas ARASAAC. La rejilla cambia el número de columnas con el ancho disponible. La aprobación es verde y la eliminación requiere diálogo con etiqueta explícita. Se usan `ScaaWidth`, `ScaaSection`, `ScaaNotice` y `ScaaConfirmButton`. El acceso desde Inicio abre Pictogramas. La revisión y las categorías tienen pantallas propias para ordenar el flujo en tablet.

El bloque del mockup que propone generación de imágenes se adapta a una acción real de importación. Los controles de voz, generación, recomendaciones y rutinas corresponden a sus alcances posteriores. La atribución incluye autor, propietario, origen y licencia conforme a los [términos de ARASAAC](https://arasaac.org/terms-of-use). El módulo usa el selector oficial de archivos [file_selector](https://pub.dev/packages/file_selector).
