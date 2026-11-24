import 'package:flutter/material.dart';

import '../design/scaa_components.dart';
import '../design/scaa_theme.dart';
import 'catalog_api.dart';
import 'catalog_controls.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({
    super.key,
    required this.store,
    required this.categories,
  });
  final CatalogStore store;
  final List<Category> categories;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  late List<Category> _categories = widget.categories;
  Category? _editing;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _change(Future<void> Function() action) async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await action();
      final categories = await widget.store.categories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _editing = null;
        _name.clear();
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = catalogError(
            error,
            'No pudimos completar la operación. Reintenta.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final name = _name.text.trim();
    await _change(() => widget.store.saveCategory(name, id: _editing?.id));
  }

  Future<void> _delete(Category category) async {
    if (!await confirmDeletion(
          context,
          title: '¿Eliminar ${category.name}?',
          message: 'Se quitará esta categoría. Los pictogramas y sus otras categorías se conservarán.',
        ) ||
        !mounted) {
      return;
    }
    await _change(() => widget.store.deleteCategory(category.id));
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: SafeArea(
        top: false,
        child: ScaaWidth(
          child: ListView(
            padding: const EdgeInsets.all(ScaaLayout.section),
            children: [
              ScaaSection(
                title: _editing == null
                    ? 'Crear categoría'
                    : 'Renombrar categoría',
                icon: Icons.folder_outlined,
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        enabled: !_busy,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (text) =>
                            catalogTextError(text, 50, 'un nombre'),
                      ),
                      const SizedBox(height: ScaaLayout.gap),
                      if (_error != null) ...[
                        ScaaNotice(_error!, kind: ScaaNoticeKind.error),
                        const SizedBox(height: ScaaLayout.gap),
                      ],
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        spacing: ScaaLayout.small,
                        overflowSpacing: ScaaLayout.small,
                        children: [
                          if (_editing != null)
                            OutlinedButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                      _editing = null;
                                      _error = null;
                                      _name.clear();
                                    }),
                              child: const Text('Cancelar edición'),
                            ),
                          ScaaConfirmButton(
                            onPressed: _busy ? null : _save,
                            label: _busy ? 'Procesando…' : 'Guardar categoría',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ScaaLayout.section),
              ScaaSection(
                title: 'Categorías guardadas',
                icon: Icons.folder_open_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_categories.isEmpty)
                      const Text('Todavía no hay categorías.'),
                    for (final category in _categories)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(category.name),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              tooltip: 'Renombrar ${category.name}',
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                      _editing = category;
                                      _error = null;
                                      _name.text = category.name;
                                    }),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Eliminar ${category.name}',
                              color: Theme.of(context).colorScheme.error,
                              onPressed: _busy ? null : () => _delete(category),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
