import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/warna.dart';

class PindaiQrisScreen extends StatefulWidget {
  const PindaiQrisScreen({super.key});

  @override
  State<PindaiQrisScreen> createState() => _PindaiQrisScreenState();
}

class _PindaiQrisScreenState extends State<PindaiQrisScreen> with WidgetsBindingObserver {
  
  // PERBAIKAN: Menambahkan autoStart untuk memastikan mesin menyala saat diinisialisasi
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _isProcessing = false;
  bool _isFlashOn = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // PERBAIKAN: Paksa kamera menyala secara asinkron saat layar pertama kali dirender
    _mulaiKamera();
  }
  
  Future<void> _mulaiKamera() async {
    try {
      await _cameraController.start();
    } catch (e) {
      debugPrint("Kamera gagal diakses: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraController.value.isInitialized) return;
    
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _cameraController.stop(); // Hemat baterai saat aplikasi di latar belakang
        break;
      case AppLifecycleState.resumed:
        _cameraController.start();
        if (mounted) setState(() => _isFlashOn = false); 
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _handleQrDetected(String code) {
    if (_isProcessing) return; 
    
    setState(() => _isProcessing = true);
    _cameraController.stop(); 

    final bool isValidQris = code.startsWith("000201") || code.toUpperCase().contains("NMID");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              isValidQris ? Icons.check_circle_rounded : Icons.error_rounded,
              color: isValidQris ? WarnaDesaPay.success : WarnaDesaPay.danger,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              isValidQris ? "QRIS Valid" : "QR Tidak Valid",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isValidQris 
              ? "Lanjutkan pembayaran menggunakan QRIS ini?\n\nKode: $code" 
              : "Kode yang dipindai bukan QRIS berstandar Nasional.\n\nKode: $code",
          style: const TextStyle(color: WarnaDesaPay.textMain, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () { 
              Navigator.pop(context); 
              setState(() => _isProcessing = false);
              _cameraController.start(); 
            }, 
            child: const Text("Pindai Lagi", style: TextStyle(color: WarnaDesaPay.textSub, fontWeight: FontWeight.bold)),
          ),
          if (isValidQris) 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: WarnaDesaPay.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () { 
                Navigator.pop(context); 
                Navigator.pop(context, code); // Kembalikan kode QR ke layar sebelumnya (menghindari double navigasi)
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tidak ditemukan kode QR pada gambar tersebut."),
              backgroundColor: WarnaDesaPay.danger,
              behavior: SnackBarBehavior.floating,
            )
          );
        }
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      await _cameraController.toggleTorch();
      if (mounted) {
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      }
    } catch (e) {
      debugPrint("Senter tidak didukung: $e");
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
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.no_photography_rounded, color: Colors.white54, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "Kamera terblokir sistem.\nPastikan izin diberikan dan restart aplikasi.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: WarnaDesaPay.primary),
                      onPressed: _mulaiKamera,
                      child: const Text("Coba Ulang", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              );
            },
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQrDetected(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: WarnaDesaPay.secondary, width: 2.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.65), spreadRadius: 9999),
                ],
              ),
              child: Center(
                child: Container(
                  width: 2, height: 2,
                  decoration: const BoxDecoration(color: WarnaDesaPay.secondary, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
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
                  onTap: _toggleFlash,
                ),
              ],
            ),
          ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100), 
                    side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
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
