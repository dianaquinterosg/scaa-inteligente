import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../backend_client.dart';
import '../design/scaa_components.dart';
import '../design/scaa_theme.dart';
import 'catalog_api.dart';
import 'catalog_controls.dart';
import 'category_screen.dart';
import 'pictogram_editor.dart';

Future<Uint8List?> choosePictogramFile() async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Imágenes PNG, JPG y WebP',
        extensions: ['png', 'jpg', 'jpeg', 'webp'],
        uniformTypeIdentifiers: [
          'public.png',
          'public.jpeg',
          'org.webmproject.webp',
        ],
      ),
    ],
  );
  if (file == null) return null;
  if (await file.length() > maxImageBytes) {
    throw const ApiException(413, 'La imagen supera el máximo de 5 MB.');
  }
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in file.openRead()) {
    if (bytes.length + chunk.length > maxImageBytes) {
      throw const ApiException(413, 'La imagen supera el máximo de 5 MB.');
    }
    bytes.add(chunk);
  }
  return bytes.takeBytes();
}

class PictogramScreen extends StatefulWidget {
  const PictogramScreen({
    super.key,
    required this.store,
    this.chooseFile = choosePictogramFile,
  });

  final CatalogStore store;
  final Future<Uint8List?> Function() chooseFile;

  @override
  State<PictogramScreen> createState() => _PictogramScreenState();
}

