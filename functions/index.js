"use strict";

const crypto = require("crypto");

const {
  onRequest,
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/*
|--------------------------------------------------------------------------
| SECRET
|--------------------------------------------------------------------------
*/

const TRIPAY_PRIVATE_KEY =
  defineSecret("TRIPAY_PRIVATE_KEY");

/*
|--------------------------------------------------------------------------
| KONSTANTA
|--------------------------------------------------------------------------
*/

const REGION = "asia-southeast2";
const BALANCE_FIELD = "balance";

const ALLOWED_STATUS = new Set([
  "PAID",
  "UNPAID",
  "EXPIRED",
  "FAILED",
]);

/*
|--------------------------------------------------------------------------
| HELPER
|--------------------------------------------------------------------------
*/

function sendJson(res, statusCode, data) {
  return res.status(statusCode).json(data);
}

function toSafeInteger(value) {
  const number = Number(value);

  if (!Number.isSafeInteger(number)) {
    return null;
  }

  return number;
}

function generateSignature(rawBody, privateKey) {
  return crypto
    .createHmac("sha256", privateKey)
    .update(rawBody, "utf8")
    .digest("hex");
}

function verifySignature(
  rawBody,
  receivedSignature,
  privateKey
) {
  if (!rawBody || !receivedSignature || !privateKey) {
    return false;
  }

  try {
    const expected = generateSignature(
      rawBody,
      privateKey
    );

    const expectedBuffer = Buffer.from(
      expected,
      "hex"
    );

    const receivedBuffer = Buffer.from(
      receivedSignature.trim().toLowerCase(),
      "hex"
    );

    if (
      expectedBuffer.length !==
      receivedBuffer.length
    ) {
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
| ADMIN CHECK
|--------------------------------------------------------------------------
*/

async function checkAdmin(uid) {
  if (!uid) {
    return false;
  }

  const snap = await db
    .collection("users")
    .doc(uid)
    .get();

  if (!snap.exists) {
    return false;
  }

  const data = snap.data() || {};

  return data.role === "admin";
}

/*
|--------------------------------------------------------------------------
| ADMIN UBah SALDO
|--------------------------------------------------------------------------
|
| Flutter TIDAK PERNAH menulis users.balance langsung.
|
| Alur:
|
| Admin Flutter
|      ↓
| adminAdjustBalance
|      ↓
| Firestore Transaction
|      ├── users/{uid}.balance
|      └── balance_ledger/{id}
|
|--------------------------------------------------------------------------
*/

exports.adminAdjustBalance = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
  },

  async (request) => {
    /*
    |--------------------------------------------------------------------------
    | 1. WAJIB LOGIN
    |--------------------------------------------------------------------------
    */

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Admin harus login."
      );
    }

    const adminUid = request.auth.uid;

    /*
    |--------------------------------------------------------------------------
    | 2. WAJIB ADMIN
    |--------------------------------------------------------------------------
    */

    const adminIsValid =
      await checkAdmin(adminUid);

    if (!adminIsValid) {
      throw new HttpsError(
        "permission-denied",
        "Akses hanya untuk admin."
      );
    }

    /*
    |--------------------------------------------------------------------------
    | 3. VALIDASI INPUT
    |--------------------------------------------------------------------------
    */

    const data = request.data || {};

    const uid =
      typeof data.uid === "string"
        ? data.uid.trim()
        : "";

    const alasan =
      typeof data.alasan === "string"
        ? data.alasan.trim()
        : "";

    const amount =
      toSafeInteger(data.amount);

    if (!uid) {
      throw new HttpsError(
        "invalid-argument",
        "UID user wajib diisi."
      );
    }

    if (!alasan) {
      throw new HttpsError(
        "invalid-argument",
        "Alasan perubahan saldo wajib diisi."
      );
    }

    if (
      amount === null ||
      amount === 0
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Nominal saldo tidak valid."
      );
    }

    /*
    |--------------------------------------------------------------------------
    | 4. BATAS NOMINAL
    |--------------------------------------------------------------------------
    |
    | Maksimum perubahan sekali transaksi:
    | Rp100.000.000
    |
    */

    const MAX_ADJUSTMENT = 100000000;

    if (
      Math.abs(amount) >
      MAX_ADJUSTMENT
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Nominal perubahan saldo terlalu besar."
      );
    }

    /*
    |--------------------------------------------------------------------------
    | 5. REFERENSI USER
    |--------------------------------------------------------------------------
    */

    const userRef =
      db.collection("users").doc(uid);

    try {
      const result =
        await db.runTransaction(
          async (transaction) => {
            /*
            |--------------------------------------------------------------------------
            | AMBIL USER
            |--------------------------------------------------------------------------
            */

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
            | SALDO LAMA
            |--------------------------------------------------------------------------
            */

            const before =
              toSafeInteger(
                userData[BALANCE_FIELD]
              );

            if (
              before === null ||
              before < 0
            ) {
              throw new Error(
                "INVALID_BALANCE"
              );
            }

            /*
            |--------------------------------------------------------------------------
            | SALDO BARU
            |--------------------------------------------------------------------------
            */

            const after =
              before + amount;

            if (
              !Number.isSafeInteger(after)
            ) {
              throw new Error(
                "BALANCE_OVERFLOW"
              );
            }

            if (after < 0) {
              throw new Error(
                "NEGATIVE_BALANCE"
              );
            }

            /*
            |--------------------------------------------------------------------------
            | UPDATE USER
            |--------------------------------------------------------------------------
            */

            transaction.update(
              userRef,
              {
                [BALANCE_FIELD]: after,

                updatedAt:
                  admin.firestore
                    .FieldValue
                    .serverTimestamp(),
              }
            );

            /*
            |--------------------------------------------------------------------------
            | LEDGER
            |--------------------------------------------------------------------------
            */

            const ledgerRef =
              db
                .collection("balance_ledger")
                .doc();

            transaction.set(
              ledgerRef,
              {
                uid,

                type:
                  amount > 0
                    ? "CREDIT"
                    : "DEBIT",

                amount:
                  Math.abs(amount),

                before,

                after,

                reason: alasan,

                source: "ADMIN",

                adminUid,

                createdAt:
                  admin.firestore
                    .FieldValue
                    .serverTimestamp(),
              }
            );

            return {
              uid,
              before,
              after,
              amount,
              ledgerId: ledgerRef.id,
            };
          }
        );

      logger.info(
        "ADMIN SALDO BERHASIL",
        {
          adminUid,
          uid: result.uid,
          amount: result.amount,
          before: result.before,
          after: result.after,
        }
      );

      return {
        success: true,
        uid: result.uid,
        amount: result.amount,
        before: result.before,
        after: result.after,
        ledgerId: result.ledgerId,
      };
    } catch (error) {
      logger.error(
        "ADMIN SALDO GAGAL",
        {
          adminUid,
          uid,
          error: error.message,
        }
      );

      switch (error.message) {
        case "USER_NOT_FOUND":
          throw new HttpsError(
            "not-found",
            "User tidak ditemukan."
          );

        case "INVALID_BALANCE":
          throw new HttpsError(
            "failed-precondition",
            "Saldo user tidak valid."
          );

        case "NEGATIVE_BALANCE":
          throw new HttpsError(
            "failed-precondition",
            "Saldo tidak boleh negatif."
          );

        case "BALANCE_OVERFLOW":
          throw new HttpsError(
            "out-of-range",
            "Saldo melebihi batas aman."
          );

        default:
          throw new HttpsError(
            "internal",
            "Gagal mengubah saldo."
          );
      }
    }
  }
);

