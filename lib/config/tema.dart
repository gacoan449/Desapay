import 'package:flutter/material.dart';
import '../../config/warna.dart'; // DIKOREKSI: Path import disesuaikan dengan arsitektur folder config Anda

class TemaDesaPay {
  // ===================================================
  // 1. LIGHT THEME CONFIGURATION (TERANG PREMIUM)
  // ===================================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: WarnaDesaPay.primary,
      scaffoldBackgroundColor: const Color(0xffF8FAFC), // Disinkronkan dengan latar belakang layar premium baru

      colorScheme: ColorScheme.fromSeed(
        seedColor: WarnaDesaPay.primary,
        brightness: Brightness.light,
        background: const Color(0xffF8FAFC),
      ),

      // APP BAR THEME (Disinkronkan dengan gaya status bar modern)
      appBarTheme: AppBarTheme(
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0, // Mencegah perubahan warna AppBar saat di-scroll
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),

      // ELEVATED BUTTON GLOBAL THEME
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WarnaDesaPay.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54), // Menyesuaikan tinggi 54px ala e-wallet premium
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Lengkungan sudut modern 16px
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // CARD GLOBAL THEME
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0, // Mengutamakan bayangan kontras tipis dibanding elevasi solid
        surfaceTintColor: Colors.white, // Menghilangkan bias warna ungu Material 3
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Diselaraskan dengan gelembung kartu transaksi baru
        ),
        margin: EdgeInsets.zero,
      ),

      // DEKORASI GLOBAL TEXT FIELD (INPUT FIELD THEME)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Warna abu-putih terang premium default
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: WarnaDesaPay.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ===================================================
  // 2. DARK THEME CONFIGURATION (GELAP NYAMAN DI MATA)
  // ===================================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: WarnaDesaPay.primary,
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Warna dasar slate dark premium (bukan hitam pekat)

      colorScheme: ColorScheme.fromSeed(
        seedColor: WarnaDesaPay.primary,
        brightness: Brightness.dark,
        background: const Color(0xFF0F172A),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B), // Warna kontras abu tua untuk AppBar gelap
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WarnaDesaPay.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: WarnaDesaPay.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
