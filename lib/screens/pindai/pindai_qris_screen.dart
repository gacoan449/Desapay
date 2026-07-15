import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/warna.dart';

class PindaiQrisScreen extends StatefulWidget {
  const PindaiQrisScreen({super.key});

  @override
  State<PindaiQrisScreen> createState() => _PindaiQrisScreenState();
}

class _PindaiQrisScreenState extends State<PindaiQrisScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  late AnimationController _animationController;
  late Animation<double> _laserPosition;
  bool _isFlashOn = false;
  bool _hasPermission = true; // Status izin kamera rill

  @override
  void initState() {
    super.initState();

    // Animasi laser scanner
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _laserPosition = Tween<double>(begin: 0.0, end: 240.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
    _cameraController.dispose();
    super.dispose();
  }

  // ===================================================
  // FUNGSI UTAMA 1: PROSES HASIL SCANNING QRIS
  // ===================================================
  void _handleQrDetected(String code) {
    _cameraController.stop();

    // Filter validasi sederhana format QRIS (NMID / info merchant)
    final bool isValidQris = code.toUpperCase().contains("NMID") || code.startsWith("000201");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isValidQris ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              color: isValidQris ? Colors.green : WarnaDesaPay.warning,
            ),
            const SizedBox(width: 8),
            Text(isValidQris ? "QRIS Terdeteksi" : "Format Tidak Valid"),
          ],
        ),
        content: Text(
          isValidQris 
              ? "Merchant berhasil terbaca. Lanjutkan pembayaran?\n\nIsi QR:\n$code" 
              : "Barcode yang Anda scan bukan format QRIS standar Nasional (NMID).\n\nIsi QR:\n$code"
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cameraController.start();
            },
            child: const Text("Pindai Lagi"),
          ),
          if (isValidQris)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: WarnaDesaPay.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Kembali ke Beranda membawa data QRIS
                // Kirim hasil scan kembali ke beranda atau pemrosesan transaksi
              },
              child: const Text("Proses Bayar"),
            )
        ],
      ),
    );
  }

  // ===================================================
  // FUNGSI UTAMA 2: AMBIL & DECODE QR DARI GALERI HP
  // ===================================================
  Future<void> _scanDariGaleri() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final BarcodeCapture? capture = await _cameraController.analyzeImage(image.path);
      
      if (capture != null && capture.barcodes.isNotEmpty) {
        final String? qrCode = capture.barcodes.first.rawValue;
        if (qrCode != null && mounted) {
          _handleQrDetected(qrCode);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gambar tidak mengandung kode QRIS yang valid."),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // Tampilkan QR Code Merchant Toko Sendiri (Show QR)
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WarnaDesaPay.textMain),
              ),
              const SizedBox(height: 4),
              const Text(
                "Tunjukkan QR ini ke pelanggan untuk menerima pembayaran",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 220, color: WarnaDesaPay.textMain),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: WarnaDesaPay.primary,
                            child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
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
          // 1. ENGINE KAMERA DENGAN DETEKSI PERMISSION
          // ==========================================
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQrDetected(barcode.rawValue!);
                  break;
                }
              }
            },
            // Penanganan error kamera otomatis (Misal: Izin ditolak pengguna)
            onDetectError: (error, stackTrace) {
              setState(() {
                _hasPermission = false;
              });
            },
          ),

          // Layer kegelapan fungsional
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          // Tampilan Fallback jika Izin Kamera Ditolak (Keren & Informatif)
          if (!_hasPermission)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.no_photography_rounded, color: Colors.white54, size: 72),
                    const SizedBox(height: 20),
                    const Text(
                      "Izin Kamera Dibutuhkan",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "DesaPay memerlukan izin akses kamera fisik Anda untuk memindai kode QRIS secara langsung.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WarnaDesaPay.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () async {
                        // Meminta izin ulang secara aman dengan memulai controller kembali
                        _cameraController.start();
                        setState(() {
                          _hasPermission = true;
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("Izinkan Kamera", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

          // ==========================================
          // 2. HEADER BAR (CLOSE & FLASH)
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
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
                const Text(
                  "Pindai QRIS",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                ),
                IconButton(
                  onPressed: _hasPermission ? () {
                    _cameraController.toggleTorch();
                    setState(() {
                      _isFlashOn = !_isFlashOn;
                    });
                  } : null,
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _isFlashOn ? const Color(0xFFFFD700) : Colors.white24,
                    size: 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 3. TARGET BOX & LASER (HANYA MUNCUL JIKA IZIN ADA)
          // ==========================================
          if (_hasPermission)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                      ),
                      _buildCornerBracket(top: 0, left: 0, rotation: 0),
                      _buildCornerBracket(top: 0, right: 0, rotation: 1.57),
                      _buildCornerBracket(bottom: 0, left: 0, rotation: 4.71),
                      _buildCornerBracket(bottom: 0, right: 0, rotation: 3.14),
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
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          // ==========================================
          // 4. CONTROLS BAR (BOTTOM CONTROLS)
          // ==========================================
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircularControl(
                  icon: Icons.image_rounded,
                  label: "Galeri",
                  onTap: _scanDariGaleri,
                ),
                _buildCircularControl(
                  icon: Icons.qr_code_scanner_rounded,
                  label: "QR Toko",
                  onTap: _tampilkanQrSaya,
                  isPrimary: true,
                ),
                _buildCircularControl(
                  icon: Icons.help_outline_rounded,
                  label: "Bantuan",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Arahkan kamera ke kertas barcode QRIS resmi."),
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
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: WarnaDesaPay.secondary, width: 4),
              left: BorderSide(color: WarnaDesaPay.secondary, width: 4),
            ),
          ),
        ),
      ),
    );
  }

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
            child: Icon(icon, color: Colors.white, size: isPrimary ? 30 : 22),
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