class _PictogramScreenState extends State<PictogramScreen> {
  final _form = GlobalKey<FormState>();
  final _query = TextEditingController();
  final _scroll = ScrollController();
  List<Category> _categories = [];
  List<Pictogram> _local = [];
  List<Pictogram> _remote = [];
  int? _category;
  String? _searched;
  String? _remoteStatus;
  String? _error;
  String? _success;
  bool _busy = true;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh({String? query, bool alternatives = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final categories = await widget.store.categories();
      final selected = categories.any((category) => category.id == _category)
          ? _category
          : null;
      final result = query == null
          ? CatalogSearch(
              await widget.store.list(categoryId: selected),
              [],
              'not_requested',
            )
          : await widget.store.search(
              query,
              categoryId: selected,
              alternatives: alternatives,
            );
      if (mounted) {
        setState(() {
          _categories = categories;
          _category = selected;
          _local = result.local;
          _remote = result.remote;
          _remoteStatus = result.remoteStatus;
          _searched = query;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = catalogError(
            error,
            'No pudimos consultar los pictogramas. Reintenta.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _search() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _refresh(query: _query.text.trim());
  }

  Future<void> _review({Pictogram? item, Uint8List? image}) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PictogramEditor(
          store: widget.store,
          categories: _categories,
          item: item,
          image: image,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _category = null;
      _query.clear();
      _success = result;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await _refresh();
  }

  Future<void> _import() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final bytes = await widget.chooseFile();
      if (bytes != null && mounted) await _review(image: bytes);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = catalogError(
            error,
            'No pudimos abrir el archivo. Selecciona otra imagen.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _manageCategories() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CategoryScreen(store: widget.store, categories: _categories),
      ),
    );
    if (mounted) await _refresh(query: _searched);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !_busy && !_picking;
    final searched = _searched;
    return Scaffold(
      appBar: AppBar(title: const Text('SCAA · Pictogramas')),
      body: SafeArea(
        top: false,
        child: ScaaWidth(
          maxWidth: ScaaLayout.contentWidth,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(ScaaLayout.section),
            children: [
              ScaaSection(
                title: 'Buscar o importar pictograma',
                icon: Icons.search,
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _query,
                        enabled: enabled,
                        textInputAction: TextInputAction.search,
                        onFieldSubmitted: (_) => _search(),
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Por ejemplo, lavarse los dientes',
                        ),
                        validator: (value) =>
                            catalogTextError(value, 100, 'una descripción'),
                      ),
                      const SizedBox(height: ScaaLayout.gap),
                      Wrap(
                        spacing: ScaaLayout.small,
                        runSpacing: ScaaLayout.small,
                        children: [
                          FilledButton.icon(
                            onPressed: enabled ? _search : null,
                            icon: const Icon(Icons.search),
                            label: const Text('Buscar'),
                          ),
                          OutlinedButton.icon(
                            onPressed: enabled ? _import : null,
                            icon: const Icon(Icons.file_upload_outlined),
                            label: const Text('Importar imagen'),
                          ),
                          OutlinedButton.icon(
                            onPressed: enabled ? _manageCategories : null,
                            icon: const Icon(Icons.folder_outlined),
                            label: const Text('Administrar categorías'),
                          ),
                          if (searched != null)
                            TextButton(
                              onPressed: enabled
                                  ? () {
                                      _query.clear();
                                      _refresh();
                                    }
                                  : null,
                              child: const Text('Ver mis pictogramas'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ScaaLayout.gap),
              if (_success != null) ...[
                ScaaNotice(_success!, kind: ScaaNoticeKind.success),
                const SizedBox(height: ScaaLayout.gap),
              ],
              if (_error != null) ...[
                ScaaNotice(_error!, kind: ScaaNoticeKind.error),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: enabled ? () => _refresh(query: searched) : null,
                    child: const Text('Reintentar'),
                  ),
                ),
              ],
              ScaaSection(
                title: 'Mis pictogramas',
                icon: Icons.collections_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Filtrar por categoría'),
                    Wrap(
                      spacing: ScaaLayout.small,
                      runSpacing: ScaaLayout.small,
                      children: [
                        ChoiceChip(
                          label: const Text('Todas'),
                          selected: _category == null,
                          onSelected: enabled
                              ? (_) {
                                  _category = null;
                                  _refresh(query: searched);
                                }
                              : null,
                        ),
                        for (final category in _categories)
                          ChoiceChip(
                            label: Text(category.name),
                            selected: _category == category.id,
                            onSelected: enabled
                                ? (_) {
                                    _category = category.id;
                                    _refresh(query: searched);
                                  }
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: ScaaLayout.gap),
                    if (_busy)
                      const LinearProgressIndicator(
                        semanticsLabel: 'Consultando pictogramas',
                      )
                    else if (_local.isEmpty)
                      Text(
                        searched == null
                            ? 'Aún no hay pictogramas con este filtro.'
                            : 'Sin coincidencias guardadas.',
                      ),
                    _PictogramGrid(
                      items: _local,
                      store: widget.store,
                      action: 'Abrir',
                      onSelect: enabled ? (item) => _review(item: item) : null,
                    ),
                  ],
                ),
              ),
              if (_remoteStatus == 'unavailable' && searched != null) ...[
                const SizedBox(height: ScaaLayout.gap),
                const ScaaNotice(
                  'ARASAAC no está disponible. Puedes reintentar o importar una imagen propia.',
                  kind: ScaaNoticeKind.error,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: enabled
                        ? () => _refresh(query: searched, alternatives: true)
                        : null,
                    child: const Text('Reintentar ARASAAC'),
                  ),
                ),
              ] else if (searched != null &&
                  _category == null &&
                  _remoteStatus == 'not_requested') ...[
                const SizedBox(height: ScaaLayout.gap),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: enabled
                        ? () => _refresh(query: searched, alternatives: true)
                        : null,
                    icon: const Icon(Icons.travel_explore),
                    label: const Text('Buscar alternativas en ARASAAC'),
                  ),
                ),
              ] else if (_remoteStatus == 'available') ...[
                const SizedBox(height: ScaaLayout.gap),
                ScaaSection(
                  title: 'Alternativas de ARASAAC',
                  icon: Icons.travel_explore,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_remote.isEmpty)
                        const ScaaNotice(
                          'Sin alternativas para esta búsqueda. Puedes importar una imagen propia.',
                        )
                      else
                        const Text(
                          'Sergio Palao · Gobierno de Aragón · ARASAAC · CC BY-NC-SA',
                        ),
                      const SizedBox(height: ScaaLayout.small),
                      _PictogramGrid(
                        items: _remote,
                        store: widget.store,
                        action: 'Revisar',
                        onSelect: enabled
                            ? (item) => _review(item: item)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PictogramGrid extends StatelessWidget {
  const _PictogramGrid({
    required this.items,
    required this.store,
    required this.action,
    required this.onSelect,
  });

  final List<Pictogram> items;
  final CatalogStore store;
  final String action;
  final ValueChanged<Pictogram>? onSelect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / 215).floor().clamp(1, 4);
      final width =
          (constraints.maxWidth - (columns - 1) * ScaaLayout.small) / columns;
      return Wrap(
        spacing: ScaaLayout.small,
        runSpacing: ScaaLayout.small,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(ScaaLayout.small),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 100,
                        child: Image.network(
                          store.imageUrl(item).toString(),
                          fit: BoxFit.contain,
                          cacheWidth: 320,
                          excludeFromSemantics: true,
                          errorBuilder: (context, error, stack) =>
                              const Center(child: Text('Imagen no disponible')),
                        ),
                      ),
                      const SizedBox(height: ScaaLayout.small),
                      Text(item.label, textAlign: TextAlign.center),
                      const SizedBox(height: ScaaLayout.small),
                      OutlinedButton(
                        onPressed: onSelect == null
                            ? null
                            : () => onSelect!(item),
                        child: Semantics(
                          label: '$action ${item.label}',
                          excludeSemantics: true,
                          child: Text(action),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
