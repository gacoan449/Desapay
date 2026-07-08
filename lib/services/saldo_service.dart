import 'package:cloud_firestore/cloud_firestore.dart';

class SaldoService {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Future<void> tambahSaldo({
    required String uid,
    required int nominal,
  }) async {

    final doc =
        firestore.collection("users").doc(uid);

    await firestore.runTransaction((trx) async {

      final snap = await trx.get(doc);

      final data = snap.data()!;

      final saldo = data["saldo"] ?? 0;

      trx.update(doc, {

        "saldo": saldo + nominal,

      });

    });

  }

}
