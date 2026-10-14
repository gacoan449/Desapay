"use strict";

const crypto = require("crypto");

const {
  onRequest,
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  defineSecret,
} = require("firebase-functions/params");

const logger = require("firebase-functions/logger");
const {onSchedule} = require("firebase-functions/v2/scheduler");
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

const DIGIFLAZZ_USERNAME =
  defineSecret("DIGIFLAZZ_USERNAME");

const DIGIFLAZZ_API_KEY =
  defineSecret("DIGIFLAZZ_API_KEY");

const EDPOIN_API_KEY =
  defineSecret("EDPOIN_API_KEY");

const EDPOIN_USERNAME =
  defineSecret("EDPOIN_USERNAME");

/*
|--------------------------------------------------------------------------
| KONSTANTA
|--------------------------------------------------------------------------
*/

const REGION = "asia-southeast2";

const DIGIFLAZZ_BASE_URL =
  "https://api.digiflazz.com/v1";

const EDPOIN_BASE_URL =
  "https://api.edpoin.com";

const BALANCE_FIELD = "balance";

const ALLOWED_STATUS = new Set([
  "PAID",
  "UNPAID",
  "EXPIRED",
  "FAILED",
]);

const ALLOWED_TRIPAY_EVENTS = new Set([
  "payment_status",
]);

const MAX_ADMIN_ADJUSTMENT =
  100000000;

const MAX_REQUEST_ID_LENGTH = 100;

/*
|--------------------------------------------------------------------------
| HELPER
|--------------------------------------------------------------------------
*/

function sendJson(
  res,
  statusCode,
  data
) {
  return res
    .status(statusCode)
    .json(data);
}

function toSafeInteger(value) {
  const number = Number(value);

  if (
    !Number.isSafeInteger(number)
  ) {
    return null;
  }

  return number;
}

function md5(value) {
  return crypto
    .createHash("md5")
    .update(value, "utf8")
    .digest("hex");
}

function generateRefId(uid) {
  const random =
    crypto
      .randomBytes(6)
      .toString("hex");

  return `dp-${Date.now()}-${uid.slice(
    0,
    8
  )}-${random}`;
}

function isValidRequestId(value) {
  if (
    typeof value !== "string"
  ) {
    return false;
  }

  const requestId =
    value.trim();

  if (!requestId) {
    return true;
  }

  if (
    requestId.length >
    MAX_REQUEST_ID_LENGTH
  ) {
    return false;
  }

  return /^[A-Za-z0-9_-]+$/.test(
    requestId
  );
}

function normalizeString(value) {
  return typeof value === "string"
    ? value.trim()
    : "";
}

function generateSignature(
  rawBody,
  privateKey
) {
  return crypto
    .createHmac(
      "sha256",
      privateKey
    )
    .update(rawBody, "utf8")
    .digest("hex");
}

