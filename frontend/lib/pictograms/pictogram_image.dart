import 'package:flutter/material.dart';

class PictogramImage extends StatelessWidget {
  const PictogramImage({super.key, required this.url});
  final Uri url;

  @override
  Widget build(BuildContext context) => Image.network(
    url.toString(),
    fit: BoxFit.contain,
    cacheWidth: 320,
    excludeFromSemantics: true,
    errorBuilder: (context, error, stack) =>
        const Center(child: Text('Imagen no disponible')),
  );
}
