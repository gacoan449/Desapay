import 'package:flutter/material.dart';
import 'config/tema.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const DesaPayApp());
}

class DesaPayApp extends StatelessWidget {
  const DesaPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DesaPay',
      debugShowCheckedModeBanner: false,
      theme: TemaDesaPay.lightTheme,
      darkTheme: TemaDesaPay.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
