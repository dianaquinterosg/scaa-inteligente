import 'package:flutter/material.dart';

import '../backend_client.dart';

String catalogError(Object error, String fallback) =>
    error is ApiException ? error.message : fallback;

String? catalogTextError(String? text, int maximum, String field) {
  final value = (text ?? '').trim();
  if (value.isEmpty) return 'Ingresa $field.';
  if (value.runes.length > maximum) return 'Máximo $maximum caracteres.';
  return null;
}

Future<bool> confirmDeletion(
  BuildContext context, {
  required String title,
  required String message,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ??
    false;
