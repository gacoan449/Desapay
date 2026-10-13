"use strict";

const crypto = require("crypto");
const {promisify} = require("util");
const admin = require("firebase-admin");
const {HttpsError} = require("firebase-functions/v2/https");

const db = admin.firestore();
const pbkdf2 = promisify(crypto.pbkdf2);
const COLLECTION = "transaction_pins";
const PIN_ITERATIONS = 180000;
const PIN_BYTES = 32;
const MAX_FAILED_ATTEMPTS = 5;
const LOCK_MINUTES = 15;

function pinDocument(uid) {
  return db.collection(COLLECTION).doc(uid);
}

function fail(code, message) {
  throw new HttpsError(code, message);
}

function validatePin(pin, field = "PIN") {
  if (typeof pin !== "string" || !/^\d{6}$/.test(pin)) {
    fail("invalid-argument", `${field} harus terdiri dari 6 digit angka.`);
  }
}

function validateNewPin(pin) {
  validatePin(pin, "PIN baru");
  if (/^(\d)\1{5}$/.test(pin) || pin === "123456" || pin === "654321") {
    fail("invalid-argument", "PIN terlalu mudah ditebak.");
  }
}

async function makeHash(pin) {
  const salt = crypto.randomBytes(16).toString("hex");
  const derived = await pbkdf2(pin, salt, PIN_ITERATIONS, PIN_BYTES, "sha256");
  return {
    algorithm: "pbkdf2-sha256",
    salt,
    iterations: PIN_ITERATIONS,
    pinHash: derived.toString("hex"),
    pinUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    failedAttempts: 0,
    lockedUntil: null,
  };
}

async function matches(pin, record) {
  if (record.algorithm === "pbkdf2-sha256" && record.salt && record.pinHash) {
    const iterations = Number(record.iterations);
    if (!Number.isSafeInteger(iterations) || iterations < 100000 || iterations > 1000000) {
      return false;
    }
    const derived = await pbkdf2(pin, record.salt, iterations, PIN_BYTES, "sha256");
    const saved = Buffer.from(String(record.pinHash), "hex");
    return saved.length === derived.length && crypto.timingSafeEqual(saved, derived);
  }

  // Backward-compatible verification for any legacy SHA-256 PIN saved by older builds.
  if (record.pinHash && (!record.algorithm || record.algorithm === "sha256-legacy")) {
    const digest = crypto.createHash("sha256").update(pin, "utf8").digest("hex");
    const saved = Buffer.from(String(record.pinHash), "hex");
    const actual = Buffer.from(digest, "hex");
    return saved.length === actual.length && crypto.timingSafeEqual(saved, actual);
  }
  return false;
}

function lockUntil(record, now) {
  const value = record.lockedUntil || record.pinLockedUntil;
  if (!value || typeof value.toDate !== "function") return null;
  const date = value.toDate();
  return date > now ? date : null;
}

function activeStatus(userData) {
  const status = String(userData.status || "").trim().toLowerCase();
  return status === "aktif" || status === "active";
}

async function assertActiveUser(uid) {
  if (!uid) fail("unauthenticated", "Silakan login terlebih dahulu.");
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) fail("not-found", "Akun pengguna tidak ditemukan.");
  if (!activeStatus(snap.data() || {})) {
    fail("permission-denied", "Akun tidak aktif dan tidak dapat melakukan transaksi.");
  }
  return snap.data() || {};
}

function legacyRecord(userData) {
  const oldHash = userData && typeof userData.pinHash === "string" ? userData.pinHash : "";
  if (!oldHash) return null;
  return {
    algorithm: "sha256-legacy",
    pinHash: oldHash,
    failedAttempts: Number(userData.pinFailedAttempts) || 0,
    lockedUntil: userData.pinLockedUntil || null,
  };
}

