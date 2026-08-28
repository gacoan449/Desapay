"use strict";

const crypto = require("crypto");

const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/*
|--------------------------------------------------------------------------
| KONFIGURASI
|--------------------------------------------------------------------------
|
| JANGAN taruh Private Key TriPay di Flutter.
|
| Set secret menggunakan:
|
| firebase functions:secrets:set TRIPAY_PRIVATE_KEY
|
*/

const { defineSecret } = require("firebase-functions/params");

const TRIPAY_PRIVATE_KEY = defineSecret("TRIPAY_PRIVATE_KEY");

/*
|--------------------------------------------------------------------------
| HELPER
|--------------------------------------------------------------------------
*/

function jsonResponse(res, statusCode, data) {
  res.status(statusCode).json(data);
}

/*
|--------------------------------------------------------------------------
| HMAC SHA256
|--------------------------------------------------------------------------
|
| Callback TriPay harus diverifikasi menggunakan raw body.
|
*/

function generateCallbackSignature(rawBody, privateKey) {
  return crypto
    .createHmac("sha256", privateKey)
    .update(rawBody, "utf8")
    .digest("hex");
}

/*
|--------------------------------------------------------------------------
| CONSTANT
|--------------------------------------------------------------------------
*/

const ALLOWED_STATUS = new Set([
  "PAID",
  "UNPAID",
  "EXPIRED",
  "FAILED"
]);

/*
|--------------------------------------------------------------------------
| CALLBACK TRIPAY
|--------------------------------------------------------------------------
|
| URL:
|
| https://asia-southeast2-PROJECT_ID.cloudfunctions.net/tripayCallback
|
*/

