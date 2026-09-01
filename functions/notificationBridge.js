"use strict";

const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

const db = admin.firestore();
const REGION = "asia-southeast2";

exports.bridgeTransactionNotification = onDocumentCreated(
    {document: "transactions/{transactionId}", region: REGION},
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data() || {};
      const status = String(data.status || "").toUpperCase();
      const isSuccess = status === "SUCCESS";

      await db.collection("notifikasi").add({
        uid: data.uid,
        tipe: "transaksi",
        judul: isSuccess ? "Transaksi berhasil" : "Transaksi gagal",
        pesan: isSuccess
          ? `Transaksi ${data.productName || data.buyer_sku_code || "PPOB"} berhasil.`
          : "Transaksi gagal. Saldo telah dikembalikan jika sebelumnya terdebit.",
        status: isSuccess ? "sukses" : "gagal",
        transactionId: snap.id,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    },
);