async function getTransactionPinStatus(uid) {
  const userRef = db.collection("users").doc(uid);
  const pinRef = pinDocument(uid);
  return db.runTransaction(async (tx) => {
    const [userSnap, pinSnap] = await Promise.all([tx.get(userRef), tx.get(pinRef)]);
    if (!userSnap.exists) fail("not-found", "Akun pengguna tidak ditemukan.");
    const userData = userSnap.data() || {};
    if (!activeStatus(userData)) fail("permission-denied", "Akun tidak aktif.");
    const legacy = legacyRecord(userData);
    if (!pinSnap.exists && legacy) {
      tx.create(pinRef, {
        uid,
        ...legacy,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(userRef, {
        pinHash: admin.firestore.FieldValue.delete(),
        pinFailedAttempts: admin.firestore.FieldValue.delete(),
        pinLockedUntil: admin.firestore.FieldValue.delete(),
      });
      return {hasPin: true};
    }
    return {hasPin: pinSnap.exists || legacy !== null};
  });
}

async function setTransactionPin(uid, pin) {
  validateNewPin(pin);
  const hashRecord = await makeHash(pin);
  const userRef = db.collection("users").doc(uid);
  const pinRef = pinDocument(uid);

  await db.runTransaction(async (tx) => {
    const [userSnap, pinSnap] = await Promise.all([tx.get(userRef), tx.get(pinRef)]);
    if (!userSnap.exists) fail("not-found", "Akun pengguna tidak ditemukan.");
    const userData = userSnap.data() || {};
    if (!activeStatus(userData)) fail("permission-denied", "Akun tidak aktif.");
    if (pinSnap.exists || legacyRecord(userData)) {
      fail("already-exists", "PIN transaksi sudah tersedia. Gunakan menu ubah PIN.");
    }
    tx.create(pinRef, {
      uid,
      ...hashRecord,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  return {success: true};
}

async function verifyTransactionPin(uid, pin) {
  validatePin(pin);
  const userRef = db.collection("users").doc(uid);
  const pinRef = pinDocument(uid);
  const outcome = await db.runTransaction(async (tx) => {
    const [userSnap, pinSnap] = await Promise.all([tx.get(userRef), tx.get(pinRef)]);
    if (!userSnap.exists) return {error: ["not-found", "Akun pengguna tidak ditemukan."]};
    const userData = userSnap.data() || {};
    if (!activeStatus(userData)) return {error: ["permission-denied", "Akun tidak aktif dan tidak dapat melakukan transaksi."]};

    let record = pinSnap.exists ? (pinSnap.data() || {}) : legacyRecord(userData);
    if (!record) return {error: ["failed-precondition", "Buat PIN transaksi terlebih dahulu."]};

    const now = new Date();
    const until = lockUntil(record, now);
    if (until) return {error: ["resource-exhausted", "PIN terkunci sementara. Coba lagi setelah masa penguncian berakhir."]};

    let attempts = Number(record.failedAttempts ?? record.pinFailedAttempts) || 0;
    if (record.lockedUntil || record.pinLockedUntil) attempts = 0;

    const correct = await matches(pin, record);
    if (!correct) {
      attempts += 1;
      const shouldLock = attempts >= MAX_FAILED_ATTEMPTS;
      const updated = {
        uid,
        algorithm: record.algorithm || "sha256-legacy",
        pinHash: record.pinHash,
        failedAttempts: attempts,
        lockedUntil: shouldLock
          ? admin.firestore.Timestamp.fromDate(new Date(now.getTime() + LOCK_MINUTES * 60 * 1000))
          : null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      tx.set(pinRef, updated, {merge: true});
      if (!pinSnap.exists && legacyRecord(userData)) {
        tx.update(userRef, {
          pinHash: admin.firestore.FieldValue.delete(),
          pinFailedAttempts: admin.firestore.FieldValue.delete(),
          pinLockedUntil: admin.firestore.FieldValue.delete(),
        });
      }
      return {
        error: shouldLock
          ? ["resource-exhausted", "PIN salah 5 kali. PIN dikunci selama 15 menit."]
          : ["permission-denied", "PIN transaksi salah."],
      };
    }

    if (record.algorithm !== "pbkdf2-sha256") {
      const upgraded = await makeHash(pin);
      tx.set(pinRef, {
        uid,
        ...upgraded,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(userRef, {
        pinHash: admin.firestore.FieldValue.delete(),
        pinFailedAttempts: admin.firestore.FieldValue.delete(),
        pinLockedUntil: admin.firestore.FieldValue.delete(),
      });
    } else {
      tx.set(pinRef, {
        failedAttempts: 0,
        lockedUntil: null,
        lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    }
    return {success: true};
  });

  if (outcome.error) fail(outcome.error[0], outcome.error[1]);
  return {success: true};
}

async function changeTransactionPin(uid, oldPin, newPin) {
  validatePin(oldPin, "PIN lama");
  validateNewPin(newPin);
  if (oldPin === newPin) fail("invalid-argument", "PIN baru harus berbeda dari PIN lama.");

  const newRecord = await makeHash(newPin);
  const userRef = db.collection("users").doc(uid);
  const pinRef = pinDocument(uid);

  const outcome = await db.runTransaction(async (tx) => {
    const [userSnap, pinSnap] = await Promise.all([tx.get(userRef), tx.get(pinRef)]);
    if (!userSnap.exists) return {error: ["not-found", "Akun pengguna tidak ditemukan."]};
    const userData = userSnap.data() || {};
    if (!activeStatus(userData)) return {error: ["permission-denied", "Akun tidak aktif."]};

    const record = pinSnap.exists ? (pinSnap.data() || {}) : legacyRecord(userData);
    if (!record) return {error: ["failed-precondition", "Anda belum memiliki PIN transaksi."]};

    const now = new Date();
    if (lockUntil(record, now)) {
      return {error: ["resource-exhausted", "PIN terkunci sementara. Coba lagi setelah masa penguncian berakhir."]};
    }

    let attempts = Number(record.failedAttempts ?? record.pinFailedAttempts) || 0;
    if (record.lockedUntil || record.pinLockedUntil) attempts = 0;
    const correct = await matches(oldPin, record);
    if (!correct) {
      attempts += 1;
      const shouldLock = attempts >= MAX_FAILED_ATTEMPTS;
      tx.set(pinRef, {
        uid,
        algorithm: record.algorithm || "sha256-legacy",
        pinHash: record.pinHash,
        failedAttempts: attempts,
        lockedUntil: shouldLock
          ? admin.firestore.Timestamp.fromDate(new Date(now.getTime() + LOCK_MINUTES * 60 * 1000))
          : null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      if (!pinSnap.exists && legacyRecord(userData)) {
        tx.update(userRef, {
          pinHash: admin.firestore.FieldValue.delete(),
          pinFailedAttempts: admin.firestore.FieldValue.delete(),
          pinLockedUntil: admin.firestore.FieldValue.delete(),
        });
      }
      return {
        error: shouldLock
          ? ["resource-exhausted", "PIN salah 5 kali. PIN dikunci selama 15 menit."]
          : ["permission-denied", "PIN lama salah."],
      };
    }

    tx.set(pinRef, {
      uid,
      ...newRecord,
      createdAt: pinSnap.exists && pinSnap.data().createdAt
        ? pinSnap.data().createdAt
        : admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(userRef, {
      pinHash: admin.firestore.FieldValue.delete(),
      pinFailedAttempts: admin.firestore.FieldValue.delete(),
      pinLockedUntil: admin.firestore.FieldValue.delete(),
    });
    return {success: true};
  });

  if (outcome.error) fail(outcome.error[0], outcome.error[1]);
  return {success: true};
}

module.exports = {
  assertActiveUser,
  getTransactionPinStatus,
  setTransactionPin,
  verifyTransactionPin,
  changeTransactionPin,
};
