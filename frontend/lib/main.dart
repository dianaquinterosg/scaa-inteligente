import 'package:flutter/material.dart';

import 'profile.dart';
import 'profile_screen.dart';

void main() => runApp(const ScaaApp());

class ScaaApp extends StatelessWidget {
  const ScaaApp({super.key, this.checkConnection, this.profileStore});

  final Future<void> Function()? checkConnection;
  final ProfileStore? profileStore;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SCAA Inteligente',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF246A73)),
      scaffoldBackgroundColor: const Color(0xFFF4F7F7),
      useMaterial3: true,
    ),
    home: checkConnection == null
        ? ProfileGate(store: profileStore ?? ProfileApi())
        : ConnectionScreen(check: checkConnection!),
  );
}

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key, required this.check});

  final Future<void> Function() check;

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late Future<void> _connection;

  @override
  void initState() {
    super.initState();
    _connection = widget.check();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SCAA Inteligente')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: FutureBuilder<void>(
                  future: _connection,
                  builder: (context, snapshot) {
                    final loading =
                        snapshot.connectionState != ConnectionState.done;
                    final failed = snapshot.hasError;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          loading
                              ? Icons.sync
                              : failed
                              ? Icons.cloud_off
                              : Icons.check_circle_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Preparación del MVP',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loading
                              ? 'Comprobando conexión…'
                              : failed
                              ? 'No pudimos conectar con el servidor.'
                              : 'Servidor disponible',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Esta pantalla verifica la conexión inicial. Las funciones del proyecto se incorporarán en las siguientes iteraciones.',
                        ),
                        const SizedBox(height: 24),
                        if (loading)
                          const LinearProgressIndicator(
                            semanticsLabel: 'Comprobando conexión',
                          )
                        else
                          FilledButton(
                            onPressed: () => setState(() {
                              _connection = widget.check();
                            }),
                            child: Text(
                              failed ? 'Reintentar' : 'Comprobar de nuevo',
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
