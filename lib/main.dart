import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  // 1. Memastikan seluruh engine UI native tersambung sempurna sebelum load data
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 2. Memuat berkas kredensial rahasia secara aman
    await dotenv.load(fileName: ".env");
    
    // 3. Inisialisasi Firebase Core menggunakan opsi environment terenkripsi
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Fallback log jika terjadi kesalahan konfigurasi pada hardware local
    debugPrint("Inisialisasi Sistem DesaPay Terhambat: $e");
  }

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
        primaryColor: WarnaDesaPay.primary,
        scaffoldBackgroundColor: const Color(0xffF4F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