/*
|--------------------------------------------------------------------------
| TRIPAY CALLBACK
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
    | 1. POST ONLY
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
    */

    let rawBody = "";

    if (Buffer.isBuffer(req.rawBody)) {
      rawBody =
        req.rawBody.toString("utf8");
    } else if (
      typeof req.rawBody === "string"
    ) {
      rawBody = req.rawBody;
    } else {
      rawBody = JSON.stringify(
        req.body || {}
      );
    }

    if (!rawBody.trim()) {
      logger.warn(
        "Callback ditolak: body kosong."
      );

      return sendJson(res, 400, {
        success: false,
        message: "Empty callback body.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 3. SIGNATURE
    |--------------------------------------------------------------------------
    */

    const receivedSignature =
      req.get("X-Callback-Signature") ||
      req.get("x-callback-signature") ||
      req.get("Signature");

    if (!receivedSignature) {
      logger.warn(
        "Callback ditolak: signature tidak ditemukan."
      );

      return sendJson(res, 401, {
        success: false,
        message:
          "Invalid callback signature.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 4. PRIVATE KEY
    |--------------------------------------------------------------------------
    */

    const privateKey =
      TRIPAY_PRIVATE_KEY.value();

    if (!privateKey) {
      logger.error(
        "TRIPAY_PRIVATE_KEY belum dikonfigurasi."
      );

      return sendJson(res, 500, {
        success: false,
        message:
          "Payment gateway belum dikonfigurasi.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 5. VERIFY SIGNATURE
    |--------------------------------------------------------------------------
    */

    if (
      !verifySignature(
        rawBody,
        receivedSignature,
        privateKey
      )
    ) {
      logger.warn(
        "Callback ditolak: signature tidak valid."
      );

      return sendJson(res, 401, {
        success: false,
        message:
          "Invalid callback signature.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 6. PARSE
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
    | 7. DATA
    |--------------------------------------------------------------------------
    */

    const reference =
      String(
        payload.reference || ""
      ).trim();

    const merchantRef =
      String(
        payload.merchant_ref || ""
      ).trim();

    const status =
      String(
        payload.status || ""
      )
        .trim()
        .toUpperCase();

    const totalAmount =
      toSafeInteger(
        payload.total_amount
      );

    const amountReceived =
      toSafeInteger(
        payload.amount_received
      );

    /*
    |--------------------------------------------------------------------------
    | 8. VALIDASI
    |--------------------------------------------------------------------------
    */

    if (
      !reference ||
      !merchantRef ||
      !status
    ) {
      return sendJson(res, 400, {
        success: false,
        message:
          "Callback data tidak lengkap.",
      });
    }

    if (!ALLOWED_STATUS.has(status)) {
      return sendJson(res, 400, {
        success: false,
        message:
          "Status transaksi tidak dikenal.",
      });
    }

    if (
      totalAmount === null ||
      totalAmount <= 0
    ) {
      return sendJson(res, 400, {
        success: false,
        message:
          "Nominal transaksi tidak valid.",
      });
    }

    /*
    |--------------------------------------------------------------------------
    | 9. TRANSAKSI TOP UP
    |--------------------------------------------------------------------------
    */

    const transaksiRef =
      db
        .collection("topup_transactions")
        .doc(merchantRef);

    try {
      const result =
        await db.runTransaction(
          async (transaction) => {
            const transaksiSnap =
              await transaction.get(
                transaksiRef
              );

            if (!transaksiSnap.exists) {
              throw new Error(
                "TRANSACTION_NOT_FOUND"
              );
            }

            const transaksi =
              transaksiSnap.data() || {};

            const uid =
              String(
                transaksi.uid || ""
              ).trim();

            if (!uid) {
              throw new Error(
                "TRANSACTION_UID_MISSING"
              );
            }

            const savedMerchantRef =
              String(
                transaksi.merchantRef || ""
              ).trim();

            if (
              savedMerchantRef !==
              merchantRef
            ) {
              throw new Error(
                "MERCHANT_REFERENCE_MISMATCH"
              );
            }

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

            const expectedAmount =
              toSafeInteger(
                transaksi.amount
              );

            if (
              expectedAmount === null ||
              expectedAmount <= 0
            ) {
              throw new Error(
                "INVALID_TRANSACTION_AMOUNT"
              );
            }

            if (
              expectedAmount !==
              totalAmount
            ) {
              throw new Error(
                "AMOUNT_MISMATCH"
              );
            }

            const currentStatus =
              String(
                transaksi.status ||
                  "UNPAID"
              ).toUpperCase();

            /*
            |--------------------------------------------------------------------------
            | SUDAH PAID
            |--------------------------------------------------------------------------
            */

            if (
              currentStatus === "PAID"
            ) {
              return {
                alreadyPaid: true,
                credited: false,
                uid,
              };
            }

            /*
            |--------------------------------------------------------------------------
            | NON PAID
            |--------------------------------------------------------------------------
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
                    admin.firestore
                      .FieldValue
                      .serverTimestamp(),

                  updatedAt:
                    admin.firestore
                      .FieldValue
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
            | USER
            |--------------------------------------------------------------------------
            */

            const userRef =
              db
                .collection("users")
                .doc(uid);

            const userSnap =
              await transaction.get(
                userRef
              );

            if (!userSnap.exists) {
              throw new Error(
                "USER_NOT_FOUND"
              );
            }

            const userData =
              userSnap.data() || {};

            /*
            |--------------------------------------------------------------------------
            | BALANCE
            |--------------------------------------------------------------------------
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
            | UPDATE USER
            |--------------------------------------------------------------------------
            */

            transaction.update(
              userRef,
              {
                [BALANCE_FIELD]:
                  saldoBaru,

                updatedAt:
                  admin.firestore
                    .FieldValue
                    .serverTimestamp(),
              }
            );

            /*
            |--------------------------------------------------------------------------
            | LEDGER
            |--------------------------------------------------------------------------
            */

            const ledgerRef =
              db
                .collection(
                  "balance_ledger"
                )
                .doc();

            transaction.set(
              ledgerRef,
              {
                uid,

                type: "CREDIT",

                amount:
                  expectedAmount,

                before:
                  saldoSebelumnya,

                after:
                  saldoBaru,

                reason:
                  "Top Up Saldo via TriPay",

                source:
                  "TRIPAY_CALLBACK",

                merchantRef,

                reference,

                createdAt:
                  admin.firestore
                    .FieldValue
                    .serverTimestamp(),
              }
            );

            /*
            |--------------------------------------------------------------------------
            | MUTASI SALDO
            |--------------------------------------------------------------------------
            */

            const mutasiRef =
              db
                .collection(
                  "mutasi_saldo"
                )
                .doc();

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
                  admin.firestore
                    .FieldValue
                    .serverTimestamp(),
              }
            );

            /*
            |--------------------------------------------------------------------------
            | TANDAI PAID
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
                  admin.firestore
                    .FieldValue
                    .serverTimestamp(),

                callbackReceivedAt:
                  admin.firestore
                    .FieldValue
                    .serverTimestamp(),

                updatedAt:
                  admin.firestore
                    .FieldValue
                    .serverTimestamp(),
              }
            );

            return {
              alreadyPaid: false,
              credited: true,
              uid,
              saldoAkhir: saldoBaru,
            };
          }
        );

      if (result.alreadyPaid) {
        return sendJson(res, 200, {
          success: true,
          message:
            "Transaction already processed.",
        });
      }

      if (result.credited) {
        logger.info(
          `TOP UP BERHASIL | ${merchantRef} | UID: ${result.uid} | SALDO: ${result.saldoAkhir}`
        );

        return sendJson(res, 200, {
          success: true,
        });
      }

      return sendJson(res, 200, {
        success: true,
        message:
          `Transaction status updated to ${result.status}.`,
      });
    } catch (error) {
      logger.error(
        `Gagal memproses callback ${merchantRef}`,
        error
      );

      return sendJson(res, 500, {
        success: false,
        message:
          "Callback processing failed.",
      });
    }
  }
);
