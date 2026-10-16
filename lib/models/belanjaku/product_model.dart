import 'package:cloud_firestore/cloud_firestore.dart';

class BelanjakuProduct {
  const BelanjakuProduct({required this.id, required this.name, required this.category, required this.description, required this.imageUrl, required this.price, required this.unit, required this.stock, required this.status, this.isActive = true});
  final String id, name, category, description, imageUrl, unit, status;
  final int price, stock;
  final bool isActive;
  bool get isAvailable => isActive && status == 'available' && stock > 0;
  bool get isComingSoon => status == 'coming_soon';
  factory BelanjakuProduct.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    int n(dynamic v) => v is num ? v.round() : int.tryParse(v?.toString() ?? '') ?? 0;
    return BelanjakuProduct(id: doc.id, name: d['name'] as String? ?? '', category: d['category'] as String? ?? 'Lainnya', description: d['description'] as String? ?? '', imageUrl: d['imageUrl'] as String? ?? '', price: n(d['price']), unit: d['unit'] as String? ?? 'pcs', stock: n(d['stock']), status: d['status'] as String? ?? 'coming_soon', isActive: d['isActive'] != false);
  }
}
