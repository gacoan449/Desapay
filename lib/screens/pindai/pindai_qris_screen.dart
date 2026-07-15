import 'package:flutter/material.dart';
import '../../config/warna.dart';

class PindaiQrisScreen extends StatefulWidget {
  const PindaiQrisScreen({super.key});

  @override
  State<PindaiQrisScreen> createState() => _PindaiQrisScreenState();
}

class _PindaiQrisScreenState extends State<PindaiQrisScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _laserPosition;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    // Animasi putaran laser scanner naik-turun secara kontinu
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _laserPosition = Tween<double>(begin: 0.0, end: 240.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _animationController.forward();
        }
      });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Tampilan Bottom Sheet untuk memamerkan QR Code Toko Agen (Show QR)
  void _tampilkanQrSaya() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "QRIS Toko Saya",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: WarnaDesaPay.textMain,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Tunjukkan QR ini ke pelanggan untuk menerima pembayaran",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              // Frame QR Code Elegan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Simulasi QR Code Generator dengan Ikon Sentral DesaPay
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 220, color: WarnaDesaPay.textMain),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: WarnaDesaPay.primary,
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "DESAPAY * REJEKI MOTOR",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                    ),
                    const Text(
                      "NMID : ID1020261159002",
                      style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text("Unduh QR Code"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarnaDesaPay.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ==========================================
          // 1. SIMULASI BACKGROUND KAMERA (DARK LUXURY)
          // ==========================================
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.network(
                "https://images.unsplash.com/photo-1557804506-669a67965ba0?auto=format&fit=crop&w=800&q=80", // Tekstur latar belakang cyber-office
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Layer Gradient Gelap untuk memfokuskan pendaran scanner
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ==========================================
          // 2. HEADER BAR (CLOSE & TITLE)
          // ==========================================
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
                const Text(
                  "Pindai QRIS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isFlashOn = !_isFlashOn;
                    });
                  },
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _isFlashOn ? const Color(0xFFFFD700) : Colors.white,
                    size: 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 3. TARGET BOX & ANIMASI LASER SCANNER
          // ==========================================
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Kotak Target Scanner
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                    ),

                    // Sudut-sudut Penegas Frame Sempurna (Corner Brackets)
                    _buildCornerBracket(top: 0, left: 0, rotation: 0),
                    _buildCornerBracket(top: 0, right: 0, rotation: 1.57), // 90 deg
                    _buildCornerBracket(bottom: 0, left: 0, rotation: 4.71), // 270 deg
                    _buildCornerBracket(bottom: 0, right: 0, rotation: 3.14), // 180 deg

                    // Animasi Garis Laser Neon yang Bergerak Naik Turun
                    AnimatedBuilder(
                      animation: _laserPosition,
                      builder: (context, child) {
                        return Positioned(
                          top: _laserPosition.value,
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: WarnaDesaPay.secondary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: WarnaDesaPay.secondary.withOpacity(0.8),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  "Posisikan kode QR di dalam kotak target",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 4. FLOATING CONTROL BAR (BOTTOM CONTROLS)
          // ==========================================
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol Ambil dari Galeri Foto
                _buildCircularControl(
                  icon: Icons.image_rounded,
                  label: "Galeri",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Membuka galeri foto..."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                // Tombol Inti: Tampilkan QR Kode Toko Agen (Show QR)
                _buildCircularControl(
                  icon: Icons.qr_code_scanner_rounded,
                  label: "QR Toko",
                  onTap: _tampilkanQrSaya,
                  isPrimary: true,
                ),

                // Tombol Panduan Pembayaran
                _buildCircularControl(
                  icon: Icons.help_outline_rounded,
                  label: "Bantuan",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Buka panduan transaksi QRIS..."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Builder untuk sudut-sudut Target Box yang simetris
  Widget _buildCornerBracket({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double rotation,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: WarnaDesaPay.secondary, width: 4),
              left: BorderSide(color: WarnaDesaPay.secondary, width: 4),
            ),
          ),
        ),
      ),
    );
  }

  // Helper untuk membuat Tombol Kontrol Bawah yang Simetris
  Widget _buildCircularControl({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isPrimary ? 68 : 54,
            height: isPrimary ? 68 : 54,
            decoration: BoxDecoration(
              color: isPrimary ? WarnaDesaPay.primary : Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: isPrimary ? Colors.white30 : Colors.white12,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: Colors.white,
              size: isPrimary ? 30 : 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
