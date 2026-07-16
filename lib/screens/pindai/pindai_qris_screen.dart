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
  late MobileScannerController _cameraController;
  late AnimationController _animationController;
  late Animation<double> _laserPosition;
  bool _isFlashOn = false;
  bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      autoStart: true,
    );

    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _laserPosition = Tween<double>(begin: 0.0, end: 240.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _animationController.reverse();
        if (status == AnimationStatus.dismissed) _animationController.forward();
      });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _handleQrDetected(String code) {
    _cameraController.stop();
    final bool isValidQris = code.startsWith("000201") || code.toUpperCase().contains("NMID");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isValidQris ? "QRIS Valid" : "QR Tidak Valid"),
        content: Text(isValidQris ? "Lanjutkan Pembayaran?\n\n$code" : "Bukan QRIS standar Nasional.\n\n$code"),
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
              style: ElevatedButton.styleFrom(backgroundColor: WarnaDesaPay.primary),
              onPressed: () { 
                Navigator.pop(context); 
                Navigator.pop(context); 
              }, 
              child: const Text("Proses", style: TextStyle(color: Colors.white)),
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
        if (qrCode != null && mounted) _handleQrDetected(qrCode);
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
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _handleQrDetected(barcode.rawValue!);
                  break;
                }
              }
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        "Gagal Mengakses Kamera: ${error.errorCode}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Pastikan izin kamera telah diberikan di pengaturan perangkat Anda.",
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Container(color: Colors.black.withOpacity(0.2)),
          
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white24, width: 2),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // DIKOREKSI: Memperbaiki implementasi warna latar belakang menggunakan styleFrom yang valid
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                  onPressed: () => Navigator.pop(context), 
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                const Text("Pindai QRIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                // DIKOREKSI: Memperbaiki penulisan parameter background sesuai SDK Flutter terbaru
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                  onPressed: () { 
                    _cameraController.toggleTorch(); 
                    setState(() { _isFlashOn = !_isFlashOn; }); 
                  },
                  icon: Icon(Icons.flash_on_rounded, color: _isFlashOn ? Colors.yellow : Colors.white),
                )
              ],
            ),
          ),
          
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 24, right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _scanDariGaleri,
                  icon: const Icon(Icons.image_rounded),
                  label: const Text("Ambil dari Galeri"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
