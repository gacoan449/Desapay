"use strict";

const admin = require("firebase-admin");
const crypto = require("crypto");

const db = admin.firestore();

const TRANSACTION_COLLECTION = "transaction_requests";

const STATUS = {
  PENDING: "PENDING",
  PROCESSING: "PROCESSING",
  SUCCESS: "SUCCESS",
  FAILED: "FAILED",
};

const MAX_UID_LENGTH = 128;
const MAX_PRODUCT_CODE_LENGTH = 100;
const MAX_CUSTOMER_NO_LENGTH = 100;
const MAX_SERVICE_TYPE_LENGTH = 50;
const MAX_TRANSACTION_ID_LENGTH = 180;
const MAX_PROVIDER_LENGTH = 100;
const MAX_PROVIDER_REFERENCE_LENGTH = 200;
const MAX_REASON_LENGTH = 500;

/*
|--------------------------------------------------------------------------
| VALIDATION HELPERS
|--------------------------------------------------------------------------
*/

function normalizeString(value) {
  return typeof value === "string"
    ? value.trim()
    : "";
}

function safeInteger(value) {
  const number = Number(value);

  if (!Number.isSafeInteger(number)) {
    return null;
  }

  return number;
}

function validateRequiredString(
  value,
  fieldName,
  maxLength
) {
  const normalized =
    normalizeString(value);

  if (!normalized) {
    throw new Error(
      `${fieldName}_REQUIRED`
    );
  }

  if (
    normalized.length >
    maxLength
  ) {
    throw new Error(
      `INVALID_${fieldName}_LENGTH`
    );
  }

  return normalized;
}

function normalizeOptionalString(
  value,
  maxLength
) {
  const normalized =
    normalizeString(value);

  if (
    normalized.length >
    maxLength
  ) {
    throw new Error(
      "INVALID_STRING_LENGTH"
    );
  }

  return normalized;
}

function normalizeMetadata(metadata) {
  if (
    metadata === null ||
    metadata === undefined
  ) {
    return {};
  }

  if (
    typeof metadata !== "object" ||
    Array.isArray(metadata)
  ) {
    throw new Error(
      "INVALID_METADATA"
    );
  }

  return metadata;
}

/*
|--------------------------------------------------------------------------
| TRANSACTION ID
|--------------------------------------------------------------------------
*/

function generateTransactionId(uid) {
  return `trx-${Date.now()}-${uid.slice(
    0,
    8
  )}-${crypto
    .randomBytes(6)
    .toString("hex")}`;
}

/*
|--------------------------------------------------------------------------
| CREATE TRANSACTION REQUEST
|--------------------------------------------------------------------------
*/

async function createTransactionRequest({
  uid,
  productCode,
  customerNo,
  serviceType,
  amount,
  metadata = {},
}) {
  const normalizedUid =
    validateRequiredString(
      uid,
      "UID",
      MAX_UID_LENGTH
    );

  const normalizedProductCode =
    validateRequiredString(
      productCode,
      "PRODUCT_CODE",
      MAX_PRODUCT_CODE_LENGTH
    );

  const normalizedCustomerNo =
    validateRequiredString(
      customerNo,
      "CUSTOMER_NO",
      MAX_CUSTOMER_NO_LENGTH
    );

  const normalizedServiceType =
    normalizeOptionalString(
      serviceType ||
        "PPOB",
      MAX_SERVICE_TYPE_LENGTH
    ) || "PPOB";

  const nominal =
    safeInteger(amount);

  if (
    nominal === null ||
    nominal <= 0
  ) {
    throw new Error(
      "INVALID_AMOUNT"
    );
  }

  const normalizedMetadata =
    normalizeMetadata(
      metadata
    );

  const transactionId =
    generateTransactionId(
      normalizedUid
    );

  if (
    transactionId.length >
    MAX_TRANSACTION_ID_LENGTH
  ) {
    throw new Error(
      "INVALID_TRANSACTION_ID"
    );
  }

  const transactionRef =
    db
      .collection(
        TRANSACTION_COLLECTION
      )
      .doc(transactionId);

  await transactionRef.create({
    transactionId,

    uid:
      normalizedUid,

    productCode:
      normalizedProductCode,

    customerNo:
      normalizedCustomerNo,

    serviceType:
      normalizedServiceType,

    amount:
      nominal,

    status:
      STATUS.PENDING,

    provider:
      null,

    providerReference:
      null,

    response:
      null,

    metadata:
      normalizedMetadata,

    createdAt:
      admin.firestore
        .FieldValue
        .serverTimestamp(),

    updatedAt:
      admin.firestore
        .FieldValue
        .serverTimestamp(),
  });

  return {
    transactionId,

    status:
      STATUS.PENDING,
  };
}

