import 'package:flutter/material.dart';
import 'warna.dart';

class TemaDesaPay {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: WarnaDesaPay.primary,
      scaffoldBackgroundColor: WarnaDesaPay.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: WarnaDesaPay.primary,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WarnaDesaPay.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      cardTheme: CardTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: WarnaDesaPay.primary,
        brightness: Brightness.dark,
      ),
    );
  }
}