function verifySignature(
  rawBody,
  receivedSignature,
  privateKey
) {
  if (
    !rawBody ||
    !receivedSignature ||
    !privateKey
  ) {
    return false;
  }

  try {
    const expected =
      generateSignature(
        rawBody,
        privateKey
      );

    const expectedBuffer =
      Buffer.from(
        expected,
        "hex"
      );

    const normalizedSignature =
      receivedSignature
        .trim()
        .toLowerCase();

    if (
      !/^[0-9a-f]+$/.test(
        normalizedSignature
      )
    ) {
      return false;
    }

    if (
      normalizedSignature.length !==
      64
    ) {
      return false;
    }

    const receivedBuffer =
      Buffer.from(
        normalizedSignature,
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
| DIGIFLAZZ HELPER
|--------------------------------------------------------------------------
*/

async function digiflazzRequest(
  endpoint,
  body
) {
  const response =
    await fetch(
      `${DIGIFLAZZ_BASE_URL}/${endpoint}`,
      {
        method: "POST",

        headers: {
          "Content-Type":
            "application/json",
        },

        body: JSON.stringify(body),
      }
    );

  const text =
    await response.text();

  let data;

  try {
    data =
      JSON.parse(text);
  } catch (_) {
    throw new Error(
      "Response Digiflazz bukan JSON."
    );
  }

  if (!response.ok) {
    throw new Error(
      `HTTP Digiflazz ${response.status}`
    );
  }

  return data;
}

function digiflazzCredentials() {
  const username =
    DIGIFLAZZ_USERNAME.value();

  const apiKey =
    DIGIFLAZZ_API_KEY.value();

  if (
    !username ||
    !apiKey
  ) {
    throw new Error(
      "Credential Digiflazz belum dikonfigurasi."
    );
  }

  return {
    username,
    apiKey,
  };
}

/*
|--------------------------------------------------------------------------
| EDPOIN HELPER
|--------------------------------------------------------------------------
*/

function edpoinCredentials() {
  const username =
    EDPOIN_USERNAME.value();

  const apiKey =
    EDPOIN_API_KEY.value();

  if (
    !username ||
    !apiKey
  ) {
    throw new Error(
      "Credential EDPOIN belum dikonfigurasi."
    );
  }

  return {
    username,
    apiKey,
  };
}

async function edpoinRequest(
  endpoint,
  body
) {
  const response =
    await fetch(
      `${EDPOIN_BASE_URL}/${endpoint}`,
      {
        method: "POST",

        headers: {
          "Content-Type":
            "application/json",
        },

        body: JSON.stringify(body),
      }
    );

  const text =
    await response.text();

  let data;

  try {
    data =
      JSON.parse(text);
  } catch (_) {
    throw new Error(
      "Response EDPOIN bukan JSON."
    );
  }

  if (!response.ok) {
    throw new Error(
      `HTTP EDPOIN ${response.status}`
    );
  }

  return data;
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

  const snap =
    await db
      .collection("users")
      .doc(uid)
      .get();

  if (!snap.exists) {
    return false;
  }

  const data =
    snap.data() || {};

  return data.role === "admin";
}

/*
|--------------------------------------------------------------------------
| PRODUCT PRICE TRUST
|--------------------------------------------------------------------------
*/

async function getTrustedProductPrice(
  buyerSkuCode
) {
  const sku =
    String(
      buyerSkuCode || ""
    ).trim();

  if (!sku) {
    throw new HttpsError(
      "invalid-argument",
      "SKU produk wajib diisi."
    );
  }

  if (sku.length > 100) {
    throw new HttpsError(
      "invalid-argument",
      "SKU produk terlalu panjang."
    );
  }

  const productSnap =
    await db
      .collection("products")
      .doc(sku)
      .get();

  if (!productSnap.exists) {
    throw new HttpsError(
      "not-found",
      "Produk tidak ditemukan."
    );
  }

  const product =
    productSnap.data() || {};

  if (
    product.active !== true
  ) {
    throw new HttpsError(
      "failed-precondition",
      "Produk sedang tidak tersedia."
    );
  }

  if (
    product.isTest === true
  ) {
    throw new HttpsError(
      "failed-precondition",
      "Produk test tidak dapat digunakan."
    );
  }

  let price =
    toSafeInteger(
      product.sellingPrice ??
        product.selling_price ??
        product.hargaJual ??
        product.harga_jual
    );

  if (
    price === null ||
    price <= 0
  ) {
    const cost =
      toSafeInteger(
        product.cost
      ) ?? 0;

    const margin =
      toSafeInteger(
        product.margin
      ) ?? 0;

    price =
      cost + margin;
  }

  if (
    price === null ||
    price <= 0 ||
    !Number.isSafeInteger(
      price
    )
  ) {
    throw new HttpsError(
      "failed-precondition",
      "Harga produk tidak valid."
    );
  }

  return {
    price,
    product,
  };
}

async function writeLegacyDigiflazzHistory({
  refId, uid, buyerSkuCode, productName, category, customerNo, amount, status, providerData = {},
}) {
  const historyRef = db.collection("transactions").doc(refId);
  const existing = await historyRef.get();
  const payload = {
    transactionId: refId,
    requestId: refId,
    uid,
    sku: buyerSkuCode,
    buyer_sku_code: buyerSkuCode,
    productName: productName || buyerSkuCode,
    category: category || null,
    customerNo,
    amount: toSafeInteger(amount) ?? 0,
    sellingPrice: toSafeInteger(amount) ?? 0,
    status,
    providerStatus: providerData.status || null,
    providerRc: providerData.rc || null,
    message: providerData.message || null,
    sn: providerData.sn || null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (!existing.exists) payload.createdAt = admin.firestore.FieldValue.serverTimestamp();
  await historyRef.set(payload, {merge: true});
}

/*
|--------------------------------------------------------------------------
| SALDO - DEBIT TRANSAKSI DIGIFLAZZ
|--------------------------------------------------------------------------
*/

async function debitUserBalanceForDigiflazz({
  transactionRef,
  uid,
  amount,
  buyerSkuCode,
  customerNo,
}) {
  const userRef =
    db
      .collection("users")
      .doc(uid);

  const ledgerRef =
    db
      .collection("balance_ledger")
      .doc();

  const mutasiRef =
    db
      .collection("mutasi_saldo")
      .doc();

  return db.runTransaction(
    async (transaction) => {
      const transactionSnap =
        await transaction.get(
          transactionRef
        );

      if (
        !transactionSnap.exists
      ) {
        throw new Error(
          "TRANSACTION_NOT_FOUND"
        );
      }

      const transactionData =
        transactionSnap.data() ||
        {};

      if (
        transactionData.balanceDebited ===
        true
      ) {
        return {
          alreadyDebited: true,

          saldoAkhir:
            toSafeInteger(
              transactionData.saldoAkhir
            ) ?? 0,
        };
      }

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

      const saldoSebelumnya =
        toSafeInteger(
          userData[BALANCE_FIELD]
        );

      if (
        saldoSebelumnya === null ||
        saldoSebelumnya < 0
      ) {
        throw new Error(
          "INVALID_BALANCE"
        );
      }

      if (
        !Number.isSafeInteger(
          amount
        ) ||
        amount <= 0
      ) {
        throw new Error(
          "INVALID_DEBIT_AMOUNT"
        );
      }

      if (
        saldoSebelumnya < amount
      ) {
        throw new Error(
          "INSUFFICIENT_BALANCE"
        );
      }

      const saldoBaru =
        saldoSebelumnya -
        amount;

      if (
        !Number.isSafeInteger(
          saldoBaru
        ) ||
        saldoBaru < 0
      ) {
        throw new Error(
          "BALANCE_OVERFLOW"
        );
      }

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

      transaction.set(
        ledgerRef,
        {
          uid,

          type:
            "DEBIT",

          amount,

          before:
            saldoSebelumnya,

          after:
            saldoBaru,

          reason:
            `Pembelian ${buyerSkuCode} ke ${customerNo}`,

          source:
            "DIGIFLAZZ",

          transactionId:
            transactionRef.id,

          createdAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );

      transaction.set(
        mutasiRef,
        {
          uid,

          tipe:
            "KELUAR",

          nominal:
            amount,

          saldoAwal:
            saldoSebelumnya,

          saldoAkhir:
            saldoBaru,

          keterangan:
            `Pembelian ${buyerSkuCode} ke ${customerNo}`,

          sumber:
            "DIGIFLAZZ",

          transactionId:
            transactionRef.id,

          waktu:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );

      transaction.update(
        transactionRef,
        {
          balanceDebited:
            true,

          balanceRefunded:
            false,

          amount,

          saldoAwal:
            saldoSebelumnya,

          saldoAkhir:
            saldoBaru,

          debitLedgerId:
            ledgerRef.id,

          debitMutasiId:
            mutasiRef.id,

          updatedAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );

      return {
        alreadyDebited:
          false,

        saldoAkhir:
          saldoBaru,
      };
    }
  );
}

/*
|--------------------------------------------------------------------------
| SALDO - REFUND DIGIFLAZZ
|--------------------------------------------------------------------------
*/

async function refundDigiflazzBalance({
  transactionRef,
  reason,
}) {
  const ledgerRef =
    db
      .collection("balance_ledger")
      .doc();

  const mutasiRef =
    db
      .collection("mutasi_saldo")
      .doc();

  return db.runTransaction(
    async (transaction) => {
      const transactionSnap =
        await transaction.get(
          transactionRef
        );

      if (
        !transactionSnap.exists
      ) {
        throw new Error(
          "TRANSACTION_NOT_FOUND"
        );
      }

      const trx =
        transactionSnap.data() ||
        {};

      /*
      |------------------------------------------------------------
      | SUCCESS ADALAH TERMINAL STATE
      |------------------------------------------------------------
      |
      | Jangan pernah refund transaksi yang sudah dinyatakan
      | SUCCESS oleh sistem lokal.
      |
      */

      if (
        String(
          trx.status || ""
        )
          .trim()
          .toUpperCase() ===
        "SUCCESS"
      ) {
        return {
          refunded:
            false,

          reason:
            "TRANSACTION_ALREADY_SUCCESS",

          saldoAkhir:
            toSafeInteger(
              trx.saldoAkhir
            ) ?? 0,
        };
      }

      if (
        trx.balanceDebited !== true
      ) {
        return {
          refunded:
            false,

          reason:
            "BALANCE_NOT_DEBITED",
        };
      }

      if (
        trx.balanceRefunded === true
      ) {
        return {
          refunded:
            false,

          reason:
            "ALREADY_REFUNDED",

          saldoAkhir:
            toSafeInteger(
              trx.refundSaldoAkhir ??
                trx.saldoAkhir
            ) ?? 0,
        };
      }

      const uid =
        normalizeString(
          trx.uid
        );

      const amount =
        toSafeInteger(
          trx.amount
        );

      if (!uid) {
        throw new Error(
          "TRANSACTION_UID_MISSING"
        );
      }

      if (
        amount === null ||
        amount <= 0
      ) {
        throw new Error(
          "INVALID_REFUND_AMOUNT"
        );
      }

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

      const saldoSebelumnya =
        toSafeInteger(
          userData[BALANCE_FIELD]
        );

      if (
        saldoSebelumnya === null ||
        saldoSebelumnya < 0
      ) {
        throw new Error(
          "INVALID_BALANCE"
        );
      }

      const saldoBaru =
        saldoSebelumnya +
        amount;

      if (
        !Number.isSafeInteger(
          saldoBaru
        )
      ) {
        throw new Error(
          "BALANCE_OVERFLOW"
        );
      }

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

      transaction.set(
        ledgerRef,
        {
          uid,

          type:
            "CREDIT",

          amount,

          before:
            saldoSebelumnya,

          after:
            saldoBaru,

          reason:
            reason ||
            "Refund transaksi Digiflazz",

          source:
            "DIGIFLAZZ_REFUND",

          transactionId:
            transactionRef.id,

          createdAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );

      transaction.set(
        mutasiRef,
        {
          uid,

          tipe:
            "MASUK",

          nominal:
            amount,

          saldoAwal:
            saldoSebelumnya,

          saldoAkhir:
            saldoBaru,

          keterangan:
            reason ||
            "Refund transaksi Digiflazz",

          sumber:
            "DIGIFLAZZ_REFUND",

          transactionId:
            transactionRef.id,

          waktu:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );

      transaction.update(
        transactionRef,
        {
          balanceRefunded:
            true,

          refundAmount:
            amount,

          refundSaldoAwal:
            saldoSebelumnya,

          refundSaldoAkhir:
            saldoBaru,

          refundLedgerId:
            ledgerRef.id,

          refundMutasiId:
            mutasiRef.id,

          refundedAt:
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
        refunded:
          true,

        saldoAkhir:
          saldoBaru,
      };
    }
  );
}

/*
|--------------------------------------------------------------------------
| ADMIN UBAH SALDO
|--------------------------------------------------------------------------
*/

exports.adminAdjustBalance =
  onCall(
    {
      region: REGION,
      timeoutSeconds: 30,
      memory: "256MiB",
    },

    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "Admin harus login."
        );
      }

      const adminUid =
        request.auth.uid;

      if (
        !(await checkAdmin(
          adminUid
        ))
      ) {
        throw new HttpsError(
          "permission-denied",
          "Akses hanya untuk admin."
        );
      }

      const data =
        request.data || {};

      const uid =
        normalizeString(
          data.uid
        );

      const alasan =
        typeof data.alasan === "string"
          ? data.alasan.trim()
          : typeof data.reason === "string"
              ? data.reason.trim()
              : "";

      const amount =
        toSafeInteger(
          data.amount
        );

      if (!uid) {
        throw new HttpsError(
          "invalid-argument",
          "UID user wajib diisi."
        );
      }

      if (uid.length > 128) {
        throw new HttpsError(
          "invalid-argument",
          "UID user tidak valid."
        );
      }

      if (!alasan) {
        throw new HttpsError(
          "invalid-argument",
          "Alasan perubahan saldo wajib diisi."
        );
      }

      if (
        alasan.length > 500
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Alasan perubahan saldo terlalu panjang."
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

      if (
        Math.abs(amount) >
        MAX_ADMIN_ADJUSTMENT
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Nominal perubahan saldo terlalu besar."
        );
      }

      const userRef =
        db
          .collection("users")
          .doc(uid);

      try {
        const result =
          await db.runTransaction(
            async (transaction) => {
              const userSnap =
                await transaction.get(
                  userRef
                );

              if (
                !userSnap.exists
              ) {
                throw new Error(
                  "USER_NOT_FOUND"
                );
              }

              const userData =
                userSnap.data() || {};

              const before =
                toSafeInteger(
                  userData[
                    BALANCE_FIELD
                  ]
                );

              if (
                before === null ||
                before < 0
              ) {
                throw new Error(
                  "INVALID_BALANCE"
                );
              }

              const after =
                before + amount;

              if (
                !Number.isSafeInteger(
                  after
                )
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

              transaction.update(
                userRef,
                {
                  [BALANCE_FIELD]:
                    after,

                  updatedAt:
                    admin.firestore
                      .FieldValue
                      .serverTimestamp(),
                }
              );

              const ledgerRef =
                db
                  .collection(
                    "balance_ledger"
                  )
                  .doc();

              const mutasiRef =
                db
                  .collection(
                    "mutasi_saldo"
                  )
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
                    Math.abs(
                      amount
                    ),

                  before,

                  after,

                  reason:
                    alasan,

                  source:
                    "ADMIN",

                  adminUid,

                  createdAt:
                    admin.firestore
                      .FieldValue
                      .serverTimestamp(),
                }
              );

              transaction.set(
                mutasiRef,
                {
                  uid,

                  tipe:
                    amount > 0
                      ? "MASUK"
                      : "KELUAR",

                  nominal:
                    Math.abs(
                      amount
                    ),

                  saldoAwal:
                    before,

                  saldoAkhir:
                    after,

                  keterangan:
                    alasan,

                  sumber:
                    "ADMIN",

                  adminUid,

                  waktu:
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

                ledgerId:
                  ledgerRef.id,

                mutasiId:
                  mutasiRef.id,
              };
            }
          );

        return {
          success:
            true,

          ...result,
        };
      } catch (error) {
        logger.error(
          "ADMIN SALDO GAGAL",
          error
        );

        switch (
          error.message
        ) {
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
| DIGIFLAZZ - PRICE LIST
|--------------------------------------------------------------------------
*/

exports.digiflazzPriceList =
  onCall(
    {
      region: REGION,
      timeoutSeconds: 60,
      memory: "256MiB",
      secrets: [
        DIGIFLAZZ_USERNAME,
        DIGIFLAZZ_API_KEY,
      ],
    },

    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "Harus login."
        );
      }

      if (
        !(await checkAdmin(
          request.auth.uid
        ))
      ) {
        throw new HttpsError(
          "permission-denied",
          "Hanya admin."
        );
      }

      try {
        const {
          username,
          apiKey,
        } =
          digiflazzCredentials();

        return await digiflazzRequest(
          "price-list",
          {
            cmd:
              "prepaid",

            username,

            sign:
              md5(
                username +
                  apiKey +
                  "pricelist"
              ),
          }
        );
      } catch (error) {
        logger.error(
          "DIGIFLAZZ PRICE LIST GAGAL",
          error
        );

        throw new HttpsError(
          "internal",
          "Gagal mengambil daftar produk."
        );
      }
    }
  );

/*
|--------------------------------------------------------------------------
| DIGIFLAZZ - CEK SALDO MODAL
|--------------------------------------------------------------------------
*/

exports.digiflazzCekSaldo =
  onCall(
    {
      region: REGION,
      timeoutSeconds: 30,
      memory: "256MiB",
      secrets: [
        DIGIFLAZZ_USERNAME,
        DIGIFLAZZ_API_KEY,
      ],
    },

    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "Harus login."
        );
      }

      if (
        !(await checkAdmin(
          request.auth.uid
        ))
      ) {
        throw new HttpsError(
          "permission-denied",
          "Hanya admin."
        );
      }

      try {
        const {
          username,
          apiKey,
        } =
          digiflazzCredentials();

        return await digiflazzRequest(
          "cek-saldo",
          {
            cmd:
              "deposit",

            username,

            sign:
              md5(
                username +
                  apiKey +
                  "depo"
              ),
          }
        );
      } catch (error) {
        logger.error(
          "DIGIFLAZZ CEK SALDO GAGAL",
          error
        );

        throw new HttpsError(
          "internal",
          "Gagal mengambil saldo Digiflazz."
        );
      }
    }
  );

/*
|--------------------------------------------------------------------------
| DIGIFLAZZ - KIRIM TRANSAKSI
|--------------------------------------------------------------------------
*/

exports.digiflazzKirimTransaksi =
  onCall(
    {
      region: REGION,
      timeoutSeconds: 90,
      memory: "256MiB",
      secrets: [
        DIGIFLAZZ_USERNAME,
        DIGIFLAZZ_API_KEY,
      ],
    },

    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "Harus login."
        );
      }

      const uid =
        request.auth.uid;

      const data =
        request.data || {};

      const buyerSkuCode =
        normalizeString(
          data.buyer_sku_code
        );

      const customerNo =
        normalizeString(
          data.customer_no
        );

      const requestId =
        normalizeString(
          data.request_id
        );

      if (
        !buyerSkuCode ||
        !customerNo
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Kode produk dan nomor pelanggan wajib diisi."
        );
      }

      if (
        buyerSkuCode.length >
          100 ||
        customerNo.length >
          100
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Input transaksi tidak valid."
        );
      }

      if (
        !isValidRequestId(
          requestId
        )
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Request ID tidak valid."
        );
      }

      try {
        const {
          price,
          product,
        } =
          await getTrustedProductPrice(
            buyerSkuCode
          );

        const refId =
          requestId
            ? `dp-${uid.slice(
                0,
                8
              )}-${requestId}`
            : generateRefId(
                uid
              );

        if (
          refId.length >
          180
        ) {
          throw new HttpsError(
            "invalid-argument",
            "Referensi transaksi terlalu panjang."
          );
        }

        const transaksiRef =
          db
            .collection(
              "digiflazz_transactions"
            )
            .doc(refId);

        const existingSnap =
          await transaksiRef.get();

        if (
          existingSnap.exists
        ) {
          const existing =
            existingSnap.data() ||
            {};

          if (
            existing.uid !==
            uid
          ) {
            throw new HttpsError(
              "permission-denied",
              "Transaksi tidak dapat diakses."
            );
          }

          const existingSku =
            normalizeString(
              existing.buyerSkuCode
            );

          const existingCustomerNo =
            normalizeString(
              existing.customerNo
            );

          const existingAmount =
            toSafeInteger(
              existing.amount
            );

          if (
            existingSku !==
              buyerSkuCode ||
            existingCustomerNo !==
              customerNo ||
            existingAmount !==
              price
          ) {
            throw new HttpsError(
              "already-exists",
              "Request ID sudah digunakan untuk transaksi berbeda."
            );
          }

          return {
            success:
              existing.status !==
              "FAILED",

            ref_id:
              refId,

            status:
              existing.status ||
              "PROCESSING",

            response:
              existing.response ||
              null,

            amount:
              existingAmount ??
              price,

            saldoAkhir:
              existing.saldoAkhir ??
              null,

            balanceDebited:
              existing.balanceDebited ===
              true,

            balanceRefunded:
              existing.balanceRefunded ===
              true,

            reused:
              true,
          };
        }

        const pinAuthorizationId =
          normalizeString(data.pin_authorization_id);

        if (!/^[a-f0-9]{64}$/i.test(pinAuthorizationId)) {
          throw new HttpsError(
            "failed-precondition",
            "Otorisasi PIN wajib untuk setiap pembelian."
          );
        }

        const pinAuthorizationRef =
          db.collection("pin_authorizations").doc(pinAuthorizationId);

        await db.runTransaction(async (transaction) => {
          const authorizationSnap = await transaction.get(pinAuthorizationRef);
          if (!authorizationSnap.exists) {
            throw new HttpsError("permission-denied", "Otorisasi PIN tidak valid.");
          }
          const authorization = authorizationSnap.data() || {};
          const expiresAt = authorization.expiresAt &&
            typeof authorization.expiresAt.toMillis === "function"
            ? authorization.expiresAt.toMillis()
            : 0;
          if (authorization.uid !== uid ||
              authorization.requestId !== requestId ||
              authorization.sku !== buyerSkuCode ||
              authorization.customerNo !== customerNo ||
              authorization.consumed === true ||
              expiresAt < Date.now()) {
            throw new HttpsError("permission-denied", "Otorisasi PIN tidak valid atau kedaluwarsa.");
          }
          transaction.update(pinAuthorizationRef, {
            consumed: true,
            consumedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        await transaksiRef.create(
          {
            uid,

            refId,

            buyerSkuCode,

            customerNo,

            productName:
              product.name ||
              product.nama ||
              "-",

            amount:
              price,

            status:
              "CREATED",

            balanceDebited:
              false,

            balanceRefunded:
              false,

            createdAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),

            updatedAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),
          }
        );

        await writeLegacyDigiflazzHistory({
          refId, uid, buyerSkuCode,
          productName: product.name || product.nama || buyerSkuCode,
          category: product.category || null,
          customerNo, amount: price, status: "PROCESSING",
        });

        try {
          await debitUserBalanceForDigiflazz(
            {
              transactionRef:
                transaksiRef,

              uid,

              amount:
                price,

              buyerSkuCode,

              customerNo,
            }
          );
        } catch (error) {
          await transaksiRef.set(
            {
              status:
                "FAILED",

              failureReason:
                error.message,

              updatedAt:
                admin.firestore
                  .FieldValue
                  .serverTimestamp(),
            },
            {
              merge:
                true,
            }
          );

          await writeLegacyDigiflazzHistory({
            refId, uid, buyerSkuCode,
            productName: product.name || product.nama || buyerSkuCode,
            category: product.category || null,
            customerNo, amount: price, status: "FAILED",
            providerData: {status: "Gagal", rc: error.message, message: "Transaksi tidak dapat didebit"},
          });

          switch (
            error.message
          ) {
            case "USER_NOT_FOUND":
              throw new HttpsError(
                "not-found",
                "Akun pengguna tidak ditemukan."
              );

            case "ACCOUNT_DISABLED":
              throw new HttpsError(
                "permission-denied",
                "Akun dinonaktifkan dan tidak dapat melakukan transaksi."
              );

            case "INVALID_BALANCE":
              throw new HttpsError(
                "failed-precondition",
                "Saldo pengguna tidak valid."
              );

            case "INSUFFICIENT_BALANCE":
              throw new HttpsError(
                "failed-precondition",
                "Saldo DesaPay tidak mencukupi."
              );

            case "INVALID_DEBIT_AMOUNT":
              throw new HttpsError(
                "failed-precondition",
                "Nominal transaksi tidak valid."
              );

            default:
              throw new HttpsError(
                "internal",
                "Gagal mengamankan saldo transaksi."
              );
          }
        }

        await transaksiRef.set(
          {
            status:
              "PROCESSING",

            updatedAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),
          },
          {
            merge:
              true,
          }
        );

        const {
          username,
          apiKey,
        } =
          digiflazzCredentials();

        const result =
          await digiflazzRequest(
            "transaction",
            {
              username,

              buyer_sku_code:
                buyerSkuCode,

              customer_no:
                customerNo,

              ref_id:
                refId,

              sign:
                md5(
                  username +
                    apiKey +
                    refId
                ),
            }
          );

        const resultData =
          result.data || {};

        const providerStatus =
          String(
            resultData.status ||
              ""
          )
            .trim()
            .toUpperCase();

        if (
          providerStatus ===
          "SUKSES"
        ) {
          await transaksiRef.set(
            {
              status:
                "SUCCESS",

              response:
                resultData,

              providerReference:
                resultData.ref_id ||
                resultData.sn ||
                resultData.reference ||
                null,

              completedAt:
                admin.firestore
                  .FieldValue
                  .serverTimestamp(),

              updatedAt:
                admin.firestore
                  .FieldValue
                  .serverTimestamp(),
            },
            {
              merge:
                true,
            }
          );

          await writeLegacyDigiflazzHistory({
            refId, uid, buyerSkuCode,
            productName: product.name || product.nama || buyerSkuCode,
            category: product.category || null,
            customerNo, amount: price, status: "SUCCESS", providerData: resultData,
          });

          return {
            success:
              true,

            ref_id:
              refId,

            status:
              "SUCCESS",

            response:
              resultData,
          };
        }

        if (
          providerStatus ===
          "GAGAL"
        ) {
          const refund =
            await refundDigiflazzBalance(
              {
                transactionRef:
                  transaksiRef,

                reason:
                  `Refund transaksi Digiflazz: ${
                    resultData.message ||
                    "Provider menyatakan gagal."
                  }`,
              }
            );

          await transaksiRef.set(
            {
              status:
                "FAILED",

              response:
                resultData,

              failureReason:
                resultData.message ||
                "Transaksi Digiflazz gagal.",

              refunded:
                refund.refunded ===
                  true ||
                refund.reason ===
                  "ALREADY_REFUNDED",

              updatedAt:
                admin.firestore
                  .FieldValue
                  .serverTimestamp(),
            },
            {
              merge:
                true,
            }
          );

          await writeLegacyDigiflazzHistory({
            refId, uid, buyerSkuCode,
            productName: product.name || product.nama || buyerSkuCode,
            category: product.category || null,
            customerNo, amount: price, status: "FAILED", providerData: resultData,
          });

          return {
            success:
              false,

            ref_id:
              refId,

            status:
              "FAILED",

            refunded:
              refund.refunded ===
                true ||
              refund.reason ===
                "ALREADY_REFUNDED",

            message:
              resultData.message ||
              "Transaksi gagal dan saldo telah dikembalikan.",

            response:
              resultData,
          };
        }

        await transaksiRef.set(
          {
            status:
              "PENDING",

            response:
              resultData,

            updatedAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),
          },
          {
            merge:
              true,
          }
        );

        await writeLegacyDigiflazzHistory({
          refId, uid, buyerSkuCode,
          productName: product.name || product.nama || buyerSkuCode,
          category: product.category || null,
          customerNo, amount: price, status: "PENDING", providerData: resultData,
        });

        return {
          success:
            true,

          ref_id:
            refId,

          status:
            "PENDING",

          response:
            resultData,
        };
      } catch (error) {
        if (
          error instanceof
          HttpsError
        ) {
          throw error;
        }

        logger.error(
          "DIGIFLAZZ TRANSAKSI GAGAL",
          error
        );

        throw new HttpsError(
          "internal",
          "Transaksi sedang diproses atau gagal terhubung ke provider."
        );
      }
    }
  );

