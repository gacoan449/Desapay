import 'package:flutter/material.dart';
import '../../config/warna.dart';
import '../../services/pin_service.dart';

class UbahPinScreen extends StatefulWidget {
  const UbahPinScreen({super.key});

  @override
  State<UbahPinScreen> createState() => _UbahPinScreenState();
}

class _UbahPinScreenState extends State<UbahPinScreen> {
  final PinService _pinService = PinService();

  final TextEditingController _pinLamaController =
      TextEditingController();

  final TextEditingController _pinBaruController =
      TextEditingController();

  final TextEditingController _konfirmasiController =
      TextEditingController();

  bool _loading = true;
  bool _hasPin = false;

  bool _obscureLama = true;
  bool _obscureBaru = true;
  bool _obscureKonfirmasi = true;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  @override
  void dispose() {
    _pinLamaController.dispose();
    _pinBaruController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  // ============================================================
  // CEK PIN USER
  // ============================================================
  Future<void> _checkPin() async {
    final result = await _pinService.hasPin();

    if (!mounted) return;

    setState(() {
      _hasPin = result;
      _loading = false;
    });
  }

  // ============================================================
  // SIMPAN / UBAH PIN
  // ============================================================
  Future<void> _simpanPin() async {
    final pinLama = _pinLamaController.text.trim();
    final pinBaru = _pinBaruController.text.trim();
    final konfirmasi = _konfirmasiController.text.trim();

    if (!_hasPin) {
      if (pinBaru.isEmpty || konfirmasi.isEmpty) {
        _showMessage(
          "PIN baru dan konfirmasi PIN wajib diisi.",
        );
        return;
      }

      setState(() {
        _loading = true;
      });

      final result = await _pinService.createPin(
        pin: pinBaru,
        confirmation: konfirmasi,
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      if (result != null) {
        _showMessage(result);
        return;
      }

      _showSuccess(
        "PIN transaksi berhasil dibuat.",
      );

      Navigator.pop(context);
      return;
    }

    // ==========================================================
    // UBAH PIN
    // ==========================================================
    if (pinLama.isEmpty ||
        pinBaru.isEmpty ||
        konfirmasi.isEmpty) {
      _showMessage(
        "Semua kolom PIN wajib diisi.",
      );
      return;
    }

    if (pinBaru.length != 6) {
      _showMessage(
        "PIN baru harus terdiri dari 6 digit.",
      );
      return;
    }

    if (pinBaru != konfirmasi) {
      _showMessage(
        "Konfirmasi PIN baru tidak cocok.",
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    final result = await _pinService.changePin(
      oldPin: pinLama,
      newPin: pinBaru,
      confirmation: konfirmasi,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (result != null) {
      _showMessage(result);
      return;
    }

    _showSuccess(
      "PIN transaksi berhasil diubah.",
    );

    Navigator.pop(context);
  }

  // ============================================================
  // PESAN ERROR
  // ============================================================
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // PESAN BERHASIL
  // ============================================================
  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // INPUT PIN
  // ============================================================
  Widget _pinField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      enabled: !_loading,
      obscureText: obscureText,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textInputAction: TextInputAction.next,

      decoration: InputDecoration(
        labelText: label,

        counterText: "",

        prefixIcon: const Icon(
          Icons.pin_rounded,
        ),

        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
          ),
        ),

        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: WarnaDesaPay.lightField,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: WarnaDesaPay.lightField,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: WarnaDesaPay.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,

      appBar: AppBar(
        title: const Text(
          "Ubah PIN Transaksi",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
      ),

      body: _loading && !_hasPin
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ==================================================
                // INFORMASI KEAMANAN
                // ==================================================
                Container(
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: WarnaDesaPay.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Icon(
                        Icons.security_rounded,
                        color: WarnaDesaPay.primary,
                        size: 26,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          _hasPin
                              ? "PIN transaksi digunakan untuk mengamankan transaksi PPOB Anda. Jangan berikan PIN kepada siapa pun."
                              : "Buat PIN transaksi 6 digit untuk mengamankan transaksi PPOB Anda.",
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: WarnaDesaPay.textSub,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // PIN LAMA
                // ==================================================
                if (_hasPin) ...[
                  _pinField(
                    controller: _pinLamaController,
                    label: "PIN Transaksi Lama",
                    obscureText: _obscureLama,
                    onToggle: () {
                      setState(() {
                        _obscureLama =
                            !_obscureLama;
                      });
                    },
                  ),

                  const SizedBox(height: 16),
                ],

                // ==================================================
                // PIN BARU
                // ==================================================
                _pinField(
                  controller: _pinBaruController,
                  label: "PIN Transaksi Baru",
                  obscureText: _obscureBaru,
                  onToggle: () {
                    setState(() {
                      _obscureBaru =
                          !_obscureBaru;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // KONFIRMASI PIN
                // ==================================================
                _pinField(
                  controller: _konfirmasiController,
                  label: "Konfirmasi PIN Baru",
                  obscureText: _obscureKonfirmasi,
                  onToggle: () {
                    setState(() {
                      _obscureKonfirmasi =
                          !_obscureKonfirmasi;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // ==================================================
                // TOMBOL SIMPAN
                // ==================================================
                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: ElevatedButton(
                    onPressed:
                        _loading ? null : _simpanPin,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          WarnaDesaPay.primary,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),

                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _hasPin
                                ? "UBAH PIN TRANSAKSI"
                                : "BUAT PIN TRANSAKSI",
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.4,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // CATATAN
                // ==================================================
                Container(
                  padding:
                      const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          WarnaDesaPay.lightField,
                    ),
                  ),

                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: Colors.grey,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          "PIN harus 6 digit angka. Hindari menggunakan kombinasi yang mudah ditebak.",
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color:
                                WarnaDesaPay.textSub,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
