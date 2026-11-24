import 'package:flutter/material.dart';

import '../design/scaa_components.dart';
import '../design/scaa_theme.dart';
import '../pictograms/catalog_api.dart';
import '../pictograms/catalog_controls.dart';
import 'routine_api.dart';
import 'routine_editor.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key, required this.store, required this.catalog});
  final RoutineStore store;
  final CatalogStore catalog;

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  List<RoutineData> _routines = [];
  bool _busy = true;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.store.list();
      if (mounted) setState(() => _routines = data);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = catalogError(error, 'No pudimos cargar las rutinas.'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open({int? id}) async {
    Widget screen;
    if (id == null) {
      screen = _RoutineStart(store: widget.store, catalog: widget.catalog);
    } else {
      setState(() {
        _busy = true;
        _error = null;
      });
      try {
        final data = await widget.store.get(id);
        screen = RoutineEditor(
          store: widget.store,
          catalog: widget.catalog,
          initial: data,
          generated: false,
        );
      } catch (error) {
        if (mounted) {
          setState(
            () => _error = catalogError(error, 'No pudimos abrir la rutina.'),
          );
        }
        return;
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    if (!mounted) return;
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (result != null && mounted) {
      setState(() => _success = result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SCAA · Rutinas')),
    body: SafeArea(
      top: false,
      child: ScaaWidth(
        maxWidth: ScaaLayout.contentWidth,
        child: ListView(
          padding: const EdgeInsets.all(ScaaLayout.section),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _open(),
                icon: const Icon(Icons.add),
                label: const Text('Crear rutina'),
              ),
            ),
            const SizedBox(height: ScaaLayout.gap),
            if (_success != null) ...[
              ScaaNotice(_success!, kind: ScaaNoticeKind.success),
              const SizedBox(height: ScaaLayout.gap),
            ],
            if (_error != null) ...[
              ScaaNotice(_error!, kind: ScaaNoticeKind.error),
              TextButton(
                onPressed: _busy ? null : _load,
                child: const Text('Recargar rutinas'),
              ),
            ],
            if (_busy)
              const LinearProgressIndicator(semanticsLabel: 'Cargando rutinas')
            else
              ScaaSection(
                title: 'Rutinas guardadas',
                icon: Icons.event_note_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_routines.isEmpty && _error == null)
                      const Text('Todavía no hay rutinas guardadas.'),
                    for (final routine in _routines)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(routine.name),
                        subtitle: Text('${routine.steps.length} pasos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(id: routine.id),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _RoutineStart extends StatefulWidget {
  const _RoutineStart({required this.store, required this.catalog});
  final RoutineStore store;
  final CatalogStore catalog;

  @override
  State<_RoutineStart> createState() => _RoutineStartState();
}

class _RoutineStartState extends State<_RoutineStart> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _edit(RoutineData data, {required bool generated}) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineEditor(
          store: widget.store,
          catalog: widget.catalog,
          initial: data,
          generated: generated,
        ),
      ),
    );
    if (result != null && mounted) Navigator.pop(context, result);
  }

  Future<void> _generate() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    RoutineData? data;
    try {
      data = await widget.store.generate(_description.text.trim());
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = catalogError(
            error,
            'No pudimos generar una propuesta. Puedes crear la rutina manualmente.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (data != null && mounted) await _edit(data, generated: true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crear rutina')),
    body: SafeArea(
      top: false,
      child: ScaaWidth(
        child: ListView(
          padding: const EdgeInsets.all(ScaaLayout.section),
          children: [
            ScaaSection(
              title: 'Describe la rutina',
              icon: Icons.edit_note,
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _description,
                      enabled: !_loading,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Por ejemplo, prepararse para ir al colegio',
                      ),
                      validator: (value) =>
                          catalogTextError(value, 500, 'una descripción'),
                    ),
                    const SizedBox(height: ScaaLayout.gap),
                    Wrap(
                      spacing: ScaaLayout.small,
                      runSpacing: ScaaLayout.small,
                      children: [
                        FilledButton.icon(
                          onPressed: _loading ? null : _generate,
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('Generar propuesta'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _edit(
                                  RoutineData(
                                    description: _description.text.trim(),
                                    steps: [RoutineStep()],
                                  ),
                                  generated: false,
                                ),
                          icon: const Icon(Icons.playlist_add),
                          label: const Text('Crear manualmente'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ScaaLayout.gap),
            if (_loading) ...[
              const ScaaNotice('Generando propuesta…'),
              const SizedBox(height: ScaaLayout.small),
              const LinearProgressIndicator(
                semanticsLabel: 'Generando propuesta',
              ),
            ],
            if (_error != null) ScaaNotice(_error!, kind: ScaaNoticeKind.error),
          ],
        ),
      ),
    ),
  );
}
