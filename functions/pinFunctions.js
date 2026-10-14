"use strict";

const crypto = require("crypto");
const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");

const db = admin.firestore();
const REGION = "asia-southeast2";
const MAX_ATTEMPTS = 5;
const LOCK_MS = 15 * 60 * 1000;
const AUTH_TTL_MS = 5 * 60 * 1000;

function requireAuth(request) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Silakan login kembali.");
  return request.auth.uid;
}
function validPin(pin) { return typeof pin === "string" && /^\\d{6}$/.test(pin); }
function weakPin(pin) {
  return /^(\\d)\\1{5}$/.test(pin) || pin === "123456" || pin === "654321";
}
function hashPin(pin, salt) {
  return crypto.scryptSync(pin, salt, 64).toString("hex");
}
function secureEqual(a, b) {
  if (typeof a !== "string" || typeof b !== "string") return false;
  const aa = Buffer.from(a, "hex"), bb = Buffer.from(b, "hex");
  return aa.length === bb.length && aa.length > 0 && crypto.timingSafeEqual(aa, bb);
}
function securityRef(uid) { return db.collection("user_security").doc(uid); }
function fail(message, code = "invalid-argument") { throw new HttpsError(code, message); }

exports.pinHasPin = onCall({region: REGION}, async (request) => {
  const uid = requireAuth(request);
  const snap = await securityRef(uid).get();
  return {hasPin: snap.exists && !!(snap.data() || {}).pinHash};
});

exports.pinCreate = onCall({region: REGION}, async (request) => {
  const uid = requireAuth(request);
  const pin = request.data && request.data.pin;
  if (!validPin(pin)) fail("PIN harus terdiri dari 6 digit angka.");
  if (weakPin(pin)) fail("PIN terlalu mudah ditebak.");
  const ref = securityRef(uid);
  const salt = crypto.randomBytes(16).toString("hex");
  const pinHash = hashPin(pin, salt);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists && (snap.data() || {}).pinHash) fail("PIN sudah dibuat. Gunakan ubah PIN.");
    tx.set(ref, {pinSalt: salt, pinHash, failedAttempts: 0, lockedUntil: null,
      pinCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
      pinUpdatedAt: admin.firestore.FieldValue.serverTimestamp()});
  });
  return {success: true};
});

async function verifyAndUpdate(uid, pin, {changeTo = null, purchase = null} = {}) {
  if (!validPin(pin)) fail("PIN harus terdiri dari 6 digit angka.");
  const ref = securityRef(uid);
  const authToken = purchase ? crypto.randomBytes(32).toString("hex") : null;
  const authorizationRef = purchase ? db.collection("pin_authorizations").doc(authToken) : null;
  const now = Date.now();
  let verificationError = null;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists || !(snap.data() || {}).pinHash) fail("PIN transaksi belum dibuat.", "failed-precondition");
    const data = snap.data();
    const lockedUntil = data.lockedUntil && typeof data.lockedUntil.toMillis === "function" ? data.lockedUntil.toMillis() : 0;
    if (lockedUntil > now) {
      verificationError = "PIN terkunci sementara. Coba lagi nanti.";
      return;
    }
    const expected = hashPin(pin, data.pinSalt || "");
    if (!secureEqual(expected, data.pinHash)) {
      const attempts = (Number.isSafeInteger(data.failedAttempts) ? data.failedAttempts : 0) + 1;
      tx.update(ref, {failedAttempts: attempts >= MAX_ATTEMPTS ? 0 : attempts,
        lockedUntil: attempts >= MAX_ATTEMPTS ? admin.firestore.Timestamp.fromMillis(now + LOCK_MS) : null});
      verificationError = attempts >= MAX_ATTEMPTS
        ? "PIN salah. PIN dikunci selama 15 menit."
        : "PIN salah.";
      return;
    }
    const update = {failedAttempts: 0, lockedUntil: null};
    if (changeTo) {
      const salt = crypto.randomBytes(16).toString("hex");
      update.pinSalt = salt;
      update.pinHash = hashPin(changeTo, salt);
      update.pinUpdatedAt = admin.firestore.FieldValue.serverTimestamp();
    }
    tx.update(ref, update);
    if (purchase) {
      const requestId = String(purchase.requestId || "");
      const sku = String(purchase.sku || "");
      const customerNo = String(purchase.customerNo || "");
      if (!/^[A-Za-z0-9_-]{1,128}$/.test(requestId) || !sku || sku.length > 100 || !customerNo || customerNo.length > 100) {
        fail("Data transaksi tidak valid.");
      }
      tx.create(authorizationRef, {uid, requestId, sku, customerNo, consumed: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(now + AUTH_TTL_MS)});
    }
  });
  if (verificationError) throw new HttpsError("permission-denied", verificationError);
  return authToken;
}

exports.pinVerify = onCall({region: REGION}, async (request) => {
  const uid = requireAuth(request);
  await verifyAndUpdate(uid, request.data && request.data.pin);
  return {success: true};
});

exports.pinChange = onCall({region: REGION}, async (request) => {
  const uid = requireAuth(request);
  const data = request.data || {};
  if (!validPin(data.newPin) || weakPin(data.newPin)) fail("PIN baru harus 6 digit dan tidak mudah ditebak.");
  if (data.newPin === data.oldPin) fail("PIN baru harus berbeda dari PIN lama.");
  await verifyAndUpdate(uid, data.oldPin, {changeTo: data.newPin});
  return {success: true};
});

exports.pinAuthorizePurchase = onCall({region: REGION}, async (request) => {
  const uid = requireAuth(request);
  const data = request.data || {};
  if (!validPin(data.pin)) fail("PIN harus terdiri dari 6 digit angka.");
  const token = await verifyAndUpdate(uid, data.pin, {purchase: {
    requestId: data.requestId, sku: data.sku, customerNo: data.customerNo,
  }});
  return {authorizationId: token};
});
