import 'package:cloud_firestore/cloud_firestore.dart';
class BelanjakuDeliveryAreaService {
  BelanjakuDeliveryAreaService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  Stream<List<Map<String, dynamic>>> watchActiveAreas() => _db.collection('belanjaku_delivery_areas').where('isActive', isEqualTo: true).snapshots().map((s) => s.docs.map((d) => <String, dynamic>{'id': d.id, ...d.data()}).toList(growable: false));
}
