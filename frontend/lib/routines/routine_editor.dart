import 'package:flutter/material.dart';

import '../design/scaa_components.dart';
import '../design/scaa_theme.dart';
import '../pictograms/catalog_api.dart';
import '../pictograms/catalog_controls.dart';
import 'routine_api.dart';
import 'routine_pictograms.dart';

class RoutineEditor extends StatefulWidget {
  const RoutineEditor({
    super.key,
    required this.store,
    required this.catalog,
    required this.initial,
    required this.generated,
  });
  final RoutineStore store;
  final CatalogStore catalog;
  final RoutineData initial;
  final bool generated;

  @override
  State<RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends State<RoutineEditor> {
  late final _name = TextEditingController(text: widget.initial.name);
  late final _description = TextEditingController(
    text: widget.initial.description,
  );
  late final _steps = widget.initial.steps.map((step) => step.copy()).toList();
  final _scroll = ScrollController();
  bool _working = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _error = message;
      _working = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _choose(RoutineStep step) async {
    final picture = await Navigator.push<Pictogram>(
      context,
      MaterialPageRoute(
        builder: (_) => RoutinePictograms(
          catalog: widget.catalog,
          initialTerm: step.searchTerm.isEmpty
              ? step.label.trim()
              : step.searchTerm,
          candidates: step.candidates,
        ),
      ),
    );
    if (!mounted || picture == null) return;
    setState(() {
      step.pictogram = picture;
      step.approved = true;
    });
  }

  Future<void> _save() async {
    final nameError = catalogTextError(_name.text, 100, 'un nombre');
    if (nameError != null) {
      _showError(nameError);
      return;
    }
    if (_description.text.trim().runes.length > 500) {
      _showError('La descripción admite hasta 500 caracteres.');
      return;
    }
    if (_steps.isEmpty) {
      _showError('Agrega al menos un paso.');
      return;
    }
    for (var i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      if (catalogTextError(step.label, 100, 'una etiqueta') != null) {
        _showError(
          'Ingresa una etiqueta de 1 a 100 caracteres para el paso ${i + 1}.',
        );
        return;
      }
      if (!step.approved || step.pictogram == null) {
        _showError('Selecciona y aprueba un pictograma para el paso ${i + 1}.');
        return;
      }
    }
    FocusScope.of(context).unfocus();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar rutina'),
        content: Text(
          'Se guardará «${_name.text.trim()}» con ${_steps.length} pasos. '
          'Los candidatos externos aprobados se incorporarán junto con la rutina.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir editando'),
          ),
          ScaaConfirmButton(
            onPressed: () => Navigator.pop(context, true),
            label: 'Confirmar guardado',
          ),
        ],
      ),
    );
    if (!mounted || accepted != true) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await widget.store.save(
        RoutineData(
          id: widget.initial.id,
          name: _name.text,
          description: _description.text,
          steps: _steps,
        ),
      );
      if (mounted) Navigator.pop(context, 'Rutina guardada.');
    } catch (error) {
      if (mounted) {
        _showError(
          catalogError(
            error,
            'No pudimos guardar la rutina. El borrador sigue disponible.',
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    if (!await confirmDeletion(
          context,
          title: '¿Eliminar esta rutina?',
          message: 'La rutina y sus pasos se eliminarán. Los pictogramas se conservarán.',
        ) ||
        !mounted) {
      return;
    }
    setState(() => _working = true);
    try {
      await widget.store.delete(widget.initial.id!);
      if (mounted) Navigator.pop(context, 'Rutina eliminada.');
    } catch (error) {
      if (mounted) {
        _showError(
          catalogError(error, 'No pudimos eliminar la rutina. Reintenta.'),
        );
      }
    }
  }

  void _move(int from, int to) =>
      setState(() => _steps.insert(to, _steps.removeAt(from)));

  Widget _step(int index, RoutineStep step) {
    final picture = step.pictogram;
    final status = step.approved
        ? 'Pictograma aprobado para este paso'
        : picture != null
        ? 'Candidato pendiente de revisión'
        : switch (step.association) {
            'ambiguous' => 'Hay varias coincidencias locales. Elige una.',
            'unavailable' => 'ARASAAC no respondió. Elige un pictograma.',
            _ => 'Sin pictograma seleccionado',
          };
    return Padding(
      key: ObjectKey(step),
      padding: const EdgeInsets.only(bottom: ScaaLayout.gap),
      child: ScaaSection(
        title: 'Paso ${index + 1}',
        icon: Icons.format_list_numbered,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: ValueKey('routine-step-label-$index'),
              initialValue: step.label,
              enabled: !_working,
              decoration: const InputDecoration(labelText: 'Etiqueta del paso'),
              onChanged: (value) {
                step.label = value;
                if (step.approved) setState(() => step.approved = false);
              },
            ),
            const SizedBox(height: ScaaLayout.small),
            ScaaNotice(
              status,
              kind: step.approved
                  ? ScaaNoticeKind.success
                  : ScaaNoticeKind.info,
            ),
            if (picture != null) ...[
              const SizedBox(height: ScaaLayout.small),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: RoutinePicture(picture, catalog: widget.catalog),
                  ),
                  const SizedBox(width: ScaaLayout.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(picture.label),
                        if (picture.attribution != null)
                          Text(picture.attribution!),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            Wrap(
              spacing: ScaaLayout.small,
              runSpacing: ScaaLayout.small,
              children: [
                if (picture != null && !step.approved)
                  ScaaConfirmButton(
                    key: ValueKey('routine-approve-picture-$index'),
                    label: 'Aprobar pictograma',
                    onPressed: _working
                        ? null
                        : () => setState(() => step.approved = true),
                  ),
                OutlinedButton.icon(
                  key: ValueKey('routine-picture-$index'),
                  onPressed: _working ? null : () => _choose(step),
                  icon: const Icon(Icons.image_search_outlined),
                  label: Text(
                    picture == null
                        ? 'Elegir pictograma'
                        : 'Cambiar pictograma',
                  ),
                ),
              ],
            ),
            Wrap(
              children: [
                IconButton(
                  tooltip: 'Subir paso ${index + 1}',
                  onPressed: _working || index == 0
                      ? null
                      : () => _move(index, index - 1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Bajar paso ${index + 1}',
                  onPressed: _working || index == _steps.length - 1
                      ? null
                      : () => _move(index, index + 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Eliminar paso ${index + 1}',
                  color: Theme.of(context).colorScheme.error,
                  onPressed: _working
                      ? null
                      : () => setState(() => _steps.removeAt(index)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial.id != null;
    return PopScope(
      canPop: !_working,
      child: Scaffold(
        appBar: AppBar(title: Text(editing ? 'Editar rutina' : 'Crear rutina')),
        body: SafeArea(
          top: false,
          bottom: false,
          child: ScaaWidth(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(ScaaLayout.section),
              children: [
                if (_error == null)
                  const SizedBox.shrink()
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: ScaaLayout.gap),
                    child: ScaaNotice(_error!, kind: ScaaNoticeKind.error),
                  ),
                if (_working) ...[
                  const LinearProgressIndicator(
                    semanticsLabel: 'Procesando rutina',
                  ),
                  const SizedBox(height: ScaaLayout.gap),
                ],
                if (widget.generated) ...[
                  const ScaaNotice(
                    'Propuesta de rutina. Revisa los pasos y aprueba cada pictograma antes de guardar.',
                  ),
                  const SizedBox(height: ScaaLayout.gap),
                ],
                ScaaSection(
                  title: 'Datos de la rutina',
                  icon: Icons.event_note_outlined,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        enabled: !_working,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                      const SizedBox(height: ScaaLayout.gap),
                      TextFormField(
                        controller: _description,
                        enabled: !_working,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ScaaLayout.gap),
                for (var index = 0; index < _steps.length; index++)
                  _step(index, _steps[index]),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _working || _steps.length == maxRoutineSteps
                        ? null
                        : () => setState(() => _steps.add(RoutineStep())),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar paso'),
                  ),
                ),
                if (_steps.length == maxRoutineSteps)
                  const Text('Máximo de 12 pasos.'),
                if (editing)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: _working ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar rutina'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 2,
          child: SafeArea(
            child: ScaaWidth(
              shrinkHeight: true,
              child: Padding(
                padding: const EdgeInsets.all(ScaaLayout.gap),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  spacing: ScaaLayout.small,
                  overflowSpacing: ScaaLayout.small,
                  children: [
                    OutlinedButton(
                      onPressed: _working ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ScaaConfirmButton(
                      onPressed: _working ? null : _save,
                      label: 'Guardar rutina',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
