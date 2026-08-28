"use strict";

const crypto = require("crypto");

const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

const TRIPAY_PRIVATE_KEY = defineSecret("TRIPAY_PRIVATE_KEY");

/*
|--------------------------------------------------------------------------
| KONSTANTA
|--------------------------------------------------------------------------
*/

const REGION = "asia-southeast2";

const ALLOWED_STATUS = new Set([
  "PAID",
  "UNPAID",
  "EXPIRED",
  "FAILED",
]);

const BALANCE_FIELD = "balance";

/*
|--------------------------------------------------------------------------
| RESPONSE
|--------------------------------------------------------------------------
*/

function sendJson(res, statusCode, data) {
  return res.status(statusCode).json(data);
}

/*
|--------------------------------------------------------------------------
| HMAC SHA256 CALLBACK
|--------------------------------------------------------------------------
*/

function generateSignature(rawBody, privateKey) {
  return crypto
    .createHmac("sha256", privateKey)
    .update(rawBody, "utf8")
    .digest("hex");
}

/*
|--------------------------------------------------------------------------
| CONSTANT TIME SIGNATURE CHECK
|--------------------------------------------------------------------------
*/

function verifySignature(rawBody, receivedSignature, privateKey) {
  if (!rawBody || !receivedSignature || !privateKey) {
    return false;
  }

  try {
    const expected = generateSignature(rawBody, privateKey);

    const expectedBuffer = Buffer.from(expected, "hex");
    const receivedBuffer = Buffer.from(
      receivedSignature.trim().toLowerCase(),
      "hex"
    );

    if (expectedBuffer.length !== receivedBuffer.length) {
      return false;
    }

    return crypto.timingSafeEqual(
      expectedBuffer,
      receivedBuffer
    );
  } catch (_) {
    return false;
  }
}

/*
|--------------------------------------------------------------------------
| INTEGER AMAN
|--------------------------------------------------------------------------
*/

function toSafeInteger(value) {
  const number = Number(value);

  if (!Number.isSafeInteger(number)) {
    return null;
  }

  return number;
}

/*
|--------------------------------------------------------------------------
| CALLBACK TRIPAY
|--------------------------------------------------------------------------
|
| URL:
|
| https://asia-southeast2-PROJECT_ID.cloudfunctions.net/tripayCallback
|
|--------------------------------------------------------------------------
*/

