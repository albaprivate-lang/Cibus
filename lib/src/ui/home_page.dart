import 'package:flutter/material.dart';

import '../data/open_facts_client.dart';
import 'scanner_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.client});

  final OpenFactsClient client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.eco_rounded, size: 48, color: Color(0xFF176B4D)),
                  const SizedBox(height: 8),
                  Text(
                    'Cibus',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF143D30),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Entiende lo que eliges',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF597068),
                        ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    key: const Key('scan-button'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ScannerPage(client: client),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 17),
                      child: Text('Escanear código de barras'),
                    ),
                    style: FilledButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Escala Cibus', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          const Text('La escala se aplicará cuando existan reglas verificadas y datos suficientes.'),
                          const SizedBox(height: 16),
                          const _ScaleRow(color: Color(0xFF2E9D67), label: 'Excelente'),
                          const _ScaleRow(color: Color(0xFFF3F4EF), label: 'Bueno', border: true),
                          const _ScaleRow(color: Color(0xFFE99736), label: 'Mejorable'),
                          const _ScaleRow(color: Color(0xFFD7504B), label: 'Poco recomendable'),
                          const Divider(height: 28),
                          const Row(children: [
                            Icon(Icons.help_outline_rounded, color: Color(0xFF66736E)),
                            SizedBox(width: 10),
                            Expanded(child: Text('Datos insuficientes / Análisis en desarrollo')),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Datos abiertos · Valoración independiente y explicable',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF66736E)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({required this.color, required this.label, this.border = false});
  final Color color;
  final String label;
  final bool border;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: border ? Border.all(color: const Color(0xFFB8BFBA)) : null,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
}
