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

function generateTransactionId(uid) {
  return `trx-${Date.now()}-${uid.slice(0, 8)}-${crypto
    .randomBytes(6)
    .toString("hex")}`;
}

function safeInteger(value) {
  const number = Number(value);

  if (!Number.isSafeInteger(number)) {
    return null;
  }

  return number;
}

async function createTransactionRequest({
  uid,
  productCode,
  customerNo,
  serviceType,
  amount,
  metadata = {},
}) {
  if (!uid) {
    throw new Error("UID_REQUIRED");
  }

  if (!productCode) {
    throw new Error("PRODUCT_CODE_REQUIRED");
  }

  if (!customerNo) {
    throw new Error("CUSTOMER_NO_REQUIRED");
  }

  const nominal = safeInteger(amount);

  if (nominal === null || nominal <= 0) {
    throw new Error("INVALID_AMOUNT");
  }

  const transactionId = generateTransactionId(uid);

  const transactionRef = db
    .collection(TRANSACTION_COLLECTION)
    .doc(transactionId);

  await transactionRef.create({
    transactionId,

    uid,

    productCode,

    customerNo,

    serviceType: serviceType || "PPOB",

    amount: nominal,

    status: STATUS.PENDING,

    provider: null,

    providerReference: null,

    response: null,

    metadata,

    createdAt:
      admin.firestore.FieldValue.serverTimestamp(),

    updatedAt:
      admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    transactionId,
    status: STATUS.PENDING,
  };
}

async function getTransactionRequest(transactionId) {
  if (!transactionId) {
    throw new Error("TRANSACTION_ID_REQUIRED");
  }

  const ref = db
    .collection(TRANSACTION_COLLECTION)
    .doc(transactionId);

  const snap = await ref.get();

  if (!snap.exists) {
    throw new Error("TRANSACTION_NOT_FOUND");
  }

  return {
    id: snap.id,
    ...snap.data(),
  };
}

async function markProcessing(transactionId, provider) {
  const ref = db
    .collection(TRANSACTION_COLLECTION)
    .doc(transactionId);

  await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(ref);

    if (!snap.exists) {
      throw new Error("TRANSACTION_NOT_FOUND");
    }

    const data = snap.data();

    if (
      data.status === STATUS.SUCCESS ||
      data.status === STATUS.FAILED
    ) {
      return;
    }

    transaction.update(ref, {
      status: STATUS.PROCESSING,

      provider: provider || null,

      updatedAt:
        admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

async function markSuccess({
  transactionId,
  provider,
  providerReference,
  response,
}) {
  const ref = db
    .collection(TRANSACTION_COLLECTION)
    .doc(transactionId);

  await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(ref);

    if (!snap.exists) {
      throw new Error("TRANSACTION_NOT_FOUND");
    }

    const data = snap.data();

    if (data.status === STATUS.SUCCESS) {
      return;
    }

    transaction.update(ref, {
      status: STATUS.SUCCESS,

      provider: provider || data.provider || null,

      providerReference:
        providerReference ||
        data.providerReference ||
        null,

      response: response || null,

      completedAt:
        admin.firestore.FieldValue.serverTimestamp(),

      updatedAt:
        admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

async function markFailed({
  transactionId,
  provider,
  providerReference,
  response,
  reason,
}) {
  const ref = db
    .collection(TRANSACTION_COLLECTION)
    .doc(transactionId);

  await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(ref);

    if (!snap.exists) {
      throw new Error("TRANSACTION_NOT_FOUND");
    }

    const data = snap.data();

    if (data.status === STATUS.SUCCESS) {
      return;
    }

    transaction.update(ref, {
      status: STATUS.FAILED,

      provider: provider || data.provider || null,

      providerReference:
        providerReference ||
        data.providerReference ||
        null,

      response: response || null,

      failureReason:
        reason || "Transaksi gagal.",

      completedAt:
        admin.firestore.FieldValue.serverTimestamp(),

      updatedAt:
        admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

module.exports = {
  TRANSACTION_COLLECTION,
  STATUS,
  createTransactionRequest,
  getTransactionRequest,
  markProcessing,
  markSuccess,
  markFailed,
};
