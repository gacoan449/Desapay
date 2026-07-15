import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/home/home_screen.dart'; // Sesuaikan path ini dengan project Anda

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Membaca file konfigurasi rahasia .env
  await dotenv.load(fileName: ".env");

  // 2. Inisialisasi Firebase secara aman menggunakan opsi Dotenv
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DesaPay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
