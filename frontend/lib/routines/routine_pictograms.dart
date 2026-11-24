import 'package:flutter/material.dart';

import '../design/scaa_components.dart';
import '../design/scaa_theme.dart';
import '../pictograms/catalog_api.dart';
import '../pictograms/catalog_controls.dart';
import '../pictograms/pictogram_screen.dart';

class RoutinePicture extends StatelessWidget {
  const RoutinePicture(this.picture, {super.key, required this.catalog});
  final Pictogram picture;
  final CatalogStore catalog;

  @override
  Widget build(BuildContext context) => Image.network(
    catalog.imageUrl(picture).toString(),
    height: 84,
    fit: BoxFit.contain,
    cacheWidth: 240,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => const Text('Vista previa no disponible'),
  );
}

class RoutinePictograms extends StatefulWidget {
  const RoutinePictograms({
    super.key,
    required this.catalog,
    required this.initialTerm,
    required this.candidates,
  });
  final CatalogStore catalog;
  final String initialTerm;
  final List<Pictogram> candidates;

  @override
  State<RoutinePictograms> createState() => _RoutinePictogramsState();
}

class _RoutinePictogramsState extends State<RoutinePictograms> {
  late final _query = TextEditingController(text: widget.initialTerm);
  final _form = GlobalKey<FormState>();
  List<Pictogram> _local = [];
  List<Pictogram> _remote = [];
  bool _busy = true;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load({bool searching = false}) async {
    if (searching && !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final result = searching
          ? await widget.catalog.search(_query.text.trim(), alternatives: true)
          : CatalogSearch(await widget.catalog.list(), [], 'not_requested');
      if (!mounted) return;
      setState(() {
        _local = result.local;
        _remote = result.remote;
        if (result.remoteStatus == 'unavailable') {
          _notice = 'ARASAAC no está disponible. Puedes usar un pictograma guardado o importar uno propio.';
        }
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _notice = catalogError(
            error,
            'No pudimos consultar el catálogo. Reintenta.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCatalog() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => PictogramScreen(store: widget.catalog)),
    );
    if (mounted) await _load();
  }

  Widget _group(String title, List<Pictogram> pictures) => ScaaSection(
    title: title,
    icon: Icons.collections_outlined,
    child: Column(
      children: [
        for (final picture in pictures)
          Padding(
            padding: const EdgeInsets.only(bottom: ScaaLayout.gap),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.pop(context, picture),
                        child: const Text('Usar este pictograma'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Elegir pictograma')),
    body: SafeArea(
      top: false,
      child: ScaaWidth(
        child: ListView(
          padding: const EdgeInsets.all(ScaaLayout.section),
          children: [
            ScaaSection(
              title: 'Buscar en el catálogo',
              icon: Icons.search,
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _query,
                      decoration: const InputDecoration(
                        labelText: 'Término de búsqueda',
                      ),
                      validator: (text) =>
                          catalogTextError(text, 100, 'un término'),
                    ),
                    const SizedBox(height: ScaaLayout.small),
                    Wrap(
                      spacing: ScaaLayout.small,
                      runSpacing: ScaaLayout.small,
                      children: [
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _load(searching: true),
                          child: const Text('Buscar'),
                        ),
                        OutlinedButton(
                          onPressed: _busy ? null : _openCatalog,
                          child: const Text('Abrir catálogo para importar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ScaaLayout.gap),
            const ScaaNotice(
              'Los pictogramas incorporados desde el catálogo se guardan de forma independiente de esta rutina.',
            ),
            const SizedBox(height: ScaaLayout.gap),
            if (_busy)
              const LinearProgressIndicator(
                semanticsLabel: 'Buscando pictogramas',
              ),
            if (_notice != null) ...[
              ScaaNotice(_notice!, kind: ScaaNoticeKind.error),
              const SizedBox(height: ScaaLayout.gap),
            ],
            if (widget.candidates.isNotEmpty) ...[
              _group('Candidatos del paso', widget.candidates),
              const SizedBox(height: ScaaLayout.gap),
            ],
            if (_local.isNotEmpty) ...[
              _group('Pictogramas guardados', _local),
              const SizedBox(height: ScaaLayout.gap),
            ],
            if (_remote.isNotEmpty) _group('Alternativas de ARASAAC', _remote),
            if (!_busy &&
                widget.candidates.isEmpty &&
                _local.isEmpty &&
                _remote.isEmpty)
              const Text('No se encontraron pictogramas.'),
          ],
        ),
      ),
    ),
  );
}
