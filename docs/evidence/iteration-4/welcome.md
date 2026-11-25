# Iteración 4 · Pantalla de bienvenida

La composición adopta la jerarquía de la propuesta visual aprobada. El saludo centrado utiliza el alias confirmado y el subtítulo dice «Tu espacio de comunicación». Cuando se carece de perfil se muestra «¡Hola!» y el acceso deliberado a administración permite configurarlo.

Las tarjetas Material 3 de Pictogramas y Rutinas conservan las rutas actuales. Tienen iconos grandes, esquinas redondeadas y una sombra suave basada en el tema. En iPad se muestran a la par cuando el ancho lo permite. En ventanas estrechas se apilan y el acceso de administración conserva una etiqueta accesible. El indicador de modo está debajo de las tarjetas y se mantienen la confirmación y el retorno a visualización.

## Pruebas

- Flutter aprobó 36 pruebas y `flutter analyze --no-pub` quedó sin incidencias.
- Los widgets verificaron alias confirmado, bienvenida sin perfil, áreas táctiles amplias, acceso a ambas rutas y ausencia de desbordamientos a escala de texto 2.
- Se usaron tamaños de 1180 × 820, 820 × 1180 y 420 × 980 píxeles lógicos. Se verificaron tarjetas en una fila en los dos tamaños de iPad y apiladas en el tamaño compacto.
- Las 16 comprobaciones de [Device Hub](manual-check.md) corresponden al incremento anterior de modos y visor. La aprobación visual de esta bienvenida queda pendiente.

Para validar en Device Hub, inicia la aplicación con un perfil sintético. Comprueba saludo, subtítulo y tarjetas en ambas orientaciones. Abre ambas tarjetas y vuelve al inicio. Comprueba que el acceso a administración sigue pidiendo confirmación.
