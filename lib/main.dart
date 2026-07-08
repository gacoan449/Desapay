import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'config/tema.dart';
import 'screens/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(const DesaPayApp());
  } catch (e) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text(
              'Firebase gagal diinisialisasi.\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
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
