import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/warna.dart';

class PindaiQrisScreen extends StatefulWidget {
  const PindaiQrisScreen({super.key});

  @override
  State<PindaiQrisScreen> createState() => _PindaiQrisScreenState();
}

class _PindaiQrisScreenState extends State<PindaiQrisScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _isFlashOn = false; 
  bool _hasCameraPermission = true; // Tambahan untuk memantau izin

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _handleQrDetected(String code) {
    if (_isProcessing) return; 
    setState(() => _isProcessing = true);
    
    // Hentikan kamera saat dialog muncul demi performa dan baterai
    _cameraController.stop();

    final bool isValidQris = code.startsWith("000201") || code.toUpperCase().contains("NMID");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              isValidQris ? Icons.check_circle_rounded : Icons.error_rounded,
              color: isValidQris ? WarnaDesaPay.success : WarnaDesaPay.danger,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(isValidQris ? "QRIS Valid" : "QR Tidak Valid", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text(
          isValidQris ? "Lanjutkan pembayaran menggunakan QRIS ini?\n\nKode: $code" : "Kode yang dipindai bukan QRIS.\n\nKode: $code",
          style: const TextStyle(color: WarnaDesaPay.textMain, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () { 
              Navigator.pop(context); 
              setState(() => _isProcessing = false);
              // Jalankan kamera kembali untuk memindai ulang
              _cameraController.start();
            }, 
            child: const Text("Pindai Lagi", style: TextStyle(color: WarnaDesaPay.textSub, fontWeight: FontWeight.bold)),
          ),
          if (isValidQris) 
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: WarnaDesaPay.primary),
              onPressed: () { 
                Navigator.pop(context); 
                Navigator.pop(context, code);
              }, 
              child: const Text("Proses", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }

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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada QR Code di gambar"), backgroundColor: WarnaDesaPay.danger));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
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
            // KOREKSI UTAMA: Menangani error/izin ditolak agar tidak crash/muncul teks bawaan
            errorBuilder: (context, error, child) {
              return const Center(
                child: Text(
                  "Gagal membuka kamera.\nPastikan izin kamera diberikan.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              );
            },
          ),
          // Kotak Scanner (Hanya muncul jika kamera aktif/diizinkan)
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: WarnaDesaPay.secondary, width: 2.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.65), spreadRadius: 9999)],
              ),
            ),
          ),
          // Header Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircularButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
                const Text("Pindai QRIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                _buildCircularButton(
                  icon: _isFlashOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                  color: _isFlashOn ? WarnaDesaPay.warning : Colors.white,
                  onTap: () async {
                    try {
                      await _cameraController.toggleTorch();
                      setState(() => _isFlashOn = !_isFlashOn);
                    } catch (_) {
                      // Mencegah error jika flash ditekan saat kamera mati/izin ditolak
                    }
                  },
                ),
              ],
            ),
          ),
          // Tombol Galeri
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 24, right: 24,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100), side: BorderSide(color: Colors.white.withOpacity(0.2))),
                ),
                onPressed: _scanDariGaleri,
                icon: const Icon(Icons.image_rounded, size: 20),
                label: const Text("Ambil dari Galeri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
