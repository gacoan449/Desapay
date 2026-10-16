import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class BelanjakuInterestService {
  BelanjakuInterestService({FirebaseFirestore? firestore, FirebaseAuth? auth}) : _db = firestore ?? FirebaseFirestore.instance, _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  Future<void> expressInterest({required String productId, required String productName, required String areaId, required String areaName}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Silakan masuk ke DesaPay terlebih dahulu.');
    if (areaId.trim().isEmpty || areaName.trim().isEmpty) throw ArgumentError('Pilih wilayah terlebih dahulu.');
    final safeId = productId.replaceAll('/', '_');
    await _db.collection('belanjaku_product_interests').doc(user.uid + '_' + safeId).set({'uid': user.uid, 'productId': productId, 'productName': productName, 'areaId': areaId, 'areaName': areaName, 'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
}
