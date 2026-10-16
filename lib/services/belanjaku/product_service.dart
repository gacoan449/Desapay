import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/belanjaku/product_model.dart';
class BelanjakuProductService {
  BelanjakuProductService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _products => _db.collection('belanjaku_products');
  Stream<List<BelanjakuProduct>> watchActiveProducts() => _products.where('isActive', isEqualTo: true).snapshots().map((s) => s.docs.map(BelanjakuProduct.fromDocument).toList(growable: false));
  Stream<List<BelanjakuProduct>> watchCategory(String category) => _products.where('isActive', isEqualTo: true).where('category', isEqualTo: category).snapshots().map((s) => s.docs.map(BelanjakuProduct.fromDocument).toList(growable: false));
}
