import 'package:flutter/material.dart';

import 'backend_client.dart';
import 'design/scaa_components.dart';
import 'design/scaa_theme.dart';
import 'profile.dart';
import 'pictograms/catalog_api.dart';
import 'pictograms/pictogram_screen.dart';

import 'routines/routine_api.dart';
import 'routines/routines_screen.dart';

class ProfileGate extends StatefulWidget {
  const ProfileGate({
    super.key,
    required this.store,
    required this.catalog,
    required this.routines,
  });
  final ProfileStore store;
  final CatalogStore catalog;
  final RoutineStore routines;
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  ProfileData? _profile;
  bool _loading = true;
  bool _failed = false;
  bool _administration = false;
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
          _editing = _administration && profile == null;
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

  Future<void> _enterAdministration() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entrar a administración'),
        content: const Text(
          'Desde este modo se pueden modificar el perfil, los pictogramas y las rutinas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar acceso'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _administration = true;
        _editing = !_loading && !_failed && _profile == null;
      });
    }
  }

  void _exitAdministration() => setState(() {
    _administration = false;
    _editing = false;
    _saved = false;
  });

  @override
  Widget build(BuildContext context) {
    if (_administration && _editing) {
      return ProfileEditor(
        store: widget.store,
        initial: _profile,
        onCancel: () => setState(() {
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
    final profile = _profile;
    final administration = _administration;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCAA · Inicio'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: ScaaLayout.small),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _administration
                  ? _exitAdministration
                  : _enterAdministration,
              icon: Icon(
                _administration
                    ? Icons.visibility_outlined
                    : Icons.lock_outline,
              ),
              label: Text(
                _administration
                    ? 'Volver a visualización'
                    : 'Acceso de administración',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ScaaWidth(
          maxWidth: ScaaLayout.contentWidth,
          child: ListView(
            padding: const EdgeInsets.all(ScaaLayout.section),
            children: [
              ScaaModeBanner(administration: _administration),
              const SizedBox(height: ScaaLayout.gap),
              if (profile != null) ...[
                Text(
                  'Hola, ${profile.alias}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: ScaaLayout.gap),
              ],
              if (_administration && _loading)
                const LinearProgressIndicator(
                  semanticsLabel: 'Cargando perfil',
                ),
              if (_administration && _failed) ...[
                const ScaaNotice(
                  'No pudimos cargar tu perfil.',
                  kind: ScaaNoticeKind.error,
                ),
                TextButton(onPressed: _load, child: const Text('Reintentar')),
              ],
              if (_saved) ...[
                const ScaaNotice(
                  'Perfil guardado',
                  kind: ScaaNoticeKind.success,
                ),
                const SizedBox(height: ScaaLayout.gap),
              ],
              Wrap(
                spacing: ScaaLayout.small,
                runSpacing: ScaaLayout.small,
                children: [
                  if (_administration && !_loading && !_failed)
                    FilledButton.icon(
                      key: const ValueKey('edit-profile'),
                      onPressed: () => setState(() {
                        _editing = true;
                        _saved = false;
                      }),
                      icon: const Icon(Icons.person_outline),
                      label: Text(
                        profile == null
                            ? 'Configurar perfil'
                            : 'Perfil y contexto',
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PictogramScreen(
                          store: widget.catalog,
                          administration: administration,
                          onExitAdministration: _exitAdministration,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.collections_outlined),
                    label: const Text('Pictogramas'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoutinesScreen(
                          store: widget.routines,
                          catalog: widget.catalog,
                          administration: administration,
                          onExitAdministration: _exitAdministration,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.event_note_outlined),
                    label: const Text('Rutinas'),
                  ),
                ],
              ),
              const SizedBox(height: ScaaLayout.section),
              if (_administration && profile != null)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final cardWidth = width >= ScaaLayout.twoColumns
                        ? (width - ScaaLayout.gap) / 2
                        : width;
                    return Wrap(
                      spacing: ScaaLayout.gap,
                      runSpacing: ScaaLayout.gap,
                      children: [
                        for (final kind in ContextKind.values)
                          SizedBox(
                            width: cardWidth,
                            child: ScaaSection(
                              title: kind.title,
                              icon: _contextIcon(kind),
                              child: profile.values(kind).isEmpty
                                  ? const Text('Sin elementos registrados')
                                  : Wrap(
                                      spacing: ScaaLayout.small,
                                      runSpacing: ScaaLayout.small,
                                      children: [
                                        for (final value in profile.values(
                                          kind,
                                        ))
                                          Chip(label: Text(value)),
                                      ],
                                    ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _contextIcon(ContextKind kind) => switch (kind) {
  ContextKind.interest => Icons.favorite_outline,
  ContextKind.activity => Icons.directions_walk_outlined,
  ContextKind.routine => Icons.event_repeat_outlined,
};

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
      body: SafeArea(
        bottom: false,
        child: ScaaWidth(
          child: Form(
            key: _form,
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(ScaaLayout.section),
              children: [
                if (_error == null)
                  const SizedBox.shrink()
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: ScaaLayout.gap),
                    child: ScaaNotice(
                      _error!,
                      key: const ValueKey('save-error'),
                      kind: ScaaNoticeKind.error,
                    ),
                  ),
                if (widget.initial == null) ...[
                  const ScaaNotice('Un alias es suficiente para comenzar.'),
                  const SizedBox(height: ScaaLayout.gap),
                ],
                ScaaSection(
                  title: 'Datos del perfil',
                  icon: Icons.person_outline,
                  child: TextFormField(
                    key: const ValueKey('alias'),
                    controller: _alias,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Alias',
                      helperText: 'Obligatorio · de 1 a 50 caracteres',
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => _validate(value),
                  ),
                ),
                for (final kind in ContextKind.values) ...[
                  const SizedBox(height: ScaaLayout.gap),
                  ScaaSection(
                    title: kind.title,
                    icon: _contextIcon(kind),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Opcional · hasta 50 caracteres por elemento',
                        ),
                        for (var i = 0; i < _items[kind]!.length; i++)
                          Padding(
                            key: ObjectKey(_items[kind]![i]),
                            padding: const EdgeInsets.only(top: ScaaLayout.gap),
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
                                  color: Theme.of(context).colorScheme.error,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: ScaaLayout.small),
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
                ],
              ],
            ),
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
                  if (widget.onCancel != null)
                    OutlinedButton(
                      onPressed: _saving ? null : widget.onCancel,
                      child: const Text('Cancelar'),
                    ),
                  ScaaConfirmButton(
                    key: const ValueKey('save-profile'),
                    onPressed: _saving ? null : _save,
                    label: _saving ? 'Guardando…' : 'Guardar',
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