exports.tripayCallback = onRequest(
  {
    region: REGION,
    secrets: [TRIPAY_PRIVATE_KEY],
    cors: false,
    timeoutSeconds: 30,
    memory: "256MiB",
  },

  async (req, res) => {
    /*
    |--------------------------------------------------------------------------
    | 1. HANYA POST
    |--------------------------------------------------------------------------
    */

    if (req.method !== "POST") {
      return sendJson(res, 405, {
        success: false,
        message: "Method Not Allowed",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 2. RAW BODY
    |--------------------------------------------------------------------------
    |
    | WAJIB menggunakan raw body untuk verifikasi signature.
    |
    */

    let rawBody = "";

    if (Buffer.isBuffer(req.rawBody)) {
      rawBody = req.rawBody.toString("utf8");
    } else if (typeof req.rawBody === "string") {
      rawBody = req.rawBody;
    } else {
      rawBody = JSON.stringify(req.body || {});
    }

    if (!rawBody.trim()) {
      logger.warn("Callback ditolak: body kosong.");

      return sendJson(res, 400, {
        success: false,
        message: "Empty callback body.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 3. AMBIL SIGNATURE
    |--------------------------------------------------------------------------
    */

    const receivedSignature =
      req.get("X-Callback-Signature") ||
      req.get("x-callback-signature") ||
      req.get("Signature");

    if (!receivedSignature) {
      logger.warn(
        "Callback ditolak: X-Callback-Signature tidak ditemukan."
      );

      return sendJson(res, 401, {
        success: false,
        message: "Invalid callback signature.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 4. PRIVATE KEY DARI FIREBASE SECRET
    |--------------------------------------------------------------------------
    */

    const privateKey = TRIPAY_PRIVATE_KEY.value();

    if (!privateKey) {
      logger.error(
        "TRIPAY_PRIVATE_KEY belum dikonfigurasi."
      );

      return sendJson(res, 500, {
        success: false,
        message: "Payment gateway belum dikonfigurasi.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 5. VERIFIKASI SIGNATURE
    |--------------------------------------------------------------------------
    */

    const signatureValid = verifySignature(
      rawBody,
      receivedSignature,
      privateKey
    );

    if (!signatureValid) {
      logger.warn(
        "Callback ditolak: signature tidak valid."
      );

      return sendJson(res, 401, {
        success: false,
        message: "Invalid callback signature.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 6. PARSE JSON
    |--------------------------------------------------------------------------
    */

    let payload;

    try {
      payload = JSON.parse(rawBody);
    } catch (error) {
      logger.error(
        "Callback JSON tidak valid.",
        error
      );

      return sendJson(res, 400, {
        success: false,
        message: "Invalid JSON.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 7. AMBIL DATA CALLBACK
    |--------------------------------------------------------------------------
    */

    const reference =
      String(payload.reference || "").trim();

    const merchantRef =
      String(payload.merchant_ref || "").trim();

    const status =
      String(payload.status || "")
        .trim()
        .toUpperCase();

    const totalAmount =
      toSafeInteger(payload.total_amount);

    const amountReceived =
      toSafeInteger(payload.amount_received);

    /*
    |--------------------------------------------------------------------------
    | 8. VALIDASI DATA WAJIB
    |--------------------------------------------------------------------------
    */

    if (
      !reference ||
      !merchantRef ||
      !status
    ) {
      logger.warn(
        "Callback ditolak: data tidak lengkap.",
        {
          reference,
          merchantRef,
          status,
        }
      );

      return sendJson(res, 400, {
        success: false,
        message: "Callback data tidak lengkap.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 9. VALIDASI STATUS
    |--------------------------------------------------------------------------
    */

    if (!ALLOWED_STATUS.has(status)) {
      logger.warn(
        `Status callback tidak dikenal: ${status}`
      );

      return sendJson(res, 400, {
        success: false,
        message: "Status transaksi tidak dikenal.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 10. VALIDASI NOMINAL
    |--------------------------------------------------------------------------
    */

    if (
      totalAmount === null ||
      totalAmount <= 0
    ) {
      logger.warn(
        `Nominal callback tidak valid: ${merchantRef}`
      );

      return sendJson(res, 400, {
        success: false,
        message: "Nominal transaksi tidak valid.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 11. REFERENSI TRANSAKSI DESAPAY
    |--------------------------------------------------------------------------
    |
    | Saat invoice dibuat, aplikasi/backend WAJIB membuat:
    |
    | topup_transactions/{merchantRef}
    |
    | Contoh:
    |
    | {
    |   uid: "...",
    |   merchantRef: "DP-123456",
    |   reference: "...",
    |   amount: 50000,
    |   status: "UNPAID"
    | }
    |
    */

    const transaksiRef = db
      .collection("topup_transactions")
      .doc(merchantRef);

    try {
      const result = await db.runTransaction(
        async (transaction) => {
          /*
          |--------------------------------------------------------------------------
          | 12. AMBIL TRANSAKSI TOP UP
          |--------------------------------------------------------------------------
          */

          const transaksiSnap =
            await transaction.get(transaksiRef);

          if (!transaksiSnap.exists) {
            throw new Error(
              "TRANSACTION_NOT_FOUND"
            );
          }

          const transaksi =
            transaksiSnap.data() || {};

          /*
          |--------------------------------------------------------------------------
          | 13. UID
          |--------------------------------------------------------------------------
          */

          const uid =
            String(transaksi.uid || "").trim();

          if (!uid) {
            throw new Error(
              "TRANSACTION_UID_MISSING"
            );
          }

          /*
          |--------------------------------------------------------------------------
          | 14. VALIDASI MERCHANT REF
          |--------------------------------------------------------------------------
          */

          const savedMerchantRef =
            String(
              transaksi.merchantRef || ""
            ).trim();

          if (
            savedMerchantRef !== merchantRef
          ) {
            throw new Error(
              "MERCHANT_REFERENCE_MISMATCH"
            );
          }

          /*
          |--------------------------------------------------------------------------
          | 15. VALIDASI REFERENCE TRIPAY
          |--------------------------------------------------------------------------
          */

          const savedReference =
            String(
              transaksi.reference || ""
            ).trim();

          if (
            savedReference &&
            savedReference !== reference
          ) {
            throw new Error(
              "TRIPAY_REFERENCE_MISMATCH"
            );
          }

          /*
          |--------------------------------------------------------------------------
          | 16. VALIDASI NOMINAL
          |--------------------------------------------------------------------------
          */

          const expectedAmount =
            toSafeInteger(transaksi.amount);

          if (
            expectedAmount === null ||
            expectedAmount <= 0
          ) {
            throw new Error(
              "INVALID_TRANSACTION_AMOUNT"
            );
          }

          if (
            expectedAmount !== totalAmount
          ) {
            throw new Error(
              "AMOUNT_MISMATCH"
            );
          }

          /*
          |--------------------------------------------------------------------------
          | 17. ANTI DOUBLE CREDIT
          |--------------------------------------------------------------------------
          */

          const currentStatus =
            String(
              transaksi.status || "UNPAID"
            ).toUpperCase();

          if (currentStatus === "PAID") {
            return {
              alreadyPaid: true,
              credited: false,
              uid,
              saldoAkhir:
                toSafeInteger(
                  transaksi.saldoAkhir
                ) || 0,
            };
          }

          /*
          |--------------------------------------------------------------------------
          | 18. STATUS NON-PAID
          |--------------------------------------------------------------------------
          |
          | EXPIRED / FAILED / UNPAID
          | tidak boleh menambah saldo.
          |
          */

          if (status !== "PAID") {
            transaction.update(
              transaksiRef,
              {
                status,
                reference,
                totalAmount,
                amountReceived:
                  amountReceived ?? 0,
                callbackReceivedAt:
                  admin.firestore.FieldValue
                    .serverTimestamp(),
                updatedAt:
                  admin.firestore.FieldValue
                    .serverTimestamp(),
              }
            );

            return {
              alreadyPaid: false,
              credited: false,
              uid,
              status,
            };
          }

          /*
          |--------------------------------------------------------------------------
          | 19. AMBIL USER
          |--------------------------------------------------------------------------
          */

          const userRef =
            db.collection("users").doc(uid);

          const userSnap =
            await transaction.get(userRef);

          if (!userSnap.exists) {
            throw new Error(
              "USER_NOT_FOUND"
            );
          }

          const userData =
            userSnap.data() || {};

          /*
          |--------------------------------------------------------------------------
          | 20. FIELD SALDO
          |--------------------------------------------------------------------------
          |
          | HARUS SAMA dengan SaldoService:
          |
          | balance
          |
          */

          const saldoSebelumnya =
            toSafeInteger(
              userData[BALANCE_FIELD]
            );

          if (
            saldoSebelumnya === null ||
            saldoSebelumnya < 0
          ) {
            throw new Error(
              "INVALID_USER_BALANCE"
            );
          }

          /*
          |--------------------------------------------------------------------------
          | 21. HITUNG SALDO BARU
          |--------------------------------------------------------------------------
          */

          const saldoBaru =
            saldoSebelumnya +
            expectedAmount;

          if (
            !Number.isSafeInteger(
              saldoBaru
            )
          ) {
            throw new Error(
              "BALANCE_OVERFLOW"
            );
          }

          /*
          |--------------------------------------------------------------------------
          | 22. UPDATE SALDO USER
          |--------------------------------------------------------------------------
          */

          transaction.update(
            userRef,
            {
              [BALANCE_FIELD]:
                saldoBaru,

              updatedAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),
            }
          );

          /*
          |--------------------------------------------------------------------------
          | 23. BUAT MUTASI SALDO
          |--------------------------------------------------------------------------
          */

          const mutasiRef =
            db.collection(
              "mutasi_saldo"
            ).doc();

          transaction.set(
            mutasiRef,
            {
              uid,

              tipe: "MASUK",

              nominal:
                expectedAmount,

              saldoAwal:
                saldoSebelumnya,

              saldoAkhir:
                saldoBaru,

              keterangan:
                "Top Up Saldo via TriPay",

              sumber:
                "TRIPAY_CALLBACK",

              merchantRef,

              reference,

              waktu:
                admin.firestore.FieldValue
                  .serverTimestamp(),
            }
          );

          /*
          |--------------------------------------------------------------------------
          | 24. TANDAI TRANSAKSI SUDAH DICREDIT
          |--------------------------------------------------------------------------
          */

          transaction.update(
            transaksiRef,
            {
              status: "PAID",

              reference,

              totalAmount:
                expectedAmount,

              amountReceived:
                amountReceived ?? 0,

              creditedAmount:
                expectedAmount,

              saldoAwal:
                saldoSebelumnya,

              saldoAkhir:
                saldoBaru,

              credited: true,

              creditedAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),

              callbackReceivedAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),

              updatedAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),
            }
          );

          /*
          |--------------------------------------------------------------------------
          | 25. HASIL
          |--------------------------------------------------------------------------
          */

          return {
            alreadyPaid: false,
            credited: true,
            uid,
            saldoAkhir: saldoBaru,
          };
        }
      );

      /*
      |--------------------------------------------------------------------------
      | 26. CALLBACK DUPLIKAT
      |--------------------------------------------------------------------------
      */

      if (result.alreadyPaid) {
        logger.info(
          `Callback duplicate diabaikan: ${merchantRef}`
        );

        return sendJson(res, 200, {
          success: true,
          message:
            "Transaction already processed.",
        });
      }

      /*
      |--------------------------------------------------------------------------
      | 27. TOP UP BERHASIL
      |--------------------------------------------------------------------------
      */

      if (result.credited) {
        logger.info(
          `TOP UP BERHASIL | ${merchantRef} | UID: ${result.uid} | SALDO: ${result.saldoAkhir}`
        );

        return sendJson(res, 200, {
          success: true,
        });
      }

      /*
      |--------------------------------------------------------------------------
      | 28. STATUS NON-PAID
      |--------------------------------------------------------------------------
      */

      return sendJson(res, 200, {
        success: true,
        message:
          `Transaction status updated to ${result.status}.`,
      });
    } catch (error) {
      /*
      |--------------------------------------------------------------------------
      | 29. ERROR
      |--------------------------------------------------------------------------
      */

      logger.error(
        `Gagal memproses callback ${merchantRef}`,
        error
      );

      /*
      |--------------------------------------------------------------------------
      | TRANSAKSI TIDAK TERDAFTAR
      |--------------------------------------------------------------------------
      |
      | 500 supaya TriPay melakukan retry.
      |
      */

      if (
        error.message ===
        "TRANSACTION_NOT_FOUND"
      ) {
        return sendJson(res, 500, {
          success: false,
          message:
            "Transaction not registered.",
        });
      }

      /*
      |--------------------------------------------------------------------------
      | ERROR LAIN
      |--------------------------------------------------------------------------
      |
      | Return 500 supaya callback dapat di-retry.
      |
      */

      return sendJson(res, 500, {
        success: false,
        message:
          "Callback processing failed.",
      });
    }
  }
);