exports.tripayCallback = onRequest(
  {
    region: "asia-southeast2",
    secrets: [TRIPAY_PRIVATE_KEY],
    cors: false,
    timeoutSeconds: 30,
    memory: "256MiB"
  },
  async (req, res) => {
    /*
    |--------------------------------------------------------------------------
    | HANYA POST
    |--------------------------------------------------------------------------
    */

    if (req.method !== "POST") {
      return jsonResponse(res, 405, {
        success: false,
        message: "Method Not Allowed"
      });
    }

    /*
    |--------------------------------------------------------------------------
    | AMBIL RAW BODY
    |--------------------------------------------------------------------------
    |
    | Signature harus dihitung dari JSON mentah.
    |
    */

    let rawBody;

    if (Buffer.isBuffer(req.rawBody)) {
      rawBody = req.rawBody.toString("utf8");
    } else if (typeof req.rawBody === "string") {
      rawBody = req.rawBody;
    } else {
      rawBody = JSON.stringify(req.body || {});
    }

    /*
    |--------------------------------------------------------------------------
    | AMBIL SIGNATURE
    |--------------------------------------------------------------------------
    */

    const remoteSignature =
      req.headers["x-callback-signature"] ||
      req.headers["x-callback-signature".toLowerCase()] ||
      req.headers["signature"];

    if (!remoteSignature || typeof remoteSignature !== "string") {
      logger.warn("Callback ditolak: signature tidak ditemukan.");

      return jsonResponse(res, 401, {
        success: false,
        message: "Invalid callback signature"
      });
    }

    /*
    |--------------------------------------------------------------------------
    | VERIFIKASI SIGNATURE
    |--------------------------------------------------------------------------
    */

    const privateKey = TRIPAY_PRIVATE_KEY.value();

    if (!privateKey) {
      logger.error("TRIPAY_PRIVATE_KEY belum dikonfigurasi.");

      return jsonResponse(res, 500, {
        success: false,
        message: "Server payment gateway belum dikonfigurasi."
      });
    }

    const expectedSignature = generateCallbackSignature(
      rawBody.trim(),
      privateKey
    );

    const receivedSignature = remoteSignature.trim().toLowerCase();

    let signatureValid = false;

    try {
      const expectedBuffer = Buffer.from(expectedSignature, "hex");
      const receivedBuffer = Buffer.from(receivedSignature, "hex");

      if (expectedBuffer.length === receivedBuffer.length) {
        signatureValid = crypto.timingSafeEqual(
          expectedBuffer,
          receivedBuffer
        );
      }
    } catch (_) {
      signatureValid = false;
    }

    if (!signatureValid) {
      logger.warn("Callback ditolak: signature tidak valid.");

      return jsonResponse(res, 401, {
        success: false,
        message: "Invalid callback signature"
      });
    }

    /*
    |--------------------------------------------------------------------------
    | PARSE JSON
    |--------------------------------------------------------------------------
    */

    let payload;

    try {
      payload = JSON.parse(rawBody);
    } catch (e) {
      logger.error("Callback bukan JSON valid.", e);

      return jsonResponse(res, 400, {
        success: false,
        message: "Invalid JSON"
      });
    }

    /*
    |--------------------------------------------------------------------------
    | DATA CALLBACK
    |--------------------------------------------------------------------------
    */

    const reference = String(payload.reference || "").trim();
    const merchantRef = String(payload.merchant_ref || "").trim();
    const status = String(payload.status || "").trim().toUpperCase();

    const totalAmount = Number(payload.total_amount || 0);
    const amountReceived = Number(payload.amount_received || 0);

    if (!reference || !merchantRef || !status) {
      logger.warn("Callback tidak lengkap.", payload);

      return jsonResponse(res, 400, {
        success: false,
        message: "Callback data tidak lengkap."
      });
    }

    if (!ALLOWED_STATUS.has(status)) {
      logger.warn(`Status callback tidak dikenal: ${status}`);

      return jsonResponse(res, 400, {
        success: false,
        message: "Status transaksi tidak dikenal."
      });
    }

    /*
    |--------------------------------------------------------------------------
    | VALIDASI NOMINAL
    |--------------------------------------------------------------------------
    */

    if (totalAmount <= 0) {
      return jsonResponse(res, 400, {
        success: false,
        message: "Nominal transaksi tidak valid."
      });
    }

    /*
    |--------------------------------------------------------------------------
    | CARI TRANSAKSI
    |--------------------------------------------------------------------------
    |
    | Dokumen transaksi wajib sudah dibuat ketika invoice dibuat.
    |
    */

    const transaksiRef = db
      .collection("topup_transactions")
      .doc(merchantRef);

    try {
      const result = await db.runTransaction(async (transaction) => {
        const transaksiSnap = await transaction.get(transaksiRef);

        /*
        |--------------------------------------------------------------------------
        | TRANSAKSI TIDAK DITEMUKAN
        |--------------------------------------------------------------------------
        */

        if (!transaksiSnap.exists) {
          throw new Error("TRANSACTION_NOT_FOUND");
        }

        const transaksi = transaksiSnap.data();

        const uid = String(transaksi.uid || "");

        if (!uid) {
          throw new Error("TRANSACTION_UID_MISSING");
        }

        /*
        |--------------------------------------------------------------------------
        | ANTI DOUBLE CREDIT
        |--------------------------------------------------------------------------
        */

        const currentStatus =
          String(transaksi.status || "UNPAID").toUpperCase();

        if (currentStatus === "PAID") {
          return {
            alreadyPaid: true,
            uid,
            saldoAkhir: Number(transaksi.saldoAkhir || 0)
          };
        }

        /*
        |--------------------------------------------------------------------------
        | VALIDASI MERCHANT REF
        |--------------------------------------------------------------------------
        */

        if (transaksi.merchantRef !== merchantRef) {
          throw new Error("MERCHANT_REFERENCE_MISMATCH");
        }

        /*
        |--------------------------------------------------------------------------
        | VALIDASI REFERENCE TRIPAY
        |--------------------------------------------------------------------------
        */

        if (
          transaksi.reference &&
          String(transaksi.reference) !== reference
        ) {
          throw new Error("TRIPAY_REFERENCE_MISMATCH");
        }

        /*
        |--------------------------------------------------------------------------
        | VALIDASI NOMINAL
        |--------------------------------------------------------------------------
        */

        const expectedAmount = Number(transaksi.amount || 0);

        if (
          expectedAmount <= 0 ||
          expectedAmount !== totalAmount
        ) {
          throw new Error("AMOUNT_MISMATCH");
        }

        /*
        |--------------------------------------------------------------------------
        | STATUS SELAIN PAID
        |--------------------------------------------------------------------------
        |
        | Tidak boleh menambah saldo.
        |
        */

        if (status !== "PAID") {
          transaction.update(transaksiRef, {
            status,
            callbackReference: reference,
            callbackReceivedAt:
              admin.firestore.FieldValue.serverTimestamp(),
            updatedAt:
              admin.firestore.FieldValue.serverTimestamp()
          });

          return {
            alreadyPaid: false,
            credited: false,
            uid,
            status
          };
        }

        /*
        |--------------------------------------------------------------------------
        | AMOUNT RECEIVED
        |--------------------------------------------------------------------------
        |
        | amount_received bisa berbeda dari total transaksi
        | karena fee. Untuk kredit saldo, gunakan nominal topup
        | yang sudah divalidasi dari transaksi.
        |
        */

        if (
          amountReceived > 0 &&
          amountReceived > expectedAmount
        ) {
          logger.warn(
            `amount_received lebih besar dari expectedAmount: ${merchantRef}`
          );
        }

        /*
        |--------------------------------------------------------------------------
        | AMBIL USER
        |--------------------------------------------------------------------------
        */

        const userRef = db.collection("users").doc(uid);
        const userSnap = await transaction.get(userRef);

        if (!userSnap.exists) {
          throw new Error("USER_NOT_FOUND");
        }

        const userData = userSnap.data();

        const saldoSebelumnya =
          Number(userData.saldo || 0);

        if (
          !Number.isSafeInteger(saldoSebelumnya) ||
          saldoSebelumnya < 0
        ) {
          throw new Error("INVALID_USER_BALANCE");
        }

        /*
        |--------------------------------------------------------------------------
        | HITUNG SALDO BARU
        |--------------------------------------------------------------------------
        */

        const saldoBaru =
          saldoSebelumnya + expectedAmount;

        if (!Number.isSafeInteger(saldoBaru)) {
          throw new Error("BALANCE_OVERFLOW");
        }

        /*
        |--------------------------------------------------------------------------
        | UPDATE SALDO
        |--------------------------------------------------------------------------
        */

        transaction.update(userRef, {
          saldo: saldoBaru,
          updatedAt:
            admin.firestore.FieldValue.serverTimestamp()
        });

        /*
        |--------------------------------------------------------------------------
        | AUDIT MUTASI
        |--------------------------------------------------------------------------
        */

        const mutasiRef =
          db.collection("mutasi_saldo").doc();

        transaction.set(mutasiRef, {
          uid,
          tipe: "MASUK",
          nominal: expectedAmount,
          saldoAwal: saldoSebelumnya,
          saldoAkhir: saldoBaru,
          keterangan: "Top Up Saldo via TriPay",
          sumber: "TRIPAY_CALLBACK",
          merchantRef,
          reference,
          waktu:
            admin.firestore.FieldValue.serverTimestamp()
        });

        /*
        |--------------------------------------------------------------------------
        | UPDATE TRANSAKSI
        |--------------------------------------------------------------------------
        */

        transaction.update(transaksiRef, {
          status: "PAID",
          reference,
          amountReceived,
          creditedAmount: expectedAmount,
          saldoAwal: saldoSebelumnya,
          saldoAkhir: saldoBaru,
          creditedAt:
            admin.firestore.FieldValue.serverTimestamp(),
          callbackReceivedAt:
            admin.firestore.FieldValue.serverTimestamp(),
          updatedAt:
            admin.firestore.FieldValue.serverTimestamp()
        });

        return {
          alreadyPaid: false,
          credited: true,
          uid,
          saldoAkhir: saldoBaru
        };
      });

      /*
      |--------------------------------------------------------------------------
      | HASIL
      |--------------------------------------------------------------------------
      */

      if (result.alreadyPaid) {
        logger.info(
          `Callback duplicate diabaikan: ${merchantRef}`
        );

        return jsonResponse(res, 200, {
          success: true,
          message: "Transaction already processed."
        });
      }

      if (result.credited) {
        logger.info(
          `TOP UP BERHASIL: ${merchantRef} -> ${result.uid} -> ${result.saldoAkhir}`
        );

        return jsonResponse(res, 200, {
          success: true
        });
      }

      return jsonResponse(res, 200, {
        success: true,
        message: `Transaction status updated to ${result.status}.`
      });
    } catch (error) {
      logger.error(
        `Gagal memproses callback ${merchantRef}`,
        error
      );

      /*
      |--------------------------------------------------------------------------
      | ERROR TRANSAKSI TIDAK DITEMUKAN
      |--------------------------------------------------------------------------
      |
      | Return 500 agar TriPay dapat melakukan retry.
      |
      */

      if (error.message === "TRANSACTION_NOT_FOUND") {
        return jsonResponse(res, 500, {
          success: false,
          message: "Transaction not registered."
        });
      }

      return jsonResponse(res, 500, {
        success: false,
        message: "Callback processing failed."
      });
    }
  }
);
