// lib/screens/saldo/topup_saldo_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../config/warna.dart';
import '../../services/tripay_service.dart';
import '../../widgets/menu_item.dart';
import '../pembayaran/metode_pembayaran_screen.dart';
import 'invoice_screen.dart';

class TopupSaldoScreen extends StatefulWidget {
  const TopupSaldoScreen({super.key});

  @override
  State<TopupSaldoScreen> createState() => _TopupSaldoScreenState();
}

class _TopupSaldoScreenState extends State<TopupSaldoScreen> {
  final TextEditingController _nominalController =
      TextEditingController();

  final FocusNode _nominalFocus = FocusNode();

  final TriPayService _triPayService = TriPayService();

  bool _isLoading = false;
  int _currentNominal = 0;

  final List<int> _pilihanNominal = [
    20000,
    50000,
    100000,
    200000,
    500000,
    1000000,
  ];

  @override
  void initState() {
    super.initState();

    _nominalController.addListener(_sinkronkanNominal);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_nominalFocus);
      }
    });
  }

  void _sinkronkanNominal() {
    final raw = _nominalController.text.replaceAll('.', '');
    final value = int.tryParse(raw) ?? 0;

    if (_currentNominal != value && mounted) {
      setState(() {
        _currentNominal = value;
      });
    }
  }

  @override
  void dispose() {
    _nominalController.removeListener(_sinkronkanNominal);
    _nominalController.dispose();
    _nominalFocus.dispose();
    super.dispose();
  }

  void _pilihNominalCepat(int nominal) {
    final formatted = _formatAngka(nominal);

    _nominalController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );

    _nominalFocus.unfocus();
  }

  Future<void> _lanjutkanKePembayaran() async {
    if (_isLoading) return;

    if (_currentNominal < 10000) {
      _tampilkanNotifikasi(
        'Minimal pengisian saldo adalah Rp 10.000.',
        isError: true,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _tampilkanNotifikasi(
        'Sesi login telah berakhir. Silakan login kembali.',
        isError: true,
      );
      return;
    }

    _nominalFocus.unfocus();

    final String? channelCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => MetodePembayaranScreen(
          nominal: _currentNominal.toString(),
        ),
      ),
    );

    if (!mounted || channelCode == null || channelCode.trim().isEmpty) {
      return;
    }

    await _buatTagihan(
      uid: user.uid,
      nominal: _currentNominal,
      method: channelCode,
    );
  }

  Future<void> _buatTagihan({
    required String uid,
    required int nominal,
    required String method,
  }) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await _triPayService.buatTagihanClosedPayment(
        uid: uid,
        method: method,
        amount: nominal,
      );

      if (!mounted) return;

      if (result.isSukses) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceScreen(
              tripayData: result,
            ),
          ),
        );
      } else {
        _tampilkanNotifikasi(
          result.pesan,
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatAngka(int angka) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(angka);
  }

  void _tampilkanNotifikasi(
    String pesan, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pesan,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor:
            isError ? WarnaDesaPay.danger : WarnaDesaPay.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool nominalValid = _currentNominal >= 10000;

    return Scaffold(
      backgroundColor: WarnaDesaPay.lightBg,
      appBar: AppBar(
        backgroundColor: WarnaDesaPay.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Isi Saldo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: _isLoading
              ? null
              : () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              24,
              20,
              120,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: WarnaDesaPay.shadow
                            .withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mau isi saldo berapa?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: WarnaDesaPay.textSub,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Rp',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: WarnaDesaPay.textMain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller:
                                  _nominalController,
                              focusNode: _nominalFocus,
                              enabled: !_isLoading,
                              keyboardType:
                                  TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly,
                                _CurrencyInputFormatter(),
                              ],
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color:
                                    WarnaDesaPay.textMain,
                                letterSpacing: 1,
                              ),
                              decoration:
                                  const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                ),
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 32,
                        thickness: 1.5,
                        color:
                            WarnaDesaPay.lightField,
                      ),
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Minimal pengisian Rp 10.000',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Pilihan Cepat',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: WarnaDesaPay.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: _pilihanNominal.length,
                  itemBuilder: (context, index) {
                    final nominal =
                        _pilihanNominal[index];

                    final selected =
                        _currentNominal == nominal;

                    return CustomBounce(
                      onTap: _isLoading
                          ? () {}
                          : () => _pilihNominalCepat(
                                nominal,
                              ),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 200),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? WarnaDesaPay.primary
                                  .withOpacity(0.1)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? WarnaDesaPay.primary
                                : WarnaDesaPay.lightField,
                            width:
                                selected ? 2 : 1.5,
                          ),
                        ),
                        child: Text(
                          'Rp ${_formatAngka(nominal)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: selected
                                ? WarnaDesaPay.primary
                                : WarnaDesaPay.textMain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                24,
                16,
                24,
                32,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: WarnaDesaPay.shadow
                        .withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: CustomBounce(
                onTap: nominalValid && !_isLoading
                    ? _lanjutkanKePembayaran
                    : () {},
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: nominalValid
                        ? WarnaDesaPay.primary
                        : Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'PILIH METODE PEMBAYARAN',
                          style: TextStyle(
                            color: nominalValid
                                ? Colors.white
                                : Colors.grey.shade500,
                            fontWeight:
                                FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyInputFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(
          offset: 0,
        ),
      );
    }

    final clean =
        newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (clean.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(
          offset: 0,
        ),
      );
    }

    final value = int.tryParse(clean);

    if (value == null) {
      return oldValue;
    }

    final formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}
