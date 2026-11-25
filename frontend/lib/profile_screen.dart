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
    return LayoutBuilder(
      builder: (context, constraints) => _buildHome(
        context,
        compactHeader: constraints.maxWidth < ScaaLayout.twoColumns,
      ),
    );
  }

  Widget _buildHome(BuildContext context, {required bool compactHeader}) {
    final profile = _profile;
    final administration = _administration;
    final theme = Theme.of(context);
    final modeAction = administration
        ? 'Volver a visualización'
        : 'Acceso de administración';
    final modeIcon = Icon(
      administration ? Icons.visibility_outlined : Icons.lock_outline,
    );
    final changeMode = administration
        ? _exitAdministration
        : _enterAdministration;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline),
            SizedBox(width: ScaaLayout.small),
            Flexible(child: Text('SCAA Inteligente')),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: ScaaLayout.small),
            child: compactHeader
                ? IconButton(
                    icon: modeIcon,
                    tooltip: modeAction,
                    onPressed: changeMode,
                  )
                : TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(
                        ScaaLayout.touch,
                        ScaaLayout.touch,
                      ),
                    ),
                    onPressed: changeMode,
                    icon: modeIcon,
                    label: Text(modeAction),
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
              const SizedBox(height: ScaaLayout.section),
              Semantics(
                header: true,
                child: Text(
                  profile == null ? '¡Hola!' : '¡Hola, ${profile.alias}!',
                  textAlign: TextAlign.center,
                  style:
                      (compactHeader
                              ? theme.textTheme.displaySmall
                              : theme.textTheme.displayMedium)
                          ?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                ),
              ),
              const SizedBox(height: ScaaLayout.small),
              Text(
                'Tu espacio de comunicación',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: ScaaLayout.section),
              if (administration && _loading)
                const LinearProgressIndicator(
                  semanticsLabel: 'Cargando perfil',
                ),
              if (administration && _failed) ...[
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
              if (administration && !_loading && !_failed) ...[
                Center(
                  child: FilledButton.icon(
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
                ),
                const SizedBox(height: ScaaLayout.gap),
              ],
              LayoutBuilder(
                builder: (context, constraints) {
                  final sideBySide =
                      constraints.maxWidth >= ScaaLayout.twoColumns;
                  final gap = sideBySide ? ScaaLayout.section : ScaaLayout.gap;
                  final cardWidth = sideBySide
                      ? (constraints.maxWidth - gap) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _WelcomeDestination(
                          label: 'Pictogramas',
                          icon: Icons.collections_outlined,
                          expanded: sideBySide,
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PictogramScreen(
                                store: widget.catalog,
                                administration: administration,
                                onExitAdministration: _exitAdministration,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _WelcomeDestination(
                          label: 'Rutinas',
                          icon: Icons.format_list_numbered,
                          expanded: sideBySide,
                          onTap: () => Navigator.push<void>(
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
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: ScaaLayout.section),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: ScaaModeBanner(administration: administration),
                ),
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

class _WelcomeDestination extends StatelessWidget {
  const _WelcomeDestination({
    required this.label,
    required this.icon,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      elevation: 4,
      shadowColor: colors.primary.withValues(alpha: 0.22),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: expanded ? 256 : 208),
            padding: const EdgeInsets.all(ScaaLayout.section),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(ScaaLayout.radius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(ScaaLayout.gap),
                      child: Icon(
                        icon,
                        size: expanded ? 72 : 56,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ScaaLayout.gap),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
