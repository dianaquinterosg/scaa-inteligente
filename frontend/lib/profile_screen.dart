import 'package:flutter/material.dart';

import 'backend_client.dart';
import 'profile.dart';

class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key, required this.store});
  final ProfileStore store;
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  ProfileData? _profile;
  bool _loading = true;
  bool _failed = false;
  bool _editing = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final profile = await widget.store.load();
      if (mounted) {
        setState(() {
          _profile = profile;
          _editing = profile == null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _failed) {
      return Scaffold(
        appBar: AppBar(title: const Text('SCAA Inteligente')),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No pudimos cargar tu perfil.'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
        ),
      );
    }
    if (_editing) {
      return ProfileEditor(
        store: widget.store,
        initial: _profile,
        onCancel: _profile == null
            ? null
            : () => setState(() {
                _editing = false;
                _saved = false;
              }),
        onSaved: (profile) => setState(() {
          _profile = profile;
          _editing = false;
          _saved = true;
        }),
      );
    }
    final profile = _profile!;
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Hola, ${profile.alias}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (_saved)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Perfil guardado'),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('edit-profile'),
                onPressed: () => setState(() {
                  _editing = true;
                  _saved = false;
                }),
                icon: const Icon(Icons.person_outline),
                label: const Text('Perfil y contexto'),
              ),
              const SizedBox(height: 24),
              for (final kind in ContextKind.values)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kind.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (profile.values(kind).isEmpty)
                          const Text('Sin elementos registrados')
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final value in profile.values(kind))
                                Chip(
                                  label: Text(
                                    value,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({
    super.key,
    required this.store,
    required this.onSaved,
    this.initial,
    this.onCancel,
  });
  final ProfileStore store;
  final ProfileData? initial;
  final ValueChanged<ProfileData> onSaved;
  final VoidCallback? onCancel;
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  late final TextEditingController _alias;
  late final Map<ContextKind, List<TextEditingController>> _items;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _alias = TextEditingController(text: widget.initial?.alias ?? '');
    _items = {
      for (final kind in ContextKind.values)
        kind: [
          for (final value in widget.initial?.values(kind) ?? <String>[])
            TextEditingController(text: value),
        ],
    };
  }

  @override
  void dispose() {
    _scroll.dispose();
    _alias.dispose();
    for (final list in _items.values) {
      for (final controller in list) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  String? _validate(
    String? text, {
    ContextKind? kind,
    TextEditingController? controller,
  }) {
    final value = (text ?? '').trim();
    if (value.isEmpty) {
      return kind == null
          ? 'Ingresa un alias.'
          : 'Completa este elemento o elimínalo.';
    }
    if (value.runes.length > 50) return 'Máximo 50 caracteres.';
    if (kind != null &&
        _items[kind]!.any(
          (other) =>
              other != controller &&
              other.text.trim().toLowerCase() == value.toLowerCase(),
        )) {
      return 'Este elemento ya existe en ${kind.title.toLowerCase()}.';
    }
    return null;
  }

  Future<void> _save() async {
    var valid = _form.currentState!.validate();
    if (_validate(_alias.text) != null) valid = false;
    for (final kind in ContextKind.values) {
      for (final item in _items[kind]!) {
        if (_validate(item.text, kind: kind, controller: item) != null) {
          valid = false;
        }
      }
    }
    if (!valid) {
      setState(() {
        _error = 'Revisa los campos del formulario.';
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    List<String> values(ContextKind kind) =>
        _items[kind]!.map((item) => item.text.trim()).toList();
    final draft = ProfileData(
      alias: _alias.text.trim(),
      interests: values(ContextKind.interest),
      activities: values(ContextKind.activity),
      frequentRoutines: values(ContextKind.routine),
    );
    try {
      final profile = await widget.store.save(draft);
      if (mounted) widget.onSaved(profile);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is ApiException ? error.message : 'No pudimos confirmar el guardado. Tus cambios siguen en edición.';
        });
        if (_scroll.hasClients) _scroll.jumpTo(0);
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !_saving) widget.onCancel?.call();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? 'Configurar perfil' : 'Perfil y contexto',
        ),
        automaticallyImplyLeading: false,
        leading: widget.onCancel == null
            ? null
            : IconButton(
                tooltip: 'Cancelar edición',
                onPressed: _saving ? null : widget.onCancel,
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _form,
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  widget.initial == null
                      ? 'Un alias es suficiente para comenzar.'
                      : 'Edita tu perfil y contexto.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        key: const ValueKey('save-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                TextFormField(
                  key: const ValueKey('alias'),
                  controller: _alias,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Alias',
                    helperText: 'Obligatorio · de 1 a 50 caracteres',
                    border: OutlineInputBorder(),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => _validate(value),
                ),
                const SizedBox(height: 24),
                for (final kind in ContextKind.values)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            kind.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Text(
                            'Opcional · hasta 50 caracteres por elemento',
                          ),
                          for (var i = 0; i < _items[kind]!.length; i++)
                            Padding(
                              key: ObjectKey(_items[kind]![i]),
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      key: ValueKey('${kind.field}-$i'),
                                      controller: _items[kind]![i],
                                      enabled: !_saving,
                                      decoration: InputDecoration(
                                        labelText: '${kind.itemLabel} ${i + 1}',
                                        border: const OutlineInputBorder(),
                                      ),
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (value) => _validate(
                                        value,
                                        kind: kind,
                                        controller: _items[kind]![i],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    key: ValueKey('remove-${kind.field}-$i'),
                                    tooltip:
                                        'Eliminar ${kind.itemLabel} ${i + 1}',
                                    onPressed: _saving
                                        ? null
                                        : () => setState(() {
                                            _items[kind]!.removeAt(i).dispose();
                                          }),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: ValueKey('add-${kind.field}'),
                            onPressed: _saving
                                ? null
                                : () => setState(() {
                                    _items[kind]!.add(TextEditingController());
                                  }),
                            icon: const Icon(Icons.add),
                            label: Text('Añadir ${kind.itemLabel}'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (widget.onCancel != null) ...[
                OutlinedButton(
                  onPressed: _saving ? null : widget.onCancel,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: FilledButton(
                  key: const ValueKey('save-profile'),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Guardando…' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
