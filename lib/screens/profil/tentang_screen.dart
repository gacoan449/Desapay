import 'package:flutter/material.dart';
import '../../config/warna.dart';

class TentangScreen extends StatelessWidget {
  const TentangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tentang & Ketentuan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: WarnaDesaPay.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_wallet_rounded, size: 48, color: WarnaDesaPay.primary),
                  ),
                  const SizedBox(height: 12),
                  const Text("DesaPay v1.0.0", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: WarnaDesaPay.textMain)),
                  const Text("Platform PPOB & Pembayaran Digital", style: TextStyle(color: WarnaDesaPay.textSub, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSection("Pasal 1: Definisi Layanan", 
                "DesaPay merupakan platform keagenan (PPOB) yang terintegrasi dengan aggregator bilyer nasional (Digiflazz & TriPay). Aplikasi ini melayani pembelian produk prabayar, pembayaran tagihan pascabayar, dan pergerakan saldo elektronik."),
            _buildSection("Pasal 2: Keamanan Akun & Saldo", 
                "Pengguna wajib menjaga kerahasiaan PIN dan OTP. Segala kerugian yang diakibatkan oleh kelalaian pengguna dalam menjaga kredensial tidak menjadi tanggung jawab pihak pengembang DesaPay."),
            _buildSection("Pasal 3: Service Level Agreement (SLA)", 
                "Proses top-up saldo dan transaksi produk digital akan diproses secara real-time (maksimal 3x24 jam kerja jika terjadi gangguan pada server pusat bilyer). Pengembalian dana (refund) atas transaksi yang dinyatakan GAGAL oleh sistem akan dikembalikan langsung ke saldo akun secara otomatis."),
            _buildSection("Pasal 4: Pemblokiran Sepihak", 
                "Sistem keamanan DesaPay memiliki hak penuh untuk melakukan blokir akun secara instan jika terdeteksi adanya indikasi fraud, manipulasi API, atau spam request yang membahayakan server."),
            const SizedBox(height: 40),
            const Center(child: Text("© 2026 DesaPay Network. All Rights Reserved.", style: TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: WarnaDesaPay.textMain)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: WarnaDesaPay.textSub, fontSize: 13, height: 1.5), textAlign: TextAlign.justify),
        ],
      ),
    );
  }
}