/*
|--------------------------------------------------------------------------
| DIGIFLAZZ - CEK STATUS PREPAID
|--------------------------------------------------------------------------
*/

exports.digiflazzCekTransaksi =
  onCall(
    {
      region: REGION,
      timeoutSeconds: 60,
      memory: "256MiB",
      secrets: [
        DIGIFLAZZ_USERNAME,
        DIGIFLAZZ_API_KEY,
      ],
    },

    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "Harus login."
        );
      }

      const refId =
        normalizeString(
          request.data?.ref_id
        );

      if (!refId) {
        throw new HttpsError(
          "invalid-argument",
          "Ref ID wajib diisi."
        );
      }

      if (
        refId.length > 180
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Ref ID tidak valid."
        );
      }

      try {
        const transaksiRef =
          db
            .collection(
              "digiflazz_transactions"
            )
            .doc(refId);

        const transaksiSnap =
          await transaksiRef.get();

        if (
          !transaksiSnap.exists
        ) {
          throw new HttpsError(
            "not-found",
            "Transaksi tidak ditemukan."
          );
        }

        const transaksi =
          transaksiSnap.data() ||
          {};

        const isAdmin =
          await checkAdmin(
            request.auth.uid
          );

        if (
          transaksi.uid !==
            request.auth.uid &&
          !isAdmin
        ) {
          throw new HttpsError(
            "permission-denied",
            "Tidak memiliki akses transaksi ini."
          );
        }

        /*
        |----------------------------------------------------------
        | TERMINAL STATE LOKAL
        |----------------------------------------------------------
        |
        | Kalau sudah SUCCESS atau sudah FAILED + refund,
        | jangan melakukan perubahan finansial ulang.
        |
        */

        const currentStatus = String(transaksi.status || "")
          .trim().toUpperCase();
        if (currentStatus === "SUCCESS" || currentStatus === "FAILED" ||
            currentStatus === "REFUND_PENDING") {
          return {
            success: currentStatus === "SUCCESS",
            ref_id: refId,
            status: currentStatus,
            response: transaksi.response || null,
            refunded: transaksi.balanceRefunded === true,
            reused: true,
          };
        }

        const buyerSkuCode =
          normalizeString(
            transaksi.buyerSkuCode
          );

        const customerNo =
          normalizeString(
            transaksi.customerNo
          );

        if (
          !buyerSkuCode ||
          !customerNo
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Data transaksi tidak lengkap."
          );
        }

        const {
          username,
          apiKey,
        } =
          digiflazzCredentials();

        const result =
          await digiflazzRequest(
            "transaction",
            {
              cmd: "status",

              username,

              buyer_sku_code:
                buyerSkuCode,

              customer_no:
                customerNo,

              ref_id:
                refId,

              sign:
                md5(
                  username +
                    apiKey +
                    "status" +
                    refId
                ),
            }
          );

        const resultData =
          result.data || {};

        const providerStatus =
          String(
            resultData.status ||
              ""
          )
            .trim()
            .toUpperCase();

        if (providerStatus === "SUKSES" || providerStatus === "SUCCESS") {
          let transitioned = false;
          await db.runTransaction(async (transaction) => {
            transitioned = false;
            const latest = await transaction.get(transaksiRef);
            if (!latest.exists) return;
            const current = latest.data() || {};
            const currentStatus = normalizeString(current.status).toUpperCase();
            if (["SUCCESS", "FAILED", "REFUND_PENDING"].includes(currentStatus)) return;
            transaction.update(transaksiRef, {
              status: "SUCCESS",
              response: resultData,
              completedAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            transitioned = true;
          });
          const latest = await transaksiRef.get();
          const finalData = latest.data() || {};
          if (finalData.status === "SUCCESS") {
            await writeLegacyDigiflazzHistory({
              refId, uid: transaksi.uid, buyerSkuCode,
              productName: transaksi.productName || buyerSkuCode,
              category: transaksi.category || null,
              customerNo, amount: transaksi.amount, status: "SUCCESS", providerData: resultData,
            });
          }
          return {
            success: finalData.status === "SUCCESS",
            ref_id: refId,
            status: finalData.status || "PROCESSING",
            response: finalData.response || resultData,
            reused: !transitioned,
          };
        }

        if (providerStatus === "GAGAL" || providerStatus === "FAILED") {
          let claimed = false;
          await db.runTransaction(async (transaction) => {
            claimed = false;
            const latest = await transaction.get(transaksiRef);
            if (!latest.exists) return;
            const current = latest.data() || {};
            const currentStatus = normalizeString(current.status).toUpperCase();
            if (["SUCCESS", "FAILED", "REFUND_PENDING"].includes(currentStatus)) return;
            transaction.update(transaksiRef, {
              status: current.balanceDebited === true && current.balanceRefunded !== true
                ? "REFUND_PENDING" : "FAILED",
              response: resultData,
              failureReason: resultData.message || "Provider menyatakan transaksi gagal.",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            claimed = true;
          });
          if (!claimed) {
            const latest = await transaksiRef.get();
            const finalData = latest.data() || {};
            return {
              success: finalData.status === "SUCCESS",
              ref_id: refId,
              status: finalData.status || "PROCESSING",
              response: finalData.response || resultData,
              refunded: finalData.balanceRefunded === true,
              reused: true,
            };
          }

          const refund = await refundDigiflazzBalance({
            transactionRef: transaksiRef,
            reason: `Refund transaksi Digiflazz: ${resultData.message || "Provider menyatakan gagal."}`,
          });
          await transaksiRef.update({
            status: "FAILED",
            refunded: refund.refunded === true || refund.reason === "ALREADY_REFUNDED" ||
              refund.reason === "BALANCE_NOT_DEBITED",
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          await writeLegacyDigiflazzHistory({
            refId, uid: transaksi.uid, buyerSkuCode,
            productName: transaksi.productName || buyerSkuCode,
            category: transaksi.category || null,
            customerNo, amount: transaksi.amount, status: "FAILED", providerData: resultData,
          });
          return {
            success: false,
            ref_id: refId,
            status: "FAILED",
            refunded: refund.refunded === true || refund.reason === "ALREADY_REFUNDED",
            response: resultData,
          };
        }

        await transaksiRef.set(
          {
            status:
              "PENDING",

            response:
              resultData,

            updatedAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),
          },
          {
            merge:
              true,
          }
        );
        await writeLegacyDigiflazzHistory({
          refId, uid: transaksi.uid, buyerSkuCode,
          productName: transaksi.productName || buyerSkuCode,
          category: transaksi.category || null,
          customerNo, amount: transaksi.amount, status: "PENDING", providerData: resultData,
        });

        return {
          success:
            true,

          ref_id:
            refId,

          status:
            "PENDING",

          response:
            resultData,
        };
      } catch (error) {
        if (
          error instanceof
          HttpsError
        ) {
          throw error;
        }

        logger.error(
          "DIGIFLAZZ CEK STATUS GAGAL",
          error
        );

        throw new HttpsError(
          "internal",
          "Gagal mengecek status transaksi."
        );
      }
    }
  );

exports.reconcileLegacyDigiflazzTransactions = onSchedule(
  {
    schedule: "every 5 minutes",
    region: REGION,
    timeZone: "Asia/Jakarta",
    timeoutSeconds: 300,
    memory: "256MiB",
    secrets: [DIGIFLAZZ_USERNAME, DIGIFLAZZ_API_KEY],
  },
  async () => {
    const snapshot = await db.collection("digiflazz_transactions")
      .where("status", "in", ["PROCESSING", "PENDING", "REFUND_PENDING"])
      .limit(100).get();
    for (const doc of snapshot.docs) {
      const ref = doc.ref;
      const data = doc.data() || {};
      const status = normalizeString(data.status).toUpperCase();
      try {
        if (status === "REFUND_PENDING") {
          await refundDigiflazzBalance({transactionRef: ref, reason: "Percobaan ulang refund otomatis"});
          const latest = await ref.get();
          if (latest.exists && (latest.data() || {}).status !== "SUCCESS") {
            await ref.update({status: "FAILED", refunded: true, updatedAt: admin.firestore.FieldValue.serverTimestamp()});
          }
          continue;
        }
        const updatedAt = data.updatedAt && typeof data.updatedAt.toMillis === "function"
          ? data.updatedAt.toMillis()
          : (data.createdAt && typeof data.createdAt.toMillis === "function" ? data.createdAt.toMillis() : 0);
        if (!updatedAt || Date.now() - updatedAt < 5 * 60 * 1000) continue;
        const refId = normalizeString(data.refId);
        const sku = normalizeString(data.buyerSkuCode);
        const customerNo = normalizeString(data.customerNo);
        if (!refId || !sku || !customerNo) continue;

        const {username, apiKey} = digiflazzCredentials();
        const result = await digiflazzRequest("transaction", {
          cmd: "status",
          username,
          buyer_sku_code: sku,
          customer_no: customerNo,
          ref_id: refId,
          sign: md5(username + apiKey + "status" + refId),
        });
        const provider = result.data || {};
        const providerStatus = normalizeString(provider.status).toUpperCase();

        if (providerStatus === "SUKSES" || providerStatus === "SUCCESS") {
          let transitioned = false;
          await db.runTransaction(async (tx) => {
            transitioned = false;
            const latest = await tx.get(ref);
            if (!latest.exists) return;
            const current = latest.data() || {};
            const currentStatus = normalizeString(current.status).toUpperCase();
            if (["SUCCESS", "FAILED", "REFUND_PENDING"].includes(currentStatus)) return;
            tx.update(ref, {
              status: "SUCCESS",
              response: provider,
              completedAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            transitioned = true;
          });
          if (transitioned) await notifyAdminTransactionStatus(refId, "SUCCESS");
        } else if (providerStatus === "GAGAL" || providerStatus === "FAILED") {
          let claimed = false;
          await db.runTransaction(async (tx) => {
            claimed = false;
            const latest = await tx.get(ref);
            if (!latest.exists) return;
            const current = latest.data() || {};
            const currentStatus = normalizeString(current.status).toUpperCase();
            if (["SUCCESS", "FAILED", "REFUND_PENDING"].includes(currentStatus)) return;
            tx.update(ref, {
              status: current.balanceDebited === true && current.balanceRefunded !== true ? "REFUND_PENDING" : "FAILED",
              response: provider,
              failureReason: provider.message || "Provider menyatakan transaksi gagal",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            claimed = true;
          });
          if (claimed) {
            await refundDigiflazzBalance({transactionRef: ref, reason: provider.message || "Provider menyatakan transaksi gagal"});
            const latest = await ref.get();
            if (latest.exists && (latest.data() || {}).status !== "SUCCESS") {
              await ref.update({status: "FAILED", refunded: true, completedAt: admin.firestore.FieldValue.serverTimestamp(), updatedAt: admin.firestore.FieldValue.serverTimestamp()});
            }
          }
        } else {
          await ref.update({
            lastReconciledAt: admin.firestore.FieldValue.serverTimestamp(),
            response: provider,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      } catch (error) {
        logger.error("Rekonsiliasi transaksi Digiflazz gagal", {transactionId: doc.id, message: error.message});
      }
    }
  }
);

async function notifyAdminTransactionStatus(transactionId, status) {
  // Status transaksi sudah tersimpan; tidak membuat perubahan saldo di sini.
  logger.info("Status transaksi Digiflazz direkonsiliasi", {transactionId, status});
}

/*
|--------------------------------------------------------------------------
| DIGIFLAZZ - MINTA TIKET DEPOSIT
|--------------------------------------------------------------------------
*/

exports.digiflazzMintaDeposit =
  onCall(
    {
      region: REGION,
      timeoutSeconds: 60,
      memory: "256MiB",
      secrets: [
        DIGIFLAZZ_USERNAME,
        DIGIFLAZZ_API_KEY,
      ],
    },

    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "Harus login."
        );
      }

      if (
        !(await checkAdmin(
          request.auth.uid
        ))
      ) {
        throw new HttpsError(
          "permission-denied",
          "Hanya admin."
        );
      }

      const data =
        request.data || {};

      const amount =
        toSafeInteger(
          data.amount
        );

      const bank =
        normalizeString(
          data.Bank
        );

      const ownerName =
        normalizeString(
          data.owner_name
        );

      if (
        amount === null ||
        amount <= 0
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Nominal deposit tidak valid."
        );
      }

      if (
        !bank ||
        !ownerName
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Bank dan nama pemilik wajib diisi."
        );
      }

      if (
        bank.length > 100 ||
        ownerName.length > 150
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Data deposit terlalu panjang."
        );
      }

      try {
        const {
          username,
          apiKey,
        } =
          digiflazzCredentials();

        const result =
          await digiflazzRequest(
            "deposit",
            {
              username,

              amount,

              Bank:
                bank,

              owner_name:
                ownerName,

              sign:
                md5(
                  username +
                    apiKey +
                    "deposit"
                ),
            }
          );

        await db
          .collection(
            "digiflazz_deposits"
          )
          .add(
            {
              adminUid:
                request.auth.uid,

              amount,

              bank,

              ownerName,

              response:
                result.data || {},

              createdAt:
                admin.firestore
                  .FieldValue
                  .serverTimestamp(),
            }
          );

        return result;
      } catch (error) {
        logger.error(
          "DIGIFLAZZ DEPOSIT GAGAL",
          error
        );

        throw new HttpsError(
          "internal",
          "Gagal membuat tiket deposit."
        );
      }
    }
  );

/*
|--------------------------------------------------------------------------
| TRIPAY CALLBACK
|--------------------------------------------------------------------------
*/

exports.tripayCallback =
  onRequest(
    {
      region: REGION,
      secrets: [
        TRIPAY_PRIVATE_KEY,
      ],
      cors: false,
      timeoutSeconds: 30,
      memory: "256MiB",
    },

    async (req, res) => {
      if (
        req.method !==
        "POST"
      ) {
        return sendJson(
          res,
          405,
          {
            success:
              false,

            message:
              "Method Not Allowed",
          }
        );
      }

      /*
      |------------------------------------------------------------
      | RAW BODY
      |------------------------------------------------------------
      |
      | Signature TriPay dihitung dari JSON callback asli.
      | Karena itu rawBody harus dipertahankan.
      |
      */

      if (
        !Buffer.isBuffer(
          req.rawBody
        )
      ) {
        logger.error(
          "TRIPAY CALLBACK RAW BODY TIDAK TERSEDIA"
        );

        return sendJson(
          res,
          500,
          {
            success:
              false,

            message:
              "Raw callback body tidak tersedia.",
          }
        );
      }

      const rawBody =
        req.rawBody.toString(
          "utf8"
        );

      if (
        !rawBody.trim()
      ) {
        return sendJson(
          res,
          400,
          {
            success:
              false,

            message:
              "Empty callback body.",
          }
        );
      }

      /*
      |------------------------------------------------------------
      | CALLBACK SIGNATURE
      |------------------------------------------------------------
      */

      const receivedSignature =
        req.get(
          "X-Callback-Signature"
        ) ||
        req.get(
          "x-callback-signature"
        ) ||
        req.get(
          "Signature"
        );

      if (
        !receivedSignature
      ) {
        return sendJson(
          res,
          401,
          {
            success:
              false,

            message:
              "Invalid callback signature.",
          }
        );
      }

      const privateKey =
        TRIPAY_PRIVATE_KEY.value();

      if (!privateKey) {
        return sendJson(
          res,
          500,
          {
            success:
              false,

            message:
              "Payment gateway belum dikonfigurasi.",
          }
        );
      }

      if (
        !verifySignature(
          rawBody,
          receivedSignature,
          privateKey
        )
      ) {
        return sendJson(
          res,
          401,
          {
            success:
              false,

            message:
              "Invalid callback signature.",
          }
        );
      }

      /*
      |------------------------------------------------------------
      | PARSE JSON
      |------------------------------------------------------------
      */

      let payload;

      try {
        payload =
          JSON.parse(
            rawBody
          );
      } catch (_) {
        return sendJson(
          res,
          400,
          {
            success:
              false,

            message:
              "Invalid JSON.",
          }
        );
      }

      /*
      |------------------------------------------------------------
      | CALLBACK EVENT
      |------------------------------------------------------------
      |
      | TriPay callback payment menggunakan:
      | X-Callback-Event: payment_status
      |
      */

      const callbackEvent =
        String(
          req.get(
            "X-Callback-Event"
          ) ||
            req.get(
              "x-callback-event"
            ) ||
            ""
        )
          .trim()
          .toLowerCase();

      if (
        !ALLOWED_TRIPAY_EVENTS.has(
          callbackEvent
        )
      ) {
        return sendJson(
          res,
          400,
          {
            success:
              false,

            message:
              "Callback event tidak dikenal.",
          }
        );
      }

      /*
      |------------------------------------------------------------
      | PAYLOAD
      |------------------------------------------------------------
      */

      const reference =
        normalizeString(
          payload.reference
        );

      const merchantRef =
        normalizeString(
          payload.merchant_ref
        );

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

      if (
        !reference ||
        !merchantRef ||
        !status
      ) {
        return sendJson(
          res,
          400,
          {
            success:
              false,

            message:
              "Callback data tidak lengkap.",
          }
        );
      }

      if (
        reference.length >
          200 ||
        merchantRef.length >
          200
      ) {
        return sendJson(
          res,
          400,
          {
            success:
              false,

            message:
              "Reference callback tidak valid.",
          }
        );
      }

      if (
        !ALLOWED_STATUS.has(
          status
        )
      ) {
        return sendJson(
          res,
          400,
          {
            success:
              false,

            message:
              "Status transaksi tidak dikenal.",
          }
        );
      }

      if (
        totalAmount ===
          null ||
        totalAmount <= 0
      ) {
        return sendJson(
          res,
          400,
          {
            success:
              false,

            message:
              "Nominal transaksi tidak valid.",
          }
        );
      }

      if (
        amountReceived !==
          null &&
        amountReceived < 0
      ) {
        return sendJson(
          res,
          400,
          {
            success:
              false,

            message:
              "Nominal pembayaran tidak valid.",
          }
        );
      }

      const transaksiRef =
        db
          .collection(
            "topup_transactions"
          )
          .doc(merchantRef);

      try {
        const result =
          await db.runTransaction(
            async (
              transaction
            ) => {
              const transaksiSnap =
                await transaction.get(
                  transaksiRef
                );

              if (
                !transaksiSnap.exists
              ) {
                throw new Error(
                  "TRANSACTION_NOT_FOUND"
                );
              }

              const transaksi =
                transaksiSnap.data() ||
                {};

              const uid =
                normalizeString(
                  transaksi.uid
                );

              if (!uid) {
                throw new Error(
                  "TRANSACTION_UID_MISSING"
                );
              }

              const savedMerchantRef =
                normalizeString(
                  transaksi.merchantRef
                );

              if (
                savedMerchantRef !==
                merchantRef
              ) {
                throw new Error(
                  "MERCHANT_REFERENCE_MISMATCH"
                );
              }

              const expectedAmount =
                toSafeInteger(
                  transaksi.amount
                );

              if (
                expectedAmount ===
                    null ||
                expectedAmount <=
                    0
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
                )
                  .toUpperCase();

              if (
                currentStatus ===
                "PAID"
              ) {
                return {
                  alreadyPaid:
                    true,

                  credited:
                    true,

                  uid,

                  saldoAkhir:
                    transaksi.saldoAkhir ??
                    null,
                };
              }

              if (
                status !==
                "PAID"
              ) {
                transaction.update(
                  transaksiRef,
                  {
                    status,

                    reference,

                    totalAmount,

                    amountReceived:
                      amountReceived ??
                      0,

                    updatedAt:
                      admin.firestore
                        .FieldValue
                        .serverTimestamp(),
                  }
                );

                return {
                  alreadyPaid:
                    false,

                  credited:
                    false,

                  status,
                };
              }

              const userRef =
                db
                  .collection(
                    "users"
                  )
                  .doc(uid);

              const userSnap =
                await transaction.get(
                  userRef
                );

              if (
                !userSnap.exists
              ) {
                throw new Error(
                  "USER_NOT_FOUND"
                );
              }

              const userData =
                userSnap.data() ||
                {};

              const saldoSebelumnya =
                toSafeInteger(
                  userData[
                    BALANCE_FIELD
                  ]
                );

              if (
                saldoSebelumnya ===
                    null ||
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

                  type:
                    "CREDIT",

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

                  tipe:
                    "MASUK",

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

              transaction.update(
                transaksiRef,
                {
                  status:
                    "PAID",

                  reference,

                  totalAmount:
                    expectedAmount,

                  amountReceived:
                    amountReceived ??
                    0,

                  creditedAmount:
                    expectedAmount,

                  saldoAwal:
                    saldoSebelumnya,

                  saldoAkhir:
                    saldoBaru,

                  credited:
                    true,

                  balanceCredited:
                    true,

                  ledgerId:
                    ledgerRef.id,

                  mutasiId:
                    mutasiRef.id,

                  creditedAt:
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
                alreadyPaid:
                  false,

                credited:
                  true,

                uid,

                saldoAkhir:
                  saldoBaru,
              };
            }
          );

        return sendJson(
          res,
          200,
          {
            success:
              true,

            ...result,
          }
        );
      } catch (error) {
        logger.error(
          "CALLBACK TRIPAY GAGAL",
          error
        );

        return sendJson(
          res,
          500,
          {
            success:
              false,

            message:
              "Callback processing failed.",
          }
        );
      }
    }
  );

/*
|--------------------------------------------------------------------------
| SALDO - DEBIT TRANSAKSI EDPOIN
|--------------------------------------------------------------------------
*/

async function debitUserBalanceForEdpoin({
  transactionRef,
  uid,
  amount,
  productCode,
  customerNo,
}) {
  const userRef =
    db
      .collection("users")
      .doc(uid);

  const ledgerRef =
    db
      .collection("balance_ledger")
      .doc();

  const mutasiRef =
    db
      .collection("mutasi_saldo")
      .doc();

  return db.runTransaction(
    async (transaction) => {
      const transactionSnap =
        await transaction.get(
          transactionRef
        );

      if (
        !transactionSnap.exists
      ) {
        throw new Error(
          "TRANSACTION_NOT_FOUND"
        );
      }

      const transactionData =
        transactionSnap.data() ||
        {};

      if (
        transactionData.balanceDebited ===
        true
      ) {
        return {
          alreadyDebited:
            true,

          saldoAkhir:
            toSafeInteger(
              transactionData.saldoAkhir
            ) ?? 0,
        };
      }

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
        userSnap.data() ||
        {};

      const accountStatus = normalizeString(
        userData.status || userData.accountStatus
      ).toLowerCase();
      if (userData.role !== "user" ||
          userData.disabled === true ||
          userData.isDisabled === true ||
          userData.isActive === false ||
          ["disabled", "blocked", "suspended", "nonaktif", "dinonaktifkan", "diblokir"].includes(accountStatus)) {
        throw new Error("ACCOUNT_DISABLED");
      }

      const saldoSebelumnya =
        toSafeInteger(
          userData[
            BALANCE_FIELD
          ]
        );

      if (
        saldoSebelumnya ===
            null ||
        saldoSebelumnya < 0
      ) {
        throw new Error(
          "INVALID_BALANCE"
        );
      }

      if (
        !Number.isSafeInteger(
          amount
        ) ||
        amount <= 0
      ) {
        throw new Error(
          "INVALID_DEBIT_AMOUNT"
        );
      }

      if (
        saldoSebelumnya < amount
      ) {
        throw new Error(
          "INSUFFICIENT_BALANCE"
        );
      }

      const saldoBaru =
        saldoSebelumnya -
        amount;

      if (
        !Number.isSafeInteger(
          saldoBaru
        ) ||
        saldoBaru < 0
      ) {
        throw new Error(
          "BALANCE_OVERFLOW"
        );
      }

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

      transaction.set(
        ledgerRef,
        {
          uid,

          type:
            "DEBIT",

          amount,

          before:
            saldoSebelumnya,

          after:
            saldoBaru,

          reason:
            `Pembelian EDPOIN ${productCode} ke ${customerNo}`,

          source:
            "EDPOIN",

          transactionId:
            transactionRef.id,

          createdAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );

      transaction.set(
        mutasiRef,
        {
          uid,

          tipe:
            "KELUAR",

          nominal:
            amount,

          saldoAwal:
            saldoSebelumnya,

          saldoAkhir:
            saldoBaru,

          keterangan:
            `Pembelian EDPOIN ${productCode} ke ${customerNo}`,

          sumber:
            "EDPOIN",

          transactionId:
            transactionRef.id,

          waktu:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );

      transaction.update(
        transactionRef,
        {
          balanceDebited:
            true,

          balanceRefunded:
            false,

          amount,

          saldoAwal:
            saldoSebelumnya,

          saldoAkhir:
            saldoBaru,

          debitLedgerId:
            ledgerRef.id,

          debitMutasiId:
            mutasiRef.id,

          updatedAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );

      return {
        alreadyDebited:
          false,

        saldoAkhir:
          saldoBaru,
      };
    }
  );
}

/*
|--------------------------------------------------------------------------
| SALDO - REFUND EDPOIN
|--------------------------------------------------------------------------
*/

async function refundEdpoinBalance({
  transactionRef,
  reason,
}) {
  const ledgerRef =
    db
      .collection("balance_ledger")
      .doc();

  const mutasiRef =
    db
      .collection("mutasi_saldo")
      .doc();

  return db.runTransaction(
    async (transaction) => {
      const transactionSnap =
        await transaction.get(
          transactionRef
        );

      if (
        !transactionSnap.exists
      ) {
        throw new Error(
          "TRANSACTION_NOT_FOUND"
        );
      }

      const trx =
        transactionSnap.data() ||
        {};

      /*
      |----------------------------------------------------------
      | SUCCESS ADALAH TERMINAL STATE
      |----------------------------------------------------------
      */

      if (
        String(
          trx.status || ""
        )
          .trim()
          .toUpperCase() ===
        "SUCCESS"
      ) {
        return {
          refunded:
            false,

          reason:
            "TRANSACTION_ALREADY_SUCCESS",

          saldoAkhir:
            toSafeInteger(
              trx.saldoAkhir
            ) ?? 0,
        };
      }

      if (
        trx.balanceDebited !==
        true
      ) {
        return {
          refunded:
            false,

          reason:
            "BALANCE_NOT_DEBITED",
        };
      }

      if (
        trx.balanceRefunded ===
        true
      ) {
        return {
          refunded:
            false,

          reason:
            "ALREADY_REFUNDED",

          saldoAkhir:
            toSafeInteger(
              trx.refundSaldoAkhir ??
                trx.saldoAkhir
            ) ?? 0,
        };
      }

      const uid =
        normalizeString(
          trx.uid
        );

      const amount =
        toSafeInteger(
          trx.amount
        );

      if (!uid) {
        throw new Error(
          "TRANSACTION_UID_MISSING"
        );
      }

      if (
        amount === null ||
        amount <= 0
      ) {
        throw new Error(
          "INVALID_REFUND_AMOUNT"
        );
      }

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
        userSnap.data() ||
        {};

      const saldoSebelumnya =
        toSafeInteger(
          userData[
            BALANCE_FIELD
          ]
        );

      if (
        saldoSebelumnya ===
            null ||
        saldoSebelumnya < 0
      ) {
        throw new Error(
          "INVALID_BALANCE"
        );
      }

      const saldoBaru =
        saldoSebelumnya +
        amount;

      if (
        !Number.isSafeInteger(
          saldoBaru
        )
      ) {
        throw new Error(
          "BALANCE_OVERFLOW"
        );
      }

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

      transaction.set(
        ledgerRef,
        {
          uid,

          type:
            "CREDIT",

          amount,

          before:
            saldoSebelumnya,

          after:
            saldoBaru,

          reason:
            reason ||
            "Refund transaksi EDPOIN",

          source:
            "EDPOIN_REFUND",

          transactionId:
            transactionRef.id,

          createdAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );

      transaction.set(
        mutasiRef,
        {
          uid,

          tipe:
            "MASUK",

          nominal:
            amount,

          saldoAwal:
            saldoSebelumnya,

          saldoAkhir:
            saldoBaru,

          keterangan:
            reason ||
            "Refund transaksi EDPOIN",

          sumber:
            "EDPOIN_REFUND",

          transactionId:
            transactionRef.id,

          waktu:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );

      transaction.update(
        transactionRef,
        {
          balanceRefunded:
            true,

          refundAmount:
            amount,

          refundSaldoAwal:
            saldoSebelumnya,

          refundSaldoAkhir:
            saldoBaru,

          refundLedgerId:
            ledgerRef.id,

          refundMutasiId:
            mutasiRef.id,

          refundedAt:
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
        refunded:
          true,

        saldoAkhir:
          saldoBaru,
      };
    }
  );
}

/*
|--------------------------------------------------------------------------
| EDPOIN - TRANSACTION REQUEST
|--------------------------------------------------------------------------
*/

exports.edpoinTransactionRequest =
  onCall(
    {
      region: REGION,
      timeoutSeconds: 90,
      memory: "256MiB",
      secrets: [
        EDPOIN_USERNAME,
        EDPOIN_API_KEY,
      ],
    },

    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "Harus login."
        );
      }

      const uid =
        request.auth.uid;

      const data =
        request.data || {};

      const productCode =
        normalizeString(
          data.product_code
        );

      const customerNo =
        normalizeString(
          data.customer_no
        );

      const requestId =
        normalizeString(
          data.request_id
        );

      if (
        !productCode ||
        !customerNo
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Kode produk dan nomor pelanggan wajib diisi."
        );
      }

      if (
        productCode.length >
          100 ||
        customerNo.length >
          100
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Input transaksi tidak valid."
        );
      }

      if (
        !isValidRequestId(
          requestId
        )
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Request ID tidak valid."
        );
      }

      try {
        const {
          price,
          product,
        } =
          await getTrustedProductPrice(
            productCode
          );

        const refId =
          requestId
            ? `dp-${uid.slice(
                0,
                8
              )}-${requestId}`
            : generateRefId(
                uid
              );

        if (
          refId.length >
          180
        ) {
          throw new HttpsError(
            "invalid-argument",
            "Referensi transaksi terlalu panjang."
          );
        }

        const transaksiRef =
          db
            .collection(
              "edpoin_transactions"
            )
            .doc(refId);

        const existingSnap =
          await transaksiRef.get();

        if (
          existingSnap.exists
        ) {
          const existing =
            existingSnap.data() ||
            {};

          if (
            existing.uid !==
            uid
          ) {
            throw new HttpsError(
              "permission-denied",
              "Transaksi tidak dapat diakses."
            );
          }

          const existingProduct =
            normalizeString(
              existing.productCode
            );

          const existingCustomerNo =
            normalizeString(
              existing.customerNo
            );

          const existingAmount =
            toSafeInteger(
              existing.amount
            );

          if (
            existingProduct !==
              productCode ||
            existingCustomerNo !==
              customerNo ||
            existingAmount !==
              price
          ) {
            throw new HttpsError(
              "already-exists",
              "Request ID sudah digunakan untuk transaksi berbeda."
            );
          }

          return {
            success:
              existing.status !==
              "FAILED",

            ref_id:
              refId,

            status:
              existing.status ||
              "PROCESSING",

            response:
              existing.response ||
              null,

            amount:
              existingAmount ??
              price,

            saldoAkhir:
              existing.saldoAkhir ??
              null,

            balanceDebited:
              existing.balanceDebited ===
              true,

            balanceRefunded:
              existing.balanceRefunded ===
              true,

            reused:
              true,
          };
        }

        await transaksiRef.create(
          {
            uid,

            refId,

            productCode,

            customerNo,

            productName:
              product.name ||
              product.nama ||
              "-",

            amount:
              price,

            status:
              "CREATED",

            balanceDebited:
              false,

            balanceRefunded:
              false,

            createdAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),

            updatedAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),
          }
        );

        try {
          await debitUserBalanceForEdpoin(
            {
              transactionRef:
                transaksiRef,

              uid,

              amount:
                price,

              productCode,

              customerNo,
            }
          );
        } catch (error) {
          await transaksiRef.set(
            {
              status:
                "FAILED",

              failureReason:
                error.message,

              updatedAt:
                admin.firestore
                  .FieldValue
                  .serverTimestamp(),
            },
            {
              merge:
                true,
            }
          );

          switch (
            error.message
          ) {
            case "USER_NOT_FOUND":
              throw new HttpsError(
                "not-found",
                "Akun pengguna tidak ditemukan."
              );

            case "INVALID_BALANCE":
              throw new HttpsError(
                "failed-precondition",
                "Saldo pengguna tidak valid."
              );

            case "INSUFFICIENT_BALANCE":
              throw new HttpsError(
                "failed-precondition",
                "Saldo DesaPay tidak mencukupi."
              );

            case "INVALID_DEBIT_AMOUNT":
              throw new HttpsError(
                "failed-precondition",
                "Nominal transaksi tidak valid."
              );

            default:
              throw new HttpsError(
                "internal",
                "Gagal mengamankan saldo transaksi."
              );
          }
        }

        await transaksiRef.set(
          {
            status:
              "PROCESSING",

            updatedAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),
          },
          {
            merge:
              true,
          }
        );

        const {
          username,
          apiKey,
        } =
          edpoinCredentials();

        const result =
          await edpoinRequest(
            "transaction",
            {
              username,

              api_key:
                apiKey,

              product_code:
                productCode,

              customer_no:
                customerNo,

              ref_id:
                refId,

              amount:
                price,

              sign:
                md5(
                  username +
                    apiKey +
                    refId
                ),
            }
          );

        const resultData =
          result.data ||
          {};

        const providerStatus =
          String(
            resultData.status ||
              result.status ||
              ""
          )
            .trim()
            .toUpperCase();

        if (
          providerStatus ===
            "SUKSES" ||
          providerStatus ===
            "SUCCESS"
        ) {
          await transaksiRef.set(
            {
              status:
                "SUCCESS",

              response:
                resultData,

              providerReference:
                resultData.ref_id ||
                resultData.reference ||
                resultData.sn ||
                null,

              completedAt:
                admin.firestore
                  .FieldValue
                  .serverTimestamp(),

              updatedAt:
                admin.firestore
                  .FieldValue
                  .serverTimestamp(),
            },
            {
              merge:
                true,
            }
          );

          return {
            success:
              true,

            ref_id:
              refId,

            status:
              "SUCCESS",

            response:
              resultData,
          };
        }

        if (
          providerStatus ===
            "GAGAL" ||
          providerStatus ===
            "FAILED" ||
          providerStatus ===
            "FAIL"
        ) {
          const refund =
            await refundEdpoinBalance(
              {
                transactionRef:
                  transaksiRef,

                reason:
                  `Refund transaksi EDPOIN: ${
                    resultData.message ||
                    result.message ||
                    "Provider menyatakan gagal."
                  }`,
              }
            );

          await transaksiRef.set(
            {
              status:
                "FAILED",

              response:
                resultData,

              failureReason:
                resultData.message ||
                result.message ||
                "Transaksi EDPOIN gagal.",

              refunded:
                refund.refunded ===
                  true ||
                refund.reason ===
                  "ALREADY_REFUNDED",

              updatedAt:
                admin.firestore
                  .FieldValue
                  .serverTimestamp(),
            },
            {
              merge:
                true,
            }
          );

          return {
            success:
              false,

            ref_id:
              refId,

            status:
              "FAILED",

            refunded:
              refund.refunded ===
                true ||
              refund.reason ===
                "ALREADY_REFUNDED",

            message:
              resultData.message ||
              result.message ||
              "Transaksi gagal dan saldo telah dikembalikan.",

            response:
              resultData,
          };
        }

        await transaksiRef.set(
          {
            status:
              "PENDING",

            response:
              resultData,

            updatedAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),
          },
          {
            merge:
              true,
          }
        );

        return {
          success:
            true,

          ref_id:
            refId,

          status:
            "PENDING",

          response:
            resultData,
        };
      } catch (error) {
        if (
          error instanceof
          HttpsError
        ) {
          throw error;
        }

        logger.error(
          "EDPOIN TRANSAKSI GAGAL",
          error
        );

        throw new HttpsError(
          "internal",
          "Transaksi sedang diproses atau gagal terhubung ke provider."
        );
      }
    }
  );


/*
|--------------------------------------------------------------------------
| DESAPAY - PENARIKAN SALDO (ATOMIC + IDEMPOTENT)
|--------------------------------------------------------------------------
*/

const WITHDRAWAL_MAX_AMOUNT = 100000000;

function validateWithdrawalDestination(data) {
  const destinationType = normalizeString(data.destination_type).toUpperCase();
  const destinationName = normalizeString(data.destination_name);
  const destinationAccount = normalizeString(data.destination_account);
  const destinationAccountName = normalizeString(data.destination_account_name);

  if (!["BANK", "E-WALLET"].includes(destinationType)) {
    throw new HttpsError("invalid-argument", "Jenis tujuan harus BANK atau E-WALLET.");
  }
  if (!destinationName || destinationName.length > 100 ||
      !destinationAccount || destinationAccount.length > 100 ||
      !destinationAccountName || destinationAccountName.length > 100) {
    throw new HttpsError("invalid-argument", "Nama layanan, nomor rekening/akun, dan nama pemilik wajib diisi dengan benar.");
  }

  return { destinationType, destinationName, destinationAccount, destinationAccountName };
}

exports.requestWithdrawal = onCall(
  { region: REGION, timeoutSeconds: 30, memory: "256MiB" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Silakan login terlebih dahulu.");
    }

    const uid = request.auth.uid;
    const data = request.data || {};
    const requestId = normalizeString(data.request_id);
    const amount = toSafeInteger(data.amount);

    if (!/^[A-Za-z0-9_-]{8,80}$/.test(requestId)) {
      throw new HttpsError("invalid-argument", "ID permintaan wajib berupa 8-80 karakter huruf, angka, _ atau -.");
    }
    if (amount === null || amount <= 0 || amount > WITHDRAWAL_MAX_AMOUNT) {
      throw new HttpsError("invalid-argument", "Nominal penarikan tidak valid.");
    }

    const destination = validateWithdrawalDestination(data);
    const withdrawalId = `wd-${crypto.createHash("sha256").update(`${uid}:${requestId}`, "utf8").digest("hex")}`;
    const withdrawalRef = db.collection("withdrawal_requests").doc(withdrawalId);
    const userRef = db.collection("users").doc(uid);
    const ledgerRef = db.collection("balance_ledger").doc();
    const mutasiRef = db.collection("mutasi_saldo").doc();

    try {
      return await db.runTransaction(async (transaction) => {
        const existingSnap = await transaction.get(withdrawalRef);
        if (existingSnap.exists) {
          const existing = existingSnap.data() || {};
          const sameRequest = existing.uid === uid &&
            existing.amount === amount &&
            existing.destinationType === destination.destinationType &&
            existing.destinationName === destination.destinationName &&
            existing.destinationAccount === destination.destinationAccount &&
            existing.destinationAccountName === destination.destinationAccountName;

          if (!sameRequest) {
            throw new HttpsError("already-exists", "ID permintaan sudah dipakai untuk data penarikan yang berbeda.");
          }
          return {
            success: true,
            request_id: withdrawalId,
            status: existing.status,
            saldoAkhir: existing.saldoAkhir,
            reused: true,
          };
        }

        const userSnap = await transaction.get(userRef);
        if (!userSnap.exists) {
          throw new HttpsError("not-found", "Akun pengguna tidak ditemukan.");
        }
        const userData = userSnap.data() || {};
        const balanceBefore = toSafeInteger(userData[BALANCE_FIELD]);
        if (balanceBefore === null || balanceBefore < 0) {
          throw new HttpsError("failed-precondition", "Saldo pengguna tidak valid.");
        }
        if (balanceBefore < amount) {
          throw new HttpsError("failed-precondition", "Saldo tidak mencukupi untuk penarikan.");
        }

        const balanceAfter = balanceBefore - amount;
        const now = admin.firestore.FieldValue.serverTimestamp();

        transaction.update(userRef, {
          [BALANCE_FIELD]: balanceAfter,
          updatedAt: now,
        });
        transaction.create(withdrawalRef, {
          uid,
          requestId,
          amount,
          destinationType: destination.destinationType,
          destinationName: destination.destinationName,
          destinationAccount: destination.destinationAccount,
          destinationAccountName: destination.destinationAccountName,
          status: "PENDING",
          saldoAwal: balanceBefore,
          saldoAkhir: balanceAfter,
          refunded: false,
          createdAt: now,
          updatedAt: now,
        });
        transaction.create(ledgerRef, {
          uid,
          type: "DEBIT",
          amount,
          before: balanceBefore,
          after: balanceAfter,
          reason: "Penahanan saldo untuk permintaan penarikan",
          source: "WITHDRAWAL",
          transactionId: withdrawalId,
          createdAt: now,
        });
        transaction.create(mutasiRef, {
          uid,
          tipe: "KELUAR",
          nominal: amount,
          saldoAwal: balanceBefore,
          saldoAkhir: balanceAfter,
          keterangan: "Saldo ditahan untuk permintaan penarikan",
          sumber: "WITHDRAWAL",
          transactionId: withdrawalId,
          waktu: now,
        });

        return {
          success: true,
          request_id: withdrawalId,
          status: "PENDING",
          saldoAkhir: balanceAfter,
          reused: false,
        };
      });
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Permintaan penarikan gagal", error);
      throw new HttpsError("internal", "Permintaan penarikan gagal diproses.");
    }
  }
);

exports.adminReviewWithdrawal = onCall(
  { region: REGION, timeoutSeconds: 30, memory: "256MiB" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Admin harus login.");
    }
    if (!(await checkAdmin(request.auth.uid))) {
      throw new HttpsError("permission-denied", "Akses hanya untuk admin.");
    }

    const data = request.data || {};
    const withdrawalId = normalizeString(data.request_id);
    const action = normalizeString(data.action).toUpperCase();
    const reason = normalizeString(data.reason).slice(0, 500);

    if (!withdrawalId || withdrawalId.length > 180 ||
        !["APPROVE", "REJECT"].includes(action)) {
      throw new HttpsError("invalid-argument", "ID permintaan atau tindakan admin tidak valid.");
    }

    const withdrawalRef = db.collection("withdrawal_requests").doc(withdrawalId);
    const ledgerRef = db.collection("balance_ledger").doc();
    const mutasiRef = db.collection("mutasi_saldo").doc();

    try {
      return await db.runTransaction(async (transaction) => {
        const withdrawalSnap = await transaction.get(withdrawalRef);
        if (!withdrawalSnap.exists) {
          throw new HttpsError("not-found", "Permintaan penarikan tidak ditemukan.");
        }
        const withdrawal = withdrawalSnap.data() || {};
        const targetStatus = action === "APPROVE" ? "APPROVED" : "REJECTED";

        if (withdrawal.status !== "PENDING") {
          if (withdrawal.status === targetStatus) {
            return {
              success: true,
              request_id: withdrawalId,
              status: withdrawal.status,
              refunded: withdrawal.refunded === true,
              reused: true,
            };
          }
          throw new HttpsError("failed-precondition", "Permintaan sudah diproses dan tidak dapat diubah lagi.");
        }

        const now = admin.firestore.FieldValue.serverTimestamp();
        if (action === "APPROVE") {
          transaction.update(withdrawalRef, {
            status: "APPROVED",
            reviewedBy: request.auth.uid,
            reviewedAt: now,
            reviewReason: reason,
            updatedAt: now,
          });
          return { success: true, request_id: withdrawalId, status: "APPROVED", refunded: false, reused: false };
        }

        const uid = normalizeString(withdrawal.uid);
        const amount = toSafeInteger(withdrawal.amount);
        if (!uid || amount === null || amount <= 0) {
          throw new HttpsError("failed-precondition", "Data permintaan penarikan tidak valid.");
        }
        if (withdrawal.refunded === true) {
          throw new HttpsError("failed-precondition", "Saldo permintaan ini sudah dikembalikan.");
        }

        const userRef = db.collection("users").doc(uid);
        const userSnap = await transaction.get(userRef);
        if (!userSnap.exists) {
          throw new HttpsError("not-found", "Akun pengguna tidak ditemukan untuk pengembalian saldo.");
        }
        const userData = userSnap.data() || {};
        const balanceBefore = toSafeInteger(userData[BALANCE_FIELD]);
        if (balanceBefore === null || balanceBefore < 0) {
          throw new HttpsError("failed-precondition", "Saldo pengguna tidak valid.");
        }
        const balanceAfter = balanceBefore + amount;
        if (!Number.isSafeInteger(balanceAfter)) {
          throw new HttpsError("failed-precondition", "Saldo hasil pengembalian melampaui batas.");
        }

        transaction.update(userRef, { [BALANCE_FIELD]: balanceAfter, updatedAt: now });
        transaction.update(withdrawalRef, {
          status: "REJECTED",
          refunded: true,
          refundSaldoAwal: balanceBefore,
          refundSaldoAkhir: balanceAfter,
          reviewedBy: request.auth.uid,
          reviewedAt: now,
          reviewReason: reason || "Permintaan penarikan ditolak",
          updatedAt: now,
        });
        transaction.create(ledgerRef, {
          uid,
          type: "CREDIT",
          amount,
          before: balanceBefore,
          after: balanceAfter,
          reason: reason || "Pengembalian saldo penarikan yang ditolak",
          source: "WITHDRAWAL_REFUND",
          transactionId: withdrawalId,
          createdAt: now,
        });
        transaction.create(mutasiRef, {
          uid,
          tipe: "MASUK",
          nominal: amount,
          saldoAwal: balanceBefore,
          saldoAkhir: balanceAfter,
          keterangan: reason || "Pengembalian saldo penarikan yang ditolak",
          sumber: "WITHDRAWAL_REFUND",
          transactionId: withdrawalId,
          waktu: now,
        });

        return { success: true, request_id: withdrawalId, status: "REJECTED", refunded: true, saldoAkhir: balanceAfter, reused: false };
      });
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Review penarikan gagal", error);
      throw new HttpsError("internal", "Status penarikan gagal diperbarui.");
    }
  }
);

