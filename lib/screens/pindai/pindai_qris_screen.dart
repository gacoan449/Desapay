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
  // DIKOREKSI: Mengunci inisialisasi agar engine kamera native tidak memicu unexpected error
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    returnImage: false,
  );

  late AnimationController _animationController;
  late Animation<double> _laserPosition;
  bool _isFlashOn = false;
  bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
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
          TextButton(onPressed: () { Navigator.pop(context); _cameraController.start(); }, child: const Text("Pindai Lagi")),
          if (isValidQris) ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("Proses"))
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
            onDetectError: (error, stack) {
              setState(() { _hasPermission = false; });
            },
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          if (!_hasPermission)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.no_photography_rounded, color: Colors.white54, size: 72),
                  const SizedBox(height: 20),
                  const Text("Gagal Memuat Kamera", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () { _cameraController.start(); setState(() { _hasPermission = true; }); }, child: const Text("Coba Lagi"))
                ],
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
                const Text("Pindai QRIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () { _cameraController.toggleTorch(); setState(() { _isFlashOn = !_isFlashOn; }); },
                  icon: Icon(Icons.flash_on_rounded, color: _isFlashOn ? Colors.yellow : Colors.white),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
