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
                          const Text('La escala usa datos nutricionales por 100 g o 100 ml y reglas públicas documentadas.'),
                          const SizedBox(height: 16),
                          const _ScaleRow(color: Color(0xFF218739), label: 'Verde · perfil favorable'),
                          const _ScaleRow(color: Color(0xFFF4C430), label: 'Amarillo · atención moderada'),
                          const _ScaleRow(color: Color(0xFFE87722), label: 'Naranja · atención elevada'),
                          const _ScaleRow(color: Color(0xFFC62828), label: 'Rojo · atención muy elevada'),
                          const Divider(height: 28),
                          const Row(children: [
                            Icon(Icons.help_outline_rounded, color: Color(0xFF66736E)),
                            SizedBox(width: 10),
                            Expanded(child: Text('Datos insuficientes · se explica qué falta')),
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
  const _ScaleRow({required this.color, required this.label});
  final Color color;
  final String label;

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
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
}
