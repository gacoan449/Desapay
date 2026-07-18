import 'package:flutter/material.dart';

/// Pusat Manajemen Palet Warna Resmi DesaPay Premium (Core System Layer)
/// Menggunakan pendekatan Slate-Neutral untuk menghasilkan UI/UX berkelas industri.
class WarnaDesaPay {
  // =========================================================================
  // 1. BRAND COLORS (FINTECH PREMIUM & IDENTITY)
  // =========================================================================
  static const Color primary = Color(0xFF0A55D6);      // Deep Royal Blue (DANA & Stripe Style)
  static const Color secondary = Color(0xFF00C4FF);    // Electric Teal / Cyan Accent

  // =========================================================================
  // 2. LIGHT MODE PALETTE (SANGAT BERSIH & KONTRAST TINGGI)
  // =========================================================================
  static const Color lightBg = Color(0xFFF8FAFC);      // Slate 50 - Latar Belakang Aplikasi
  static const Color lightCard = Colors.white;         // Putih Murni - Latar Belakang Kartu/Kontainer
  static const Color lightField = Color(0xFFF1F5F9);    // Slate 100 - Latar Belakang Text Input / Border

  // =========================================================================
  // 3. DARK MODE PALETTE (SLATE LUXURY LUX - ANTI SILAU)
  // =========================================================================
  static const Color darkBg = Color(0xFF0F172A);       // Slate 900 - Latar Belakang Aplikasi Malam
  static const Color darkCard = Color(0xFF1E293B);     // Slate 800 - Latar Belakang Kartu Malam
  static const Color darkField = Color(0xFF1E293B);    // Slate 800 - Latar Belakang Text Input Malam

  // =========================================================================
  // 4. TYPOGRAPHY NEUTRALS (SLATE THEME TEXT)
  // =========================================================================
  static const Color textMain = Color(0xFF0F172A);     // Slate 900 - Teks Utama (Mengganti hitam pekat)
  static const Color textSub = Color(0xFF64748B);      // Slate 500 - Teks Keterangan / Subtitle / Hint
  static const Color textDarkMain = Colors.white;      // Putih - Teks Utama saat Dark Mode
  static const Color textDarkSub = Color(0xFF94A3B8);  // Slate 400 - Teks Keterangan saat Dark Mode

  // =========================================================================
  // 5. TRANSACTION STATUS (VIBRANT SYSTEM SIGNALS)
  // =========================================================================
  static const Color success = Color(0xFF10B981);      // Emerald Green - Transaksi Sukses / Saldo Masuk
  static const Color danger = Color(0xFFEF4444);       // Rose Scarlet - Transaksi Gagal / Peringatan
  static const Color warning = Color(0xFFF59E0B);      // Vibrant Amber - Menunggu Pembayaran / Progres

  // =========================================================================
  // 6. EXTRA ACCENTS & ELEVATION
  // =========================================================================
  static const Color shadow = Color(0xFF64748B);       // Slate 500 - Base shadow warna untuk opasitas dinamis
  static const Color shadowSoft = Color(0x0A0F172A);   // Bayangan ultra-soft bawaan untuk kartu melayang
}
