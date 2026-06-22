import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const RodaPresaApp());
}

class RodaPresaApp extends StatelessWidget {
  const RodaPresaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roda Presa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeShell(),
    );
  }
}
