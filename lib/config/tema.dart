import 'package:flutter/material.dart';

/// Palet Warna Konstan dan Eksklusif untuk Identitas Visual Premium DesaPay
class WarnaDesaPay {
  static const Color primary = Color(0xFF1E3A8A);      // Royal Blue Utama DesaPay
  static const Color secondary = Color(0xFF06B6D4);    // Cyan Modern untuk Aksen
  static const Color lightBg = Color(0xFFF8FAFC);      // Slate 50 untuk Latar Terang
  static const Color darkBg = Color(0xFF0F172A);       // Slate 900 untuk Latar Gelap
  static const Color darkCard = Color(0xFF1E293B);     // Slate 800 untuk Komponen Gelap
  static const Color lightField = Color(0xFFF1F5F9);    // Slate 100 untuk Field Terang
}

/// Konfigurasi Mesin Tema Global DesaPay untuk Light & Dark Mode (Presentation Layer)
class TemaDesaPay {
  
  // =========================================================================
  // 1. LIGHT THEME CONFIGURATION (TERANG PREMIUM & KONTRAST TINGGI)
  // =========================================================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: WarnaDesaPay.primary,
      scaffoldBackgroundColor: WarnaDesaPay.lightBg,
      
      // Integrasi Ink Ripple Halus Kelas Industri
      splashFactory: InkRipple.splashFactory,

      // Konfigurasi Skema Warna yang Sesuai dengan Dart SDK Terbaru (No Deprecated)
      colorScheme: ColorScheme.fromSeed(
        seedColor: WarnaDesaPay.primary,
        brightness: Brightness.light,
        surface: WarnaDesaPay.lightBg,
        onSurface: const Color(0xFF0F172A), // Slate 900
      ),

      // APP BAR THEME (Gaya Flat Premium Kontemporer)
      appBarTheme: const AppBarTheme(
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0, // Mencegah glitch warna saat listview digulir
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),

      // ELEVATED BUTTON GLOBAL THEME (Standardisasi Tinggi Fintech 54px)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WarnaDesaPay.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shadowColor: Colors.transparent,
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

      // CARD GLOBAL THEME
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white, // Menghilangkan bias warna Material 3 ungu kasar
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      // DEKORASI INPUT FIELD UTAMA (FORMULIR INPUT NUMBER & TEXT)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WarnaDesaPay.lightField,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500), // Slate 400
        labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14), // Slate 600
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
          borderSide: const BorderSide(
            color: WarnaDesaPay.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 2. DARK THEME CONFIGURATION (SLATE LUXURY COMFORT - ANTI SILAU)
  // =========================================================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: WarnaDesaPay.primary,
      scaffoldBackgroundColor: WarnaDesaPay.darkBg,
      splashFactory: InkRipple.splashFactory,

      colorScheme: ColorScheme.fromSeed(
        seedColor: WarnaDesaPay.primary,
        brightness: Brightness.dark,
        surface: WarnaDesaPay.darkBg,
        onSurface: Colors.white,
      ),

      // APP BAR THEME DARK
      appBarTheme: const AppBarTheme(
        backgroundColor: WarnaDesaPay.darkCard,
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

      // ELEVATED BUTTON DARK
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WarnaDesaPay.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shadowColor: Colors.transparent,
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

      // CARD THEME DARK
      cardTheme: CardThemeData(
        color: WarnaDesaPay.darkCard,
        elevation: 0,
        surfaceTintColor: WarnaDesaPay.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      // DEKORASI INPUT FIELD DARK
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WarnaDesaPay.darkCard,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500), // Slate 500
        labelStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14), // Slate 300
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
          borderSide: const BorderSide(
            color: WarnaDesaPay.secondary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
