import 'package:flutter/material.dart';

import 'features/mountains/presentation/mountains_check_page.dart';

class SannoteApp extends StatelessWidget {
  const SannoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '산노트',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        useMaterial3: true,
      ),
      home: const MountainsCheckPage(),
    );
  }
}
