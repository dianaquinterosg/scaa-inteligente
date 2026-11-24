import 'package:flutter/material.dart';

import '../design/scaa_components.dart';
import '../design/scaa_theme.dart';
import '../pictograms/catalog_api.dart';
import '../pictograms/pictogram_image.dart';
import 'routine_api.dart';

class RoutineViewer extends StatefulWidget {
  const RoutineViewer({
    super.key,
    required this.routine,
    required this.catalog,
  });

  final RoutineData routine;
  final CatalogStore catalog;

  @override
  State<RoutineViewer> createState() => _RoutineViewerState();
}

class _RoutineViewerState extends State<RoutineViewer> {
  final _sequence = ScrollController();

  @override
  void dispose() {
    _sequence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.routine.name)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final stepWidth = (constraints.maxWidth - ScaaLayout.section * 2)
                .clamp(
                  0.0,
                  landscape
                      ? ScaaLayout.routineStepWide
                      : ScaaLayout.routineStepNarrow,
                );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(ScaaLayout.section),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScaaModeBanner(administration: false),
                  if (widget.routine.description.isNotEmpty) ...[
                    const SizedBox(height: ScaaLayout.gap),
                    Text(
                      widget.routine.description,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                  const SizedBox(height: ScaaLayout.gap),
                  if (stepWidth * widget.routine.steps.length +
                          ScaaLayout.gap * (widget.routine.steps.length - 1) >
                      constraints.maxWidth - ScaaLayout.section * 2) ...[
                    const Text(
                      'Desliza hacia los lados para ver todos los pasos.',
                    ),
                    const SizedBox(height: ScaaLayout.small),
                  ],
                  Scrollbar(
                    controller: _sequence,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      key: const ValueKey('routine-sequence'),
                      controller: _sequence,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: ScaaLayout.gap),
                      child: Row(
                        textDirection: TextDirection.ltr,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (index, step)
                              in widget.routine.steps.indexed) ...[
                            if (index != 0)
                              const SizedBox(width: ScaaLayout.gap),
                            SizedBox(
                              width: stepWidth,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(ScaaLayout.gap),
                                  child: Column(
                                    children: [
                                      Semantics(
                                        header: true,
                                        child: Text(
                                          'Paso ${index + 1}',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                      const SizedBox(height: ScaaLayout.small),
                                      SizedBox(
                                        height: ScaaLayout.routinePicture,
                                        child: step.pictogram == null
                                            ? const Center(
                                                child: Text(
                                                  'Imagen no disponible',
                                                ),
                                              )
                                            : PictogramImage(
                                                url: widget.catalog.imageUrl(
                                                  step.pictogram!,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: ScaaLayout.small),
                                      Text(
                                        step.label,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
