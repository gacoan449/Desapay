import 'package:flutter/material.dart';

class WarnaDesaPay {
  // ===================================================
  // 1. BRAND COLORS (FINTECH PREMIUM)
  // ===================================================
  static const Color primary = Color(0xFF0A55D6);      // Deep Royal Blue (DANA & Stripe Style)
  static const Color secondary = Color(0xFF00C4FF);    // Electric Teal / Cyan Accent
  static const Color background = Color(0xFFF8FAFC);   // Ultra-light Slate (Sangat bersih)
  
  // ===================================================
  // 2. MONOCHROME & NEUTRALS (SLATE THEME)
  // ===================================================
  static const Color white = Colors.white;
  static const Color greyLight = Color(0xFFF1F5F9);    // Latar input & border tipis
  static const Color textMain = Color(0xFF0F172A);     // Slate 900 (Ganti dari hitam pekat agar teks terasa premium)
  static const Color textSub = Color(0xFF64748B);      // Slate 500 (Warna abu-abu estetik untuk teks panduan)

  // ===================================================
  // 3. TRANSACTION STATUS (VIBRANT SYSTEM COLORS)
  // ===================================================
  static const Color success = Color(0xFF10B981);     // Emerald Green (Sukses Transaksi)
  static const Color danger = Color(0xFFEF4444);      // Rose Scarlet (Gagal Transaksi)
  static const Color warning = Color(0xFFF59E0B);     // Vibrant Amber / Gold (Menunggu Pembayaran)

  // ===================================================
  // 4. EXTRA ACCENTS (OPTIONAL DECORATIONS)
  // ===================================================
  static const Color shadow = Color(0x0A0F172A);      // Soft Slate shadow untuk efek kartu melayang
}
