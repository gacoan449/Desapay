import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../services/belanjaku/cart_service.dart';
import '../../services/pin_service.dart';
import 'delivery_area_screen.dart';

class BelanjakuCheckoutScreen extends StatefulWidget {
  const BelanjakuCheckoutScreen({super.key});
  @override State<BelanjakuCheckoutScreen> createState() => _BelanjakuCheckoutScreenState();
}
class _BelanjakuCheckoutScreenState extends State<BelanjakuCheckoutScreen> {
  final cart = BelanjakuCartService.instance;
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  Map<String, String>? area;
  String payment = 'COD';
  bool submitting = false;
  String? _requestId;

  String _newRequestId() {
    final random = Random.secure();
    return List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
  }
  String rp(int n) => 'Rp ' + n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => m[1]! + '.');
  @override void dispose() { addressController.dispose(); phoneController.dispose(); super.dispose(); }

  Future<void> submitOrder() async {
    if (area == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih wilayah pengiriman.'))); return; }
    if (addressController.text.trim().length < 8 || phoneController.text.trim().length < 8) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi alamat lengkap dan nomor HP yang valid.'))); return; }
    if (cart.items.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keranjang kosong.'))); return; }
    setState(() => submitting = true);
    try {
      // Reuse this key when retrying after a timeout to prevent duplicate orders/charges.
      _requestId ??= _newRequestId();
      final items = cart.items.map((item) => <String, dynamic>{'productId': item.product.id, 'quantity': item.quantity}).toList();
      final areaId = area!['id']!;
      final address = addressController.text.trim();
      final phone = phoneController.text.trim();
      String? pinAuthorizationId;
      if (payment == 'BALANCE') {
        final pin = await _askPaymentPin();
        if (pin == null) return;
        final fingerprint = sha256.convert(utf8.encode(jsonEncode(<String, dynamic>{
          'paymentMethod': payment, 'areaId': areaId, 'address': address, 'phone': phone, 'items': items,
        }))).toString();
        pinAuthorizationId = await PinService().authorizeBelanjaku(
          pin: pin, requestId: _requestId!, fingerprint: fingerprint,
        );
      }
      final callable = FirebaseFunctions.instanceFor(region: 'asia-southeast2').httpsCallable('belanjakuCreateOrder');
      final result = await callable.call(<String, dynamic>{
        'requestId': _requestId,
        'paymentMethod': payment,
        'areaId': areaId,
        'address': address,
        'phone': phone,
        'items': items,
        if (pinAuthorizationId != null) 'pinAuthorizationId': pinAuthorizationId,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      cart.clear();
      _requestId = null;
      if (!mounted) return;
      await showDialog<void>(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
        title: const Text('Pesanan berhasil dibuat'),
        content: Text('Nomor pesanan: ${data['orderId']}\nTotal: ${rp((data['total'] as num).toInt())}\nPembayaran: ${payment == 'COD' ? 'COD — belum dibayar' : 'Saldo DesaPay — lunas'}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Selesai'))],
      ));
      if (mounted) Navigator.pop(context, true);
    } on FirebaseFunctionsException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Pesanan gagal diproses.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan gagal diproses. Coba lagi.')));
    } finally { if (mounted) setState(() => submitting = false); }
  }

  Future<String?> _askPaymentPin() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(context: context, barrierDismissible: false, builder: (dialogContext) => AlertDialog(
        title: const Text('PIN Pembayaran'),
        content: TextField(controller: controller, autofocus: true, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'Masukkan PIN 6 digit', counterText: '')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Lanjutkan')),
        ],
      ));
    } finally { controller.dispose(); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout'), flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0756D8), Color(0xFF0798EA)])))),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Wilayah Pengiriman', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Card(child: ListTile(leading: const Icon(Icons.location_on_outlined, color: Color(0xFF0866D9)), title: Text(area?['name'] ?? 'Pilih wilayah pengiriman'), subtitle: Text(area?['subdistrict'] ?? 'Pilih desa/kelurahan secara manual'), trailing: const Icon(Icons.chevron_right), onTap: () async { final selected = await Navigator.push<Map<String, String>>(context, MaterialPageRoute(builder: (_) => const BelanjakuDeliveryAreaScreen())); if (selected != null && mounted) setState(() => area = selected); })),
      const SizedBox(height: 12),
      TextField(controller: addressController, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Alamat lengkap', hintText: 'Nama jalan, nomor rumah, RT/RW, patokan')),
      const SizedBox(height: 12),
      TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Nomor HP penerima')),
      const SizedBox(height: 20),
      const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w800)),
      RadioListTile<String>(value: 'COD', groupValue: payment, onChanged: (v) => setState(() => payment = v!), title: const Text('Bayar saat barang diterima (COD)'), contentPadding: EdgeInsets.zero),
      RadioListTile<String>(value: 'BALANCE', groupValue: payment, onChanged: (v) => setState(() => payment = v!), title: const Text('Saldo DesaPay'), subtitle: const Text('Saldo dipotong di server hanya jika pesanan berhasil dibuat.'), contentPadding: EdgeInsets.zero),
      const SizedBox(height: 16),
      const Text('Ringkasan Belanja', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      ...cart.items.map((i) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text('${i.product.name} × ${i.quantity}')), Text(rp(i.lineTotal))]))),
      const Divider(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal perkiraan'), Text(rp(cart.total), style: const TextStyle(fontWeight: FontWeight.w800))]),
      const SizedBox(height: 8),
      const Text('Ongkir mengikuti pengaturan admin. Harga dan stok akhir selalu diperiksa ulang di server.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: submitting ? null : submitOrder, icon: submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_outline), label: Text(submitting ? 'Memproses pesanan...' : 'Buat Pesanan'))),
    ]),
  );
}
