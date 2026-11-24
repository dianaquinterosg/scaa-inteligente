import 'package:flutter/material.dart';

import 'scaa_theme.dart';

class ScaaWidth extends StatelessWidget {
  const ScaaWidth({
    super.key,
    required this.child,
    this.maxWidth = ScaaLayout.formWidth,
    this.shrinkHeight = false,
  });
  final Widget child;
  final double maxWidth;
  final bool shrinkHeight;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: shrinkHeight ? 1 : null,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class ScaaSection extends StatelessWidget {
  const ScaaSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(ScaaLayout.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: ScaaLayout.small),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ScaaLayout.small),
          child,
        ],
      ),
    ),
  );
}

enum ScaaNoticeKind { info, success, error }

class ScaaNotice extends StatelessWidget {
  const ScaaNotice(this.message, {super.key, this.kind = ScaaNoticeKind.info});
  final String message;
  final ScaaNoticeKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (kind) {
      ScaaNoticeKind.info => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.info_outline,
      ),
      ScaaNoticeKind.success => (
        ScaaTheme.confirmBackground,
        ScaaTheme.onConfirmBackground,
        Icons.check_circle_outline,
      ),
      ScaaNoticeKind.error => (
        colors.errorContainer,
        colors.onErrorContainer,
        Icons.error_outline,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(ScaaLayout.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ScaaLayout.gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(icon, color: foreground)),
              const SizedBox(width: ScaaLayout.small),
              Expanded(
                child: Text(message, style: TextStyle(color: foreground)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScaaConfirmButton extends StatelessWidget {
  const ScaaConfirmButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    style: FilledButton.styleFrom(
      backgroundColor: ScaaTheme.confirm,
      foregroundColor: Colors.white,
    ),
    onPressed: onPressed,
    icon: const Icon(Icons.check),
    label: Text(label, textAlign: TextAlign.center),
  );
}
