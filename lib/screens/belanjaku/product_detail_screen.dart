import 'package:flutter/material.dart';
import '../../models/belanjaku/product_model.dart';
import '../../services/belanjaku/cart_service.dart';
import '../../services/belanjaku/interest_tracking_service.dart';
import '../../widgets/belanjaku/availability_badge.dart';
import '../../widgets/belanjaku/interest_button.dart';
import 'delivery_area_screen.dart';

class BelanjakuProductDetailScreen extends StatefulWidget {
  const BelanjakuProductDetailScreen({super.key, required this.product, required this.onCartChanged});
  final BelanjakuProduct product;
  final VoidCallback onCartChanged;
  @override State<BelanjakuProductDetailScreen> createState() => _BelanjakuProductDetailScreenState();
}

class _BelanjakuProductDetailScreenState extends State<BelanjakuProductDetailScreen> {
  int quantity = 1;
  bool savingInterest = false;
  String rupiah(int n) => 'Rp ' + n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => m[1]! + '.');
  Future<void> expressInterest() async {
    final area = await Navigator.push<Map<String, String>>(context, MaterialPageRoute(builder: (_) => const BelanjakuDeliveryAreaScreen()));
    if (!mounted || area == null) return;
    setState(() => savingInterest = true);
    try {
      await BelanjakuInterestService().expressInterest(productId: widget.product.id, productName: widget.product.name, areaId: area['id'] ?? '', areaName: area['name'] ?? '');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minat tersimpan. Terima kasih!')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Minat belum tersimpan: $error')));
    } finally { if (mounted) setState(() => savingInterest = false); }
  }
  @override Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(appBar: AppBar(title: const Text('Detail Produk')), body: ListView(children: [
      AspectRatio(aspectRatio: 1.2, child: p.imageUrl.isEmpty ? Container(color: const Color(0xFFF0F5FA), child: const Icon(Icons.image_outlined, size: 70)) : Image.network(p.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, size: 64))),
      Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
        Text(rupiah(p.price) + ' / ' + p.unit, style: const TextStyle(color: Color(0xFF0866D9), fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
        BelanjakuAvailabilityBadge(status: p.stock <= 0 && p.status == 'available' ? 'out_of_stock' : p.status), const SizedBox(height: 18),
        Text(p.description.isEmpty ? 'Informasi produk akan diperbarui oleh admin.' : p.description, style: const TextStyle(height: 1.5, color: Color(0xFF52647A))), const SizedBox(height: 22),
        if (p.isAvailable) ...[
          Row(children: [IconButton(onPressed: quantity > 1 ? () => setState(() => quantity--) : null, icon: const Icon(Icons.remove_circle_outline)), Text(quantity.toString()), IconButton(onPressed: quantity < p.stock ? () => setState(() => quantity++) : null, icon: const Icon(Icons.add_circle_outline)), Text(' ' + p.unit)]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { for (var i = 0; i < quantity; i++) { BelanjakuCartService.instance.add(p); } widget.onCartChanged(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk ditambahkan ke keranjang.'))); }, icon: const Icon(Icons.shopping_cart_outlined), label: const Text('Tambah ke Keranjang'))),
        ] else if (p.isComingSoon) ...[
          const Text('Produk ini belum tersedia. Pilih wilayah agar minatmu bisa dihitung oleh admin.', style: TextStyle(color: Color(0xFF64748B), height: 1.4)), const SizedBox(height: 12),
          BelanjakuInterestButton(busy: savingInterest, onPressed: savingInterest ? null : expressInterest),
        ] else const Text('Produk sedang tidak tersedia.', style: TextStyle(color: Color(0xFF64748B))),
      ])),
    ]));
  }
}