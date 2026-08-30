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

/*
|--------------------------------------------------------------------------
| KONSTANTA
|--------------------------------------------------------------------------
*/

const REGION = "asia-southeast2";

const DIGIFLAZZ_BASE_URL =
  "https://api.digiflazz.com/v1";

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

function md5(value) {
  return crypto
    .createHash("md5")
    .update(value, "utf8")
    .digest("hex");
}

async function digiflazzRequest(endpoint, body) {
  const response = await fetch(
    `${DIGIFLAZZ_BASE_URL}/${endpoint}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    }
  );

  const text = await response.text();

  let data;

  try {
    data = JSON.parse(text);
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

  if (!username || !apiKey) {
    throw new Error(
      "Credential Digiflazz belum dikonfigurasi."
    );
  }

  return {
    username,
    apiKey,
  };
}

function generateRefId(uid) {
  const random = crypto
    .randomBytes(6)
    .toString("hex");

  return `dp-${Date.now()}-${uid.slice(0, 8)}-${random}`;
}

function generateSignature(
  rawBody,
  privateKey
) {
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
      Buffer.from(expected, "hex");

    const receivedBuffer =
      Buffer.from(
        receivedSignature
          .trim()
          .toLowerCase(),
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
| ADMIN UBAH SALDO
|--------------------------------------------------------------------------
*/

exports.adminAdjustBalance = onCall(
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
      !(await checkAdmin(adminUid))
    ) {
      throw new HttpsError(
        "permission-denied",
        "Akses hanya untuk admin."
      );
    }

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

    const MAX_ADJUSTMENT =
      100000000;

    if (
      Math.abs(amount) >
      MAX_ADJUSTMENT
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Nominal perubahan saldo terlalu besar."
      );
    }

    const userRef = db
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

            if (!userSnap.exists) {
              throw new Error(
                "USER_NOT_FOUND"
              );
            }

            const userData =
              userSnap.data() || {};

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

            return {
              uid,
              before,
              after,
              amount,
              ledgerId:
                ledgerRef.id,
            };
          }
        );

      return {
        success: true,
        ...result,
      };
    } catch (error) {
      logger.error(
        "ADMIN SALDO GAGAL",
        error
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
| DIGIFLAZZ - PRICE LIST
|--------------------------------------------------------------------------
*/

exports.digiflazzPriceList = onCall(
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
      } = digiflazzCredentials();

      return await digiflazzRequest(
        "price-list",
        {
          cmd: "prepaid",
          username,

          sign: md5(
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
| DIGIFLAZZ - CEK SALDO
|--------------------------------------------------------------------------
*/

exports.digiflazzCekSaldo = onCall(
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
      } = digiflazzCredentials();

      return await digiflazzRequest(
        "cek-saldo",
        {
          cmd: "deposit",
          username,

          sign: md5(
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

      const uid =
        request.auth.uid;

      const data =
        request.data || {};

      const buyerSkuCode =
        typeof data.buyer_sku_code ===
        "string"
          ? data.buyer_sku_code.trim()
          : "";

      const customerNo =
        typeof data.customer_no ===
        "string"
          ? data.customer_no.trim()
          : "";

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
        buyerSkuCode.length > 100 ||
        customerNo.length > 100
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Input transaksi tidak valid."
        );
      }

      try {
        const {
          username,
          apiKey,
        } = digiflazzCredentials();

        const refId =
          generateRefId(uid);

        const transaksiRef =
          db
            .collection(
              "digiflazz_transactions"
            )
            .doc(refId);

        await transaksiRef.set({
          uid,

          refId,

          buyerSkuCode,

          customerNo,

          status:
            "PROCESSING",

          createdAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        });

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

              sign: md5(
                username +
                  apiKey +
                  refId
              ),
            }
          );

        const resultData =
          result.data || {};

        await transaksiRef.set(
          {
            response:
              resultData,

            status:
              resultData.status ||
              "UNKNOWN",

            updatedAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),
          },
          {
            merge: true,
          }
        );

        return result;
      } catch (error) {
        logger.error(
          "DIGIFLAZZ TRANSAKSI GAGAL",
          error
        );

        throw new HttpsError(
          "internal",
          "Transaksi Digiflazz gagal diproses."
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
        typeof request.data?.ref_id ===
        "string"
          ? request.data.ref_id.trim()
          : "";

      if (!refId) {
        throw new HttpsError(
          "invalid-argument",
          "Ref ID wajib diisi."
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

        if (!transaksiSnap.exists) {
          throw new HttpsError(
            "not-found",
            "Transaksi tidak ditemukan."
          );
        }

        const transaksi =
          transaksiSnap.data() || {};

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

        const {
          username,
          apiKey,
        } = digiflazzCredentials();

        const result =
          await digiflazzRequest(
            "transaction",
            {
              username,

              buyer_sku_code:
                transaksi.buyerSkuCode,

              customer_no:
                transaksi.customerNo,

              ref_id:
                refId,

              sign: md5(
                username +
                  apiKey +
                  refId
              ),
            }
          );

        await transaksiRef.set(
          {
            response:
              result.data || {},

            status:
              result.data?.status ||
              "UNKNOWN",

            updatedAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),
          },
          {
            merge: true,
          }
        );

        return result;
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
        typeof data.Bank ===
        "string"
          ? data.Bank.trim()
          : "";

      const ownerName =
        typeof data.owner_name ===
        "string"
          ? data.owner_name.trim()
          : "";

      if (
        amount === null ||
        amount <= 0
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Nominal deposit tidak valid."
        );
      }

      if (!bank || !ownerName) {
        throw new HttpsError(
          "invalid-argument",
          "Bank dan nama pemilik wajib diisi."
        );
      }

      try {
        const {
          username,
          apiKey,
        } = digiflazzCredentials();

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

              sign: md5(
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
          .add({
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
          });

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
      if (req.method !== "POST") {
        return sendJson(
          res,
          405,
          {
            success: false,
            message:
              "Method Not Allowed",
          }
        );
      }

      let rawBody = "";

      if (
        Buffer.isBuffer(
          req.rawBody
        )
      ) {
        rawBody =
          req.rawBody.toString(
            "utf8"
          );
      } else if (
        typeof req.rawBody ===
        "string"
      ) {
        rawBody =
          req.rawBody;
      } else {
        rawBody =
          JSON.stringify(
            req.body || {}
          );
      }

      if (!rawBody.trim()) {
        return sendJson(
          res,
          400,
          {
            success: false,
            message:
              "Empty callback body.",
          }
        );
      }

      const receivedSignature =
        req.get(
          "X-Callback-Signature"
        ) ||
        req.get(
          "x-callback-signature"
        ) ||
        req.get("Signature");

      if (!receivedSignature) {
        return sendJson(
          res,
          401,
          {
            success: false,
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
            success: false,
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
            success: false,
            message:
              "Invalid callback signature.",
          }
        );
      }

      let payload;

      try {
        payload =
          JSON.parse(rawBody);
      } catch (_) {
        return sendJson(
          res,
          400,
          {
            success: false,
            message:
              "Invalid JSON.",
          }
        );
      }

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

      if (
        !reference ||
        !merchantRef ||
        !status
      ) {
        return sendJson(
          res,
          400,
          {
            success: false,
            message:
              "Callback data tidak lengkap.",
          }
        );
      }

      if (
        !ALLOWED_STATUS.has(status)
      ) {
        return sendJson(
          res,
          400,
          {
            success: false,
            message:
              "Status transaksi tidak dikenal.",
          }
        );
      }

      if (
        totalAmount === null ||
        totalAmount <= 0
      ) {
        return sendJson(
          res,
          400,
          {
            success: false,
            message:
              "Nominal transaksi tidak valid.",
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
            async (transaction) => {
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
                  transaksi.merchantRef ||
                    ""
                ).trim();

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

              if (
                currentStatus === "PAID"
              ) {
                return {
                  alreadyPaid: true,
                };
              }

              if (status !== "PAID") {
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
                  alreadyPaid: false,
                  credited: false,
                  status,
                };
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
                  userData[
                    BALANCE_FIELD
                  ]
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

              transaction.update(
                transaksiRef,
                {
                  status: "PAID",

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

                  credited: true,

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
                alreadyPaid: false,

                credited: true,

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
            success: true,
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
            success: false,
            message:
              "Callback processing failed.",
          }
        );
      }
    }
  );

/*
|--------------------------------------------------------------------------
| EDPOIN - TRANSACTION REQUEST
|--------------------------------------------------------------------------
|
| Alur:
| User login -> pilih produk EDPOIN -> request transaksi
| -> Function validasi -> simpan transaksi -> kirim ke EDPOIN
|
| CATATAN:
| Ganti EDPOIN_BASE_URL dan format request/signature sesuai
| dokumentasi API EDPOIN yang kamu gunakan.
|--------------------------------------------------------------------------
*/

const EDPOIN_API_KEY =
  defineSecret("EDPOIN_API_KEY");

const EDPOIN_USERNAME =
  defineSecret("EDPOIN_USERNAME");

const EDPOIN_BASE_URL =
  "https://api.edpoin.com";

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

  if (!username || !apiKey) {
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
    data = JSON.parse(text);
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
| EDPOIN - TRANSACTION REQUEST
|--------------------------------------------------------------------------
*/

exports.edpoinTransactionRequest =
  onCall(
    {
      region: REGION,
      timeoutSeconds: 60,
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
        typeof data.product_code ===
        "string"
          ? data.product_code.trim()
          : "";

      const customerNo =
        typeof data.customer_no ===
        "string"
          ? data.customer_no.trim()
          : "";

      const amount =
        toSafeInteger(
          data.amount
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
        productCode.length > 100 ||
        customerNo.length > 100
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Input transaksi tidak valid."
        );
      }

      if (
        amount === null ||
        amount <= 0
      ) {
        throw new HttpsError(
          "invalid-argument",
          "Nominal transaksi tidak valid."
        );
      }

      try {
        const {
          username,
          apiKey,
        } = edpoinCredentials();

        const refId =
          generateRefId(uid);

        const transaksiRef =
          db
            .collection(
              "edpoin_transactions"
            )
            .doc(refId);

        await transaksiRef.set({
          uid,

          refId,

          productCode,

          customerNo,

          amount,

          status:
            "PROCESSING",

          createdAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        });

        /*
        |--------------------------------------------------------------------------
        | REQUEST EDPOIN
        |--------------------------------------------------------------------------
        |
        | Struktur ini sengaja dipisahkan agar mudah disesuaikan
        | dengan dokumentasi API EDPOIN yang kamu pakai.
        |--------------------------------------------------------------------------
        */

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

              amount,

              sign: md5(
                username +
                  apiKey +
                  refId
              ),
            }
          );

        const resultData =
          result.data || {};

        await transaksiRef.set(
          {
            response:
              resultData,

            status:
              resultData.status ||
              "UNKNOWN",

            updatedAt:
              admin.firestore
                .FieldValue
                .serverTimestamp(),
          },
          {
            merge: true,
          }
        );

        return {
          success: true,

          ref_id: refId,

          ...result,
        };
      } catch (error) {
        logger.error(
          "EDPOIN TRANSAKSI GAGAL",
          error
        );

        throw new HttpsError(
          "internal",
          "Transaksi EDPOIN gagal diproses."
        );
      }
    }
  );
