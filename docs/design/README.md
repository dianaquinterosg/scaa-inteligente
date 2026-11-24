# Referencia visual SCAA

[Mockups originales](mockups-originales.png) conserva la lámina del anteproyecto con los flujos de pictogramas, rutinas y recomendaciones. Se usa como referencia de composición, jerarquía y estilo. El [SRS v0.2](../SRS.md) define el comportamiento y el alcance.

| Rasgo de la lámina | Aplicación en Flutter |
|---|---|
| Cabecera azul con texto blanco y fondo de trabajo celeste | Barra de aplicación azul y fondo claro en Material 3 |
| Resultados y pasos en tarjetas blancas | Superficies con bordes suaves para los bloques del perfil |
| Azul para acciones principales, verde para aprobación, rojo para rechazo | Azul para editar y añadir, verde para guardar y confirmar, rojo para eliminar y señalar errores |
| Paneles celestes y verdes con icono y texto | Ayuda y estados explícitos de confirmación, carga y error |
| Navegación inferior por icono y texto | Patrón para los módulos disponibles. CU01 usa Inicio como entrada al perfil y retorno al resumen confirmado |

CU01 no tiene un mockup propio en la lámina. Se deriva un formulario con alias obligatorio y tarjetas para intereses, actividades y rutinas frecuentes. En tablet el contenido se centra y limita su ancho. El resumen distribuye las tarjetas en dos columnas cuando hay espacio y el editor conserva una secuencia vertical con desplazamiento y acciones visibles.

Las acciones tienen etiquetas en español. El control compacto de eliminar tiene nombre accesible y área táctil mínima de 48 puntos lógicos. El significado de cada estado se comunica por texto e icono además del color. Los mensajes de resultado se anuncian a tecnologías de asistencia y las secciones permiten que el texto se ajuste.

Los flujos de pictogramas y rutinas guiarán CU02 y CU03 según el SRS. Los controles de voz, generación de imágenes y recomendaciones representados en la lámina quedan sujetos al alcance y prioridades del MVP. La confirmación visual en iPad permanece pendiente.

Los cambios se versionan por responsabilidad con Conventional Commits. Las pruebas unitarias y de widgets acompañan a la unidad que validan. Las pruebas de sistema, la evidencia y los incrementos visuales se registran por separado cuando constituyen unidades independientes.

El sistema de diseño está en `frontend/lib/design/`. `ScaaTheme` y `ScaaLayout` centralizan la paleta, tipografía, tamaños y espaciado. `ScaaWidth`, `ScaaSection`, `ScaaNotice` y `ScaaConfirmButton` aplican los patrones compartidos. La [evidencia de CU01](../evidence/iteration-1/visual.md) identifica los commits y las comprobaciones realizadas.