/*
|--------------------------------------------------------------------------
| GET TRANSACTION REQUEST
|--------------------------------------------------------------------------
*/

async function getTransactionRequest(
  transactionId
) {
  const normalizedTransactionId =
    validateRequiredString(
      transactionId,
      "TRANSACTION_ID",
      MAX_TRANSACTION_ID_LENGTH
    );

  const ref =
    db
      .collection(
        TRANSACTION_COLLECTION
      )
      .doc(
        normalizedTransactionId
      );

  const snap =
    await ref.get();

  if (!snap.exists) {
    throw new Error(
      "TRANSACTION_NOT_FOUND"
    );
  }

  return {
    id:
      snap.id,

    ...snap.data(),
  };
}

/*
|--------------------------------------------------------------------------
| MARK PROCESSING
|--------------------------------------------------------------------------
*/

async function markProcessing(
  transactionId,
  provider
) {
  const normalizedTransactionId =
    validateRequiredString(
      transactionId,
      "TRANSACTION_ID",
      MAX_TRANSACTION_ID_LENGTH
    );

  const normalizedProvider =
    normalizeOptionalString(
      provider,
      MAX_PROVIDER_LENGTH
    );

  const ref =
    db
      .collection(
        TRANSACTION_COLLECTION
      )
      .doc(
        normalizedTransactionId
      );

  await db.runTransaction(
    async (transaction) => {
      const snap =
        await transaction.get(
          ref
        );

      if (!snap.exists) {
        throw new Error(
          "TRANSACTION_NOT_FOUND"
        );
      }

      const data =
        snap.data() || {};

      const currentStatus =
        String(
          data.status ||
            STATUS.PENDING
        )
          .trim()
          .toUpperCase();

      /*
      |------------------------------------------------------------
      | TERMINAL STATE
      |------------------------------------------------------------
      |
      | SUCCESS dan FAILED tidak boleh diproses ulang.
      |
      */

      if (
        currentStatus ===
          STATUS.SUCCESS ||
        currentStatus ===
          STATUS.FAILED
      ) {
        return;
      }

      /*
      |------------------------------------------------------------
      | PROCESSING
      |------------------------------------------------------------
      |
      | Tidak masalah jika dipanggil ulang.
      |
      */

      transaction.update(
        ref,
        {
          status:
            STATUS.PROCESSING,

          provider:
            normalizedProvider ||
            data.provider ||
            null,

          updatedAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );
    }
  );
}

/*
|--------------------------------------------------------------------------
| MARK SUCCESS
|--------------------------------------------------------------------------
*/

async function markSuccess({
  transactionId,
  provider,
  providerReference,
  response,
}) {
  const normalizedTransactionId =
    validateRequiredString(
      transactionId,
      "TRANSACTION_ID",
      MAX_TRANSACTION_ID_LENGTH
    );

  const normalizedProvider =
    normalizeOptionalString(
      provider,
      MAX_PROVIDER_LENGTH
    );

  const normalizedProviderReference =
    normalizeOptionalString(
      providerReference,
      MAX_PROVIDER_REFERENCE_LENGTH
    );

  const ref =
    db
      .collection(
        TRANSACTION_COLLECTION
      )
      .doc(
        normalizedTransactionId
      );

  await db.runTransaction(
    async (transaction) => {
      const snap =
        await transaction.get(
          ref
        );

      if (!snap.exists) {
        throw new Error(
          "TRANSACTION_NOT_FOUND"
        );
      }

      const data =
        snap.data() || {};

      const currentStatus =
        String(
          data.status ||
            STATUS.PENDING
        )
          .trim()
          .toUpperCase();

      /*
      |------------------------------------------------------------
      | IDEMPOTENCY
      |------------------------------------------------------------
      |
      | Sudah SUCCESS -> tidak menulis ulang.
      |
      */

      if (
        currentStatus ===
        STATUS.SUCCESS
      ) {
        return;
      }

      /*
      |------------------------------------------------------------
      | PROTECT FAILED
      |------------------------------------------------------------
      |
      | Transaksi yang sudah FAILED tidak boleh tiba-tiba
      | berubah menjadi SUCCESS melalui pemanggilan terlambat.
      |
      | Perubahan status FAILED -> SUCCESS harus melalui proses
      | bisnis yang memang disengaja, bukan retry biasa.
      |
      */

      if (
        currentStatus ===
        STATUS.FAILED
      ) {
        return;
      }

      transaction.update(
        ref,
        {
          status:
            STATUS.SUCCESS,

          provider:
            normalizedProvider ||
            data.provider ||
            null,

          providerReference:
            normalizedProviderReference ||
            data.providerReference ||
            null,

          response:
            response ||
            null,

          completedAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),

          updatedAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );
    }
  );
}

/*
|--------------------------------------------------------------------------
| MARK FAILED
|--------------------------------------------------------------------------
*/

async function markFailed({
  transactionId,
  provider,
  providerReference,
  response,
  reason,
}) {
  const normalizedTransactionId =
    validateRequiredString(
      transactionId,
      "TRANSACTION_ID",
      MAX_TRANSACTION_ID_LENGTH
    );

  const normalizedProvider =
    normalizeOptionalString(
      provider,
      MAX_PROVIDER_LENGTH
    );

  const normalizedProviderReference =
    normalizeOptionalString(
      providerReference,
      MAX_PROVIDER_REFERENCE_LENGTH
    );

  const normalizedReason =
    normalizeOptionalString(
      reason ||
        "Transaksi gagal.",
      MAX_REASON_LENGTH
    ) ||
    "Transaksi gagal.";

  const ref =
    db
      .collection(
        TRANSACTION_COLLECTION
      )
      .doc(
        normalizedTransactionId
      );

  await db.runTransaction(
    async (transaction) => {
      const snap =
        await transaction.get(
          ref
        );

      if (!snap.exists) {
        throw new Error(
          "TRANSACTION_NOT_FOUND"
        );
      }

      const data =
        snap.data() || {};

      const currentStatus =
        String(
          data.status ||
            STATUS.PENDING
        )
          .trim()
          .toUpperCase();

      /*
      |------------------------------------------------------------
      | SUCCESS = TERMINAL
      |------------------------------------------------------------
      |
      | Jangan pernah mengubah transaksi sukses menjadi gagal.
      |
      */

      if (
        currentStatus ===
        STATUS.SUCCESS
      ) {
        return;
      }

      /*
      |------------------------------------------------------------
      | FAILED = IDEMPOTENT
      |------------------------------------------------------------
      |
      | Tidak perlu membuat perubahan status kedua kali.
      |
      */

      if (
        currentStatus ===
        STATUS.FAILED
      ) {
        return;
      }

      transaction.update(
        ref,
        {
          status:
            STATUS.FAILED,

          provider:
            normalizedProvider ||
            data.provider ||
            null,

          providerReference:
            normalizedProviderReference ||
            data.providerReference ||
            null,

          response:
            response ||
            null,

          failureReason:
            normalizedReason,

          completedAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),

          updatedAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        }
      );
    }
  );
}

/*
|--------------------------------------------------------------------------
| EXPORT
|--------------------------------------------------------------------------
*/

module.exports = {
  TRANSACTION_COLLECTION,
  STATUS,
  createTransactionRequest,
  getTransactionRequest,
  markProcessing,
  markSuccess,
  markFailed,
};
```
