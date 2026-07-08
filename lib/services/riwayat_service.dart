import 'package:cloud_firestore/cloud_firestore.dart';

class RiwayatService {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Future<void> simpan(Map<String, dynamic> trx) async {

    await firestore
        .collection("transactions")
        .add(trx);

  }

}
