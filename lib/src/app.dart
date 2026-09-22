import 'package:flutter/material.dart';

import 'data/open_facts_client.dart';
import 'ui/home_page.dart';

class CibusApp extends StatelessWidget {
  const CibusApp({super.key, OpenFactsClient? client}) : _client = client;

  final OpenFactsClient? _client;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF176B4D);
    return MaterialApp(
      title: 'Cibus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: const Color(0xFFF7F8F5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F5),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: Color(0xFFE1E5DF)),
          ),
        ),
      ),
      home: HomePage(client: _client ?? OpenFactsClient()),
    );
  }
}
