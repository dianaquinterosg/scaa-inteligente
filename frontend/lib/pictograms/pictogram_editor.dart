import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../design/scaa_components.dart';
import '../design/scaa_theme.dart';
import 'catalog_api.dart';
import 'catalog_controls.dart';

class PictogramEditor extends StatefulWidget {
  const PictogramEditor({
    super.key,
    required this.store,
    required this.categories,
    this.item,
    this.image,
  });

  final CatalogStore store;
  final List<Category> categories;
  final Pictogram? item;
  final Uint8List? image;

  @override
  State<PictogramEditor> createState() => _PictogramEditorState();
}

class _PictogramEditorState extends State<PictogramEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final Set<int> _categories;
  late Future<Uint8List> _image;
  bool _busy = false;
  String? _error;
  List<({int id, String name})> _dependentRoutines = [];

  bool get _editing => widget.item?.id != null;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.item?.label ?? '');
    _categories = {...?widget.item?.categoryIds};
    _image = _loadImage();
  }

  Future<Uint8List> _loadImage() async {
    final bytes = widget.image ?? await widget.store.preview(widget.item!);
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        if (descriptor.width * descriptor.height > 16000000) {
          throw const FormatException('La imagen supera 16 megapíxeles.');
        }
        final wide = descriptor.width >= descriptor.height;
        final codec = await descriptor.instantiateCodec(
          targetWidth: wide ? descriptor.width.clamp(1, 256) : null,
          targetHeight: wide ? null : descriptor.height.clamp(1, 256),
        );
        try {
          if (codec.frameCount != 1) {
            throw const FormatException('Usa una imagen estática.');
          }
          final frame = await codec.getNextFrame();
          frame.image.dispose();
        } finally {
          codec.dispose();
        }
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
    return bytes;
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _error = null;
      _dependentRoutines = [];
      _busy = true;
    });
    try {
      await widget.store.save(
        _label.text.trim(),
        _categories.toList(),
        item: widget.item,
        image: widget.image,
      );
      if (mounted) Navigator.pop(context, 'Pictograma guardado.');
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = catalogError(
            error,
            'No pudimos guardar el pictograma. Reintenta.',
          );
          _busy = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    if (!await confirmDeletion(
          context,
          title: '¿Eliminar este pictograma?',
          message: 'Se quitará del catálogo y de sus categorías.',
        ) ||
        !mounted) {
      return;
    }
    setState(() {
      _error = null;
      _dependentRoutines = [];
      _busy = true;
    });
    try {
      await widget.store.delete(widget.item!.id!);
      if (mounted) Navigator.pop(context, 'Pictograma eliminado.');
    } catch (error) {
      if (mounted) {
        setState(() {
          if (error is PictogramInUse) {
            _error = error.message;
            _dependentRoutines = error.routines;
          } else {
            _error = catalogError(
              error,
              'No pudimos eliminar el pictograma. Reintenta.',
            );
          }
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar pictograma' : 'Revisar pictograma'),
      ),
      body: SafeArea(
        top: false,
        child: ScaaWidth(
          child: FutureBuilder<Uint8List>(
            future: _image,
            builder: (context, preview) => Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(ScaaLayout.section),
                children: [
                  ScaaSection(
                    title: 'Vista previa',
                    icon: Icons.image_outlined,
                    child: Column(
                      children: [
                        if (preview.connectionState != ConnectionState.done)
                          const LinearProgressIndicator(
                            semanticsLabel: 'Cargando imagen',
                          )
                        else if (preview.hasError) ...[
                          ScaaNotice(switch (preview.error) {
                            FormatException(:final message) => message,
                            _ => 'No pudimos abrir la imagen. Usa un PNG, JPG o WebP válido.',
                          }, kind: ScaaNoticeKind.error),
                          if (widget.image == null)
                            TextButton(
                              onPressed: () =>
                                  setState(() => _image = _loadImage()),
                              child: const Text('Reintentar vista previa'),
                            ),
                        ] else if (preview.hasData)
                          Image.memory(
                            preview.data!,
                            height: 180,
                            fit: BoxFit.contain,
                            cacheWidth: 512,
                            semanticLabel: 'Vista previa del pictograma',
                          ),
                        const SizedBox(height: ScaaLayout.small),
                        Text(widget.item?.attribution ?? 'Imagen propia'),
                      ],
                    ),
                  ),
                  const SizedBox(height: ScaaLayout.gap),
                  ScaaSection(
                    title: 'Datos del pictograma',
                    icon: Icons.label_outline,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _label,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            labelText: 'Etiqueta',
                          ),
                          validator: (value) =>
                              catalogTextError(value, 100, 'una etiqueta'),
                        ),
                        const SizedBox(height: ScaaLayout.gap),
                        const Text('Categorías opcionales'),
                        if (widget.categories.isEmpty)
                          const Text('Todavía no hay categorías.'),
                        Wrap(
                          spacing: ScaaLayout.small,
                          runSpacing: ScaaLayout.small,
                          children: [
                            for (final category in widget.categories)
                              FilterChip(
                                label: Text(category.name),
                                selected: _categories.contains(category.id),
                                onSelected: _busy
                                    ? null
                                    : (selected) => setState(() {
                                        if (selected) {
                                          _categories.add(category.id);
                                        } else {
                                          _categories.remove(category.id);
                                        }
                                      }),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ScaaLayout.gap),
                  if (_error != null) ...[
                    ScaaNotice(_error!, kind: ScaaNoticeKind.error),
                    if (_dependentRoutines.isNotEmpty)
                      ScaaSection(
                        title: 'Rutinas que usan este pictograma',
                        icon: Icons.event_note_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final routine in _dependentRoutines)
                              ListTile(
                                title: Text(routine.name),
                                subtitle: Text('Rutina #${routine.id}'),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: ScaaLayout.gap),
                  ],
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: ScaaLayout.small,
                    overflowSpacing: ScaaLayout.small,
                    children: [
                      OutlinedButton(
                        onPressed: _busy ? null : () => Navigator.pop(context),
                        child: Text(_editing ? 'Cancelar' : 'Rechazar'),
                      ),
                      ScaaConfirmButton(
                        onPressed:
                            _busy ||
                                preview.connectionState !=
                                    ConnectionState.done ||
                                !preview.hasData
                            ? null
                            : _save,
                        label: _busy
                            ? 'Procesando…'
                            : _editing
                            ? 'Guardar cambios'
                            : 'Aprobar y guardar',
                      ),
                    ],
                  ),
                  if (_editing)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: _busy ? null : _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar pictograma'),
                      ),
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
