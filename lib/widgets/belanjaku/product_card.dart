import 'package:flutter/material.dart';

import '../../models/belanjaku/product_model.dart';
import 'availability_badge.dart';

class BelanjakuProductCard extends StatelessWidget {
  const BelanjakuProductCard({super.key, required this.product, required this.onTap, this.onAdd});
  final BelanjakuProduct product;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  String _rupiah(int n) => 'Rp ' + n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => m[1]! + '.',
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EEF5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1.15,
              child: product.imageUrl.isEmpty
                  ? Container(color: const Color(0xFFF0F5FA), child: const Icon(Icons.image_outlined, color: Color(0xFF8BA0B8), size: 34))
                  : Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF0F5FA), child: const Icon(Icons.image_not_supported_outlined))),
            ),
          ),
          const SizedBox(height: 9),
          Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(_rupiah(product.price) + ' / ' + product.unit, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF0866D9), fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 7),
          BelanjakuAvailabilityBadge(status: product.stock <= 0 && product.status == 'available' ? 'out_of_stock' : product.status),
          if (product.isAvailable && onAdd != null)
            Align(alignment: Alignment.centerRight, child: IconButton(onPressed: onAdd, visualDensity: VisualDensity.compact, icon: const Icon(Icons.add_circle, color: Color(0xFF0866D9)))),
        ]),
      ),
    );
  }
}
