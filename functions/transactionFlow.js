"use strict";

const crypto = require("crypto");
const admin = require("firebase-admin");
const {defineSecret} = require("firebase-functions/params");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const pinSecurity = require("./pinSecurity");

const db = admin.firestore();
const REGION = "asia-southeast2";
const DIGIFLAZZ_URL = "https://api.digiflazz.com/v1/transaction";
const DIGIFLAZZ_USERNAME = defineSecret("DIGIFLAZZ_USERNAME");
const DIGIFLAZZ_API_KEY = defineSecret("DIGIFLAZZ_API_KEY");
const DIGIFLAZZ_WEBHOOK_SECRET = defineSecret("DIGIFLAZZ_WEBHOOK_SECRET");

function text(value) {
  return typeof value === "string" ? value.trim() : "";
}

function integer(value) {
  const n = Number(value);
  return Number.isSafeInteger(n) ? n : null;
}

function md5(value) {
  return crypto.createHash("md5").update(value, "utf8").digest("hex");
}

function normalizeStatus(value) {
  const status = text(value).toLowerCase();
  if (status === "sukses" || status === "success") return "SUCCESS";
  if (status === "gagal" || status === "failed" || status === "failure") {
    return "FAILED";
  }
  return "PROCESSING";
}

function normalizeRc(value) {
  return text(value);
}

exports.createPpobTransaction = onCall(
    {region: REGION, timeoutSeconds: 30, memory: "256MiB"},
    async (request) => {
      if (!request.auth) throw new HttpsError("unauthenticated", "Silakan login terlebih dahulu.");
      const uid = request.auth.uid;
      const input = request.data || {};
      const requestId = text(input.request_id);
      const sku = text(input.sku || input.buyer_sku_code);
      const customerNo = text(input.customer_no || input.customerNo);
      const type = text(input.type || "PPOB").toUpperCase();
      const category = text(input.category || type).toUpperCase();
      const source = text(input.source || "PPOB").slice(0, 40);

      if (!/^[A-Za-z0-9_-]{8,128}$/.test(requestId)) {
        throw new HttpsError("invalid-argument", "ID transaksi tidak valid.");
      }
      if (!sku || sku.length > 100 || !customerNo || customerNo.length > 100) {
        throw new HttpsError("invalid-argument", "Produk dan nomor tujuan wajib diisi dengan benar.");
      }

      const requestRef = db.collection("transaction_requests").doc(requestId);
      const existing = await requestRef.get();
      if (existing.exists) {
        const old = existing.data() || {};
        if (old.uid !== uid) throw new HttpsError("permission-denied", "Transaksi tidak dapat diakses.");
        if (text(old.sku || old.buyer_sku_code) !== sku ||
            text(old.customerNo || old.customer_no) !== customerNo) {
          throw new HttpsError("already-exists", "ID transaksi sudah digunakan untuk permintaan berbeda.");
        }
        return {success: true, request_id: requestId, status: text(old.status) || "WAITING", reused: true};
      }

      const user = await pinSecurity.assertActiveUser(uid);
      if (user.role !== "user") {
        throw new HttpsError("permission-denied", "Hanya akun pengguna yang dapat melakukan pembelian.");
      }
      const product = await getProduct(sku);
      if (!product) throw new HttpsError("not-found", "Produk tidak ditemukan.");
      const trusted = trustedPrice(product);
      const productData = trusted ? trusted.data : {};
      if (!trusted || productData.active !== true || productData.isTest === true) {
        throw new HttpsError("failed-precondition", "Produk tidak tersedia.");
      }

      await pinSecurity.verifyTransactionPin(uid, text(input.pin || input.transaction_pin));
      const cost = integer(productData.cost) ?? 0;
      const margin = trusted.price - cost;
      const productName = text(productData.name || productData.nama) || sku;
      const now = admin.firestore.FieldValue.serverTimestamp();

      try {
        await requestRef.create({
          requestId,
          transactionId: requestId,
          uid,
          type: type.slice(0, 30),
          category: category.slice(0, 40),
          sku,
          buyer_sku_code: sku,
          productName,
          brand: text(productData.brand) || "",
          customerNo,
          customer_no: customerNo,
          operator: text(input.operator).slice(0, 80),
          amount: trusted.price,
          sellingPrice: trusted.price,
          cost,
          margin,
          paymentMethod: "SALDO_UTAMA",
          status: "WAITING",
          isTest: false,
          testMode: false,
          digiflazzSent: false,
          source,
          categoryScreen: category.slice(0, 40),
          createdAt: now,
          updatedAt: now,
        });
      } catch (error) {
        // A retry with the same request id must not create a second purchase.
        const saved = await requestRef.get();
        const old = saved.data() || {};
        if (!saved.exists || old.uid !== uid ||
            text(old.sku || old.buyer_sku_code) !== sku ||
            text(old.customerNo || old.customer_no) !== customerNo) {
          throw new HttpsError("already-exists", "Permintaan transaksi sudah digunakan.");
        }
        return {success: true, request_id: requestId, status: text(old.status) || "WAITING", reused: true};
      }

      return {success: true, request_id: requestId, status: "WAITING", reused: false};
    },
);

async function getProduct(sku) {
  const direct = await db.collection("products").doc(sku).get();
  if (direct.exists) return direct;

  const query = await db.collection("products")
      .where("buyer_sku_code", "==", sku).limit(1).get();
  if (!query.empty) return query.docs[0];

  return null;
}

function trustedPrice(product) {
  const data = product.data() || {};
  let price = integer(
      data.sellingPrice ?? data.selling_price ??
      data.hargaJual ?? data.harga_jual);

  if (price === null || price <= 0) {
    const cost = integer(data.cost) ?? 0;
    const margin = integer(data.margin) ?? 0;
    price = cost + margin;
  }

  if (price <= 0) return null;
  return {price, data};
}

async function debit(requestRef, uid, amount, sku, customerNo) {
  const userRef = db.collection("users").doc(uid);
  const ledgerRef = db.collection("balance_ledger").doc();
  const mutasiRef = db.collection("mutasi_saldo").doc();

  return db.runTransaction(async (tx) => {
    const requestSnap = await tx.get(requestRef);
    if (!requestSnap.exists) throw new Error("TRANSACTION_NOT_FOUND");
    const requestData = requestSnap.data() || {};

    if (requestData.balanceDebited === true) {
      return {debited: false, saldoAkhir: integer(requestData.saldoAkhir) ?? 0};
    }

    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) throw new Error("USER_NOT_FOUND");
    const saldoAwal = integer((userSnap.data() || {}).balance);
    if (saldoAwal === null || saldoAwal < 0) throw new Error("INVALID_BALANCE");
    if (saldoAwal < amount) throw new Error("INSUFFICIENT_BALANCE");

    const saldoAkhir = saldoAwal - amount;
    tx.update(userRef, {
      balance: saldoAkhir,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(ledgerRef, {
      uid, type: "DEBIT", amount, before: saldoAwal, after: saldoAkhir,
      reason: `Pembelian ${sku} ke ${customerNo}`,
      source: "DIGIFLAZZ", transactionId: requestRef.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(mutasiRef, {
      uid, tipe: "KELUAR", nominal: amount,
      saldoAwal, saldoAkhir,
      keterangan: `Pembelian ${sku} ke ${customerNo}`,
      sumber: "DIGIFLAZZ", transactionId: requestRef.id,
      waktu: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(requestRef, {
      balanceDebited: true,
      balanceRefunded: false,
      amount,
      saldoAwal,
      saldoAkhir,
      debitLedgerId: ledgerRef.id,
      debitMutasiId: mutasiRef.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {debited: true, saldoAkhir};
  });
}

async function writeHistory(requestRef, status, providerData) {
  const snap = await requestRef.get();
  if (!snap.exists) return;
  const data = snap.data() || {};
  const historyRef = db.collection("transactions").doc(requestRef.id);
  const trustedAmount = integer(data.trustedPrice) ?? integer(data.amount) ?? 0;

  await db.runTransaction(async (tx) => {
    const historySnap = await tx.get(historyRef);
    if (historySnap.exists) {
      tx.update(historyRef, {
        status,
        amount: trustedAmount,
        sellingPrice: trustedAmount,
        providerStatus: providerData.status || null,
        providerRc: providerData.rc || null,
        message: providerData.message || null,
        sn: providerData.sn || null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    tx.set(historyRef, {
      transactionId: requestRef.id,
      requestId: requestRef.id,
      uid: data.uid,
      sku: data.buyer_sku_code || data.sku,
      buyer_sku_code: data.buyer_sku_code || data.sku,
      productName: data.productName || null,
      category: data.category || null,
      customerNo: data.customerNo || data.customer_no || null,
      amount: trustedAmount,
      sellingPrice: trustedAmount,
      status,
      providerRefId: data.providerRefId || null,
      providerStatus: providerData.status || null,
      providerRc: providerData.rc || null,
      message: providerData.message || null,
      sn: providerData.sn || null,
      createdAt: data.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

async function notify(uid, title, body, requestId, status) {
  // Deterministic ID + create-only transaction makes notifications idempotent.
  const notificationRef = db.collection("notifications").doc(`${requestId}_${status}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(notificationRef);
    if (snap.exists) return;
    tx.create(notificationRef, {
      uid, title, body, transactionId: requestId, status,
      read: false, createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

async function finalize(requestRef, status, providerData, refundReason) {
  const normalizedStatus = text(status).toUpperCase();
  if (normalizedStatus !== "SUCCESS" && normalizedStatus !== "FAILED") return;

  const ledgerRef = db.collection("balance_ledger").doc();
  const mutasiRef = db.collection("mutasi_saldo").doc();
  const reconciliationRef = db.collection("transaction_reconciliation").doc(requestRef.id);
  const providerFields = {
    providerStatus: providerData.status || null,
    providerRc: providerData.rc || null,
    providerMessage: providerData.message || null,
    providerSn: providerData.sn || null,
    providerData,
  };

  let result;
  try {
    result = await db.runTransaction(async (tx) => {
      const requestSnap = await tx.get(requestRef);
      if (!requestSnap.exists) return {action: "missing"};

      const current = requestSnap.data() || {};
      const currentStatus = text(current.status).toUpperCase();
      const fundsWereRefunded = current.balanceRefunded === true || current.refunded === true;
      // Recover an old FAILED record if its debit was never refunded.
      const unresolvedFailedDebit = currentStatus === "FAILED" &&
        normalizedStatus === "FAILED" &&
        current.balanceDebited === true &&
        !fundsWereRefunded;
      const isTerminal = ["SUCCESS", "FAILED", "RECONCILIATION_REQUIRED"].includes(currentStatus);

      const writeConflict = (reason, nextStatus = currentStatus) => {
        tx.set(reconciliationRef, {
          transactionId: requestRef.id,
          uid: current.uid || null,
          localStatus: currentStatus || null,
          requestedStatus: normalizedStatus,
          providerStatus: providerData.status || null,
          providerRc: providerData.rc || null,
          providerMessage: providerData.message || null,
          reason,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
        tx.update(requestRef, {
          status: nextStatus || "RECONCILIATION_REQUIRED",
          reconciliationRequired: true,
          providerConflict: reason,
          ...providerFields,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {action: "conflict", current, finalStatus: nextStatus};
      };

      // A success reported after any refund is always a reconciliation conflict,
      // even if an older code path already wrote SUCCESS inconsistently.
      if (normalizedStatus === "SUCCESS" && fundsWereRefunded) {
        const nextStatus = currentStatus === "FAILED" ? "FAILED" : "RECONCILIATION_REQUIRED";
        return writeConflict("PROVIDER_SUCCESS_AFTER_REFUND", nextStatus);
      }

      // A terminal state is immutable, except to repair a confirmed failure
      // whose earlier debit was never refunded.
      if (isTerminal && !unresolvedFailedDebit) {
        if (currentStatus === normalizedStatus) {
          tx.update(requestRef, {
            ...providerFields,
            completedAt: current.completedAt || admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          return {action: "finalize", current, finalStatus: currentStatus};
        }
        if (currentStatus === "RECONCILIATION_REQUIRED") {
          return writeConflict("CONFLICT_WHILE_RECONCILIATION_REQUIRED", "RECONCILIATION_REQUIRED");
        }
        return writeConflict(
          normalizedStatus + "_AFTER_" + currentStatus,
          currentStatus
        );
      }

      const now = admin.firestore.FieldValue.serverTimestamp();

      if (normalizedStatus === "SUCCESS") {
        tx.update(requestRef, {
          status: "SUCCESS",
          ...providerFields,
          completedAt: now,
          updatedAt: now,
        });
        return {action: "finalize", current, finalStatus: "SUCCESS"};
      }

      // Failure, refund, and terminal status are committed atomically. If a
      // success callback wins first, this transaction retries and sees SUCCESS.
      let refundInfo = {};
      if (fundsWereRefunded) {
        refundInfo = {
          balanceRefunded: true,
          refundAmount: integer(current.refundAmount) ?? integer(current.trustedPrice) ?? integer(current.amount) ?? 0,
          refundSaldoAwal: integer(current.refundSaldoAwal),
          refundSaldoAkhir: integer(current.refundSaldoAkhir),
          refundLedgerId: current.refundLedgerId || null,
          refundMutasiId: current.refundMutasiId || null,
        };
      } else if (current.balanceDebited === true) {
        const uid = text(current.uid);
        const amount = integer(current.trustedPrice) ?? integer(current.amount);
        if (!uid || amount === null || amount <= 0) {
          throw new Error("INVALID_REFUND_DATA");
        }

        const userRef = db.collection("users").doc(uid);
        const userSnap = await tx.get(userRef);
        if (!userSnap.exists) throw new Error("USER_NOT_FOUND");
        const userData = userSnap.data() || {};
        const saldoAwal = integer(userData.balance);
        if (saldoAwal === null || saldoAwal < 0) throw new Error("INVALID_BALANCE");
        const saldoAkhir = saldoAwal + amount;
        if (!Number.isSafeInteger(saldoAkhir)) throw new Error("BALANCE_OVERFLOW");

        tx.update(userRef, {
          balance: saldoAkhir,
          updatedAt: now,
        });
        tx.create(ledgerRef, {
          uid, type: "REFUND", amount, before: saldoAwal, after: saldoAkhir,
          reason: refundReason || providerData.message || "Refund transaksi Digiflazz",
          source: "DIGIFLAZZ_REFUND", transactionId: requestRef.id,
          createdAt: now,
        });
        tx.create(mutasiRef, {
          uid, tipe: "MASUK", nominal: amount,
          saldoAwal, saldoAkhir,
          keterangan: refundReason || providerData.message || "Refund transaksi Digiflazz",
          sumber: "DIGIFLAZZ_REFUND", transactionId: requestRef.id,
          waktu: now,
        });
        refundInfo = {
          balanceRefunded: true,
          refundAmount: amount,
          refundSaldoAwal: saldoAwal,
          refundSaldoAkhir: saldoAkhir,
          refundLedgerId: ledgerRef.id,
          refundMutasiId: mutasiRef.id,
          refundedAt: now,
        };
      }

      tx.update(requestRef, {
        status: "FAILED",
        ...providerFields,
        ...refundInfo,
        ...(current.balanceDebited !== true && !fundsWereRefunded
          ? {balanceRefunded: false}
          : {}),
        completedAt: now,
        updatedAt: now,
      });
      return {
        action: "finalize",
        current: {...current, ...refundInfo},
        finalStatus: "FAILED",
      };
    });
  } catch (error) {
    // Preserve a concurrently committed terminal state. Otherwise leave the
    // request in a retryable state so the scheduled reconciler can retry refund.
    if (normalizedStatus === "FAILED") {
      try {
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(requestRef);
          if (!snap.exists) return;
          const current = snap.data() || {};
          const currentStatus = text(current.status).toUpperCase();
          if (["SUCCESS", "FAILED", "RECONCILIATION_REQUIRED"].includes(currentStatus)) {
            if (currentStatus === "SUCCESS") {
              tx.set(reconciliationRef, {
                transactionId: requestRef.id,
                uid: current.uid || null,
                localStatus: currentStatus,
                requestedStatus: "FAILED",
                providerStatus: providerData.status || null,
                providerMessage: providerData.message || null,
                reason: "FAILED_CALLBACK_AFTER_SUCCESS",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              }, {merge: true});
              tx.update(requestRef, {
                reconciliationRequired: true,
                providerConflict: "FAILED_CALLBACK_AFTER_SUCCESS",
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            }
            return;
          }
          if (current.balanceRefunded === true) {
            tx.set(reconciliationRef, {
              transactionId: requestRef.id,
              uid: current.uid || null,
              localStatus: currentStatus,
              requestedStatus: "FAILED",
              providerStatus: providerData.status || null,
              providerMessage: providerData.message || null,
              reason: "REFUND_COMMITTED_FINALIZATION_INCOMPLETE",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, {merge: true});
            tx.update(requestRef, {
              status: "RECONCILIATION_REQUIRED",
              reconciliationRequired: true,
              providerConflict: "REFUND_COMMITTED_FINALIZATION_INCOMPLETE",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return;
          }
          tx.update(requestRef, {
            status: "REFUND_PENDING",
            refundError: text(error.message).slice(0, 300),
            ...providerFields,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
      } catch (_) {
        // The caller will receive an error and provider/webhook retries can re-enter.
      }
    }
    throw error;
  }

  if (!result || result.action === "missing" || result.action === "conflict") return;

  const finalStatus = result.finalStatus;
  const current = result.current || {};
  await writeHistory(requestRef, finalStatus, providerData);

  const title = finalStatus === "SUCCESS" ? "Transaksi berhasil" : "Transaksi gagal";
  let body;
  if (finalStatus === "SUCCESS") {
    body = `Transaksi ${current.productName || current.buyer_sku_code || "PPOB"} berhasil.`;
  } else if (current.balanceRefunded === true || current.balanceDebited === true) {
    body = current.balanceRefunded === true
      ? "Transaksi gagal. Saldo telah dikembalikan."
      : "Transaksi gagal. Silakan hubungi CS untuk pemeriksaan saldo.";
  } else {
    body = "Transaksi gagal. Tidak ada saldo yang terpotong.";
  }
  await notify(current.uid, title, body, requestRef.id, finalStatus);
}

async function sendToDigiflazz(requestData, refId) {
  const username = DIGIFLAZZ_USERNAME.value();
  const apiKey = DIGIFLAZZ_API_KEY.value();
  if (!username || !apiKey) throw new Error("Credential Digiflazz belum dikonfigurasi.");

  const sku = text(requestData.buyer_sku_code || requestData.sku);
  const customerNo = text(requestData.customerNo || requestData.customer_no);
  const body = {
    username,
    buyer_sku_code: sku,
    customer_no: customerNo,
    ref_id: refId,
    sign: md5(username + apiKey + refId),
  };

  const response = await fetch(DIGIFLAZZ_URL, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(25000),
  });
  const raw = await response.text();
  let json;
  try {
    json = JSON.parse(raw);
  } catch (_) {
    throw new Error("Respons Digiflazz tidak valid; status transaksi perlu direkonsiliasi.");
  }
  if (!response.ok) throw new Error(`HTTP Digiflazz ${response.status}; status transaksi perlu direkonsiliasi.`);
  return json.data || json;
}

async function processRequest(requestRef) {
  const data = await db.runTransaction(async (tx) => {
    const snap = await tx.get(requestRef);
    if (!snap.exists) return null;
    const current = snap.data() || {};
    if (text(current.status).toUpperCase() !== "WAITING") return null;
    tx.update(requestRef, {
      status: "PROCESSING",
      processingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return current;
  });
  if (!data) return;

  const uid = text(data.uid);
  const sku = text(data.buyer_sku_code || data.sku);
  const customerNo = text(data.customerNo || data.customer_no);
  if (!uid || !sku || !customerNo) {
    await finalize(requestRef, "FAILED", {status: "Gagal", rc: "40", message: "Data transaksi tidak lengkap"}, "Data transaksi tidak lengkap");
    return;
  }

  const userSnap = await db.collection("users").doc(uid).get();
  const userData = userSnap.data() || {};
  const userStatus = text(userData.status).toLowerCase();
  if (!userSnap.exists || userData.role !== "user" || !["aktif", "active"].includes(userStatus)) {
    await finalize(requestRef, "FAILED", {status: "Gagal", rc: "AUTH", message: "Akun tidak aktif atau user tidak valid"}, "Akun tidak aktif atau user tidak valid");
    return;
  }

  const product = await getProduct(sku);
  if (!product) {
    await finalize(requestRef, "FAILED", {status: "Gagal", rc: "PRODUCT", message: "Produk tidak ditemukan"}, "Produk tidak ditemukan");
    return;
  }
  const trusted = trustedPrice(product);
  const productData = trusted ? trusted.data : {};
  if (!trusted || productData.active !== true || productData.isTest === true) {
    await finalize(requestRef, "FAILED", {status: "Gagal", rc: "PRODUCT", message: "Produk tidak tersedia"}, "Produk tidak tersedia");
    return;
  }

  // Validate provider credentials before any balance debit. Missing secrets must
  // never leave a user's balance reserved in a transaction that cannot be sent.
  const username = text(DIGIFLAZZ_USERNAME.value());
  const apiKey = text(DIGIFLAZZ_API_KEY.value());
  if (!username || !apiKey) {
    await finalize(requestRef, "FAILED", {status: "Gagal", rc: "CONFIG", message: "Provider belum siap diproses"}, "Provider belum siap diproses");
    return;
  }

  const trustedCost = integer(productData.cost) ?? 0;
  const providerRefId = text(data.providerRefId) || `dp-${crypto.createHash("sha256").update(requestRef.id, "utf8").digest("hex").slice(0, 32)}`;
  const productName = text(productData.name || productData.nama || data.productName) || sku;
  await requestRef.update({
    trustedPrice: trusted.price,
    amount: trusted.price,
    sellingPrice: trusted.price,
    cost: trustedCost,
    margin: trusted.price - trustedCost,
    productName,
    providerRefId,
    serverValidatedAt: admin.firestore.FieldValue.serverTimestamp(),
    providerDispatchState: "NOT_SENT",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  try {
    await debit(requestRef, uid, trusted.price, sku, customerNo);
  } catch (error) {
    // Debit is atomic with balanceDebited. Re-read through finalize's transaction:
    // if the debit actually committed despite an ambiguous client error, finalize
    // performs the refund; otherwise it simply closes the no-debit failure.
    const insufficient = error.message === "INSUFFICIENT_BALANCE";
    const message = insufficient
      ? "Saldo tidak mencukupi"
      : "Transaksi belum dikirim ke provider karena saldo tidak dapat diamankan.";
    await finalize(
      requestRef,
      "FAILED",
      {
        status: "Gagal",
        rc: insufficient ? "BALANCE" : "PRE_DISPATCH_DEBIT_ERROR",
        message,
      },
      message
    );
    return;
  }

  // A failure while recording this marker happens before the network request
  // is invoked, so refund safely rather than leaving a reserved balance.
  try {
    await requestRef.update({
      providerDispatchState: "IN_FLIGHT",
      providerDispatchStartedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    await finalize(
      requestRef,
      "FAILED",
      {
        status: "Gagal",
        rc: "PRE_DISPATCH_MARKER_ERROR",
        message: "Permintaan belum dikirim ke provider. Saldo akan dikembalikan.",
      },
      "Gagal mencatat status pengiriman sebelum provider dipanggil."
    );
    return;
  }

  // Once the provider request begins, a timeout is ambiguous. Keep the debit
  // and reconcile with the same stable provider reference; never mint a new one.
  try {
    const provider = await sendToDigiflazz({...data, buyer_sku_code: sku, customerNo}, providerRefId);
    const status = normalizeStatus(provider.status);
    await requestRef.update({
      providerStatus: provider.status || null,
      providerRc: normalizeRc(provider.rc),
      providerMessage: provider.message || null,
      providerSn: provider.sn || null,
      providerData: provider,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (status === "SUCCESS") {
      await requestRef.update({providerDispatchState: "CONFIRMED", updatedAt: admin.firestore.FieldValue.serverTimestamp()});
      await finalize(requestRef, "SUCCESS", provider);
    } else if (status === "FAILED") {
      await requestRef.update({providerDispatchState: "CONFIRMED", updatedAt: admin.firestore.FieldValue.serverTimestamp()});
      await finalize(requestRef, "FAILED", provider);
    } else {
      await requestRef.update({
        status: "PROCESSING",
        providerStatus: provider.status || "PENDING",
        providerDispatchState: "UNKNOWN",
        providerMessage: provider.message || "Menunggu konfirmasi provider",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  } catch (error) {
    await requestRef.update({
      status: "PROCESSING",
      providerStatus: "UNKNOWN",
      providerDispatchState: "UNKNOWN",
      providerMessage: "Status provider belum dapat dipastikan. Sistem akan melakukan rekonsiliasi otomatis.",
      lastProviderError: text(error.message).slice(0, 300),
      lastProviderErrorAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handleWebhook(req, res) {
  const rawBody = req.rawBody ? req.rawBody.toString("utf8") : JSON.stringify(req.body || {});
  const received = text(req.get("X-Hub-Signature"));
  const secret = DIGIFLAZZ_WEBHOOK_SECRET.value();
  if (!secret) return res.status(503).send("Webhook secret belum dikonfigurasi");

  const expected = crypto.createHmac("sha1", secret).update(rawBody, "utf8").digest("hex");
  const normalized = received.replace(/^sha1=/i, "").trim().toLowerCase();
  if (!normalized || normalized.length !== expected.length ||
      !crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(normalized))) {
    return res.status(401).send("Invalid signature");
  }

  const payload = req.body && req.body.data ? req.body.data : req.body;
  const refId = text(payload && payload.ref_id);
  if (!refId) return res.status(400).send("Missing ref_id");

  const query = await db.collection("transaction_requests")
      .where("providerRefId", "==", refId).limit(1).get();
  if (query.empty) return res.status(404).send("Transaction not found");

  const requestRef = query.docs[0].ref;
  const status = normalizeStatus(payload.status);
  if (status === "PROCESSING") return res.status(200).send("OK");

  try {
    await finalize(requestRef, status, payload);
    return res.status(200).send("OK");
  } catch (error) {
    return res.status(500).send("Webhook processing failed");
  }
}

exports.processTransactionRequest = onDocumentCreated(
    {
      document: "transaction_requests/{requestId}",
      region: REGION,
      secrets: [DIGIFLAZZ_USERNAME, DIGIFLAZZ_API_KEY],
    },
    async (event) => {
      const requestRef = event.data && event.data.ref;
      if (!requestRef) return;
      try {
        await processRequest(requestRef);
      } catch (error) {
        // Jangan menimpa status refund yang gagal atau status terminal.
        // Jika saldo sudah dipotong dan hasil provider belum pasti, pertahankan
        // transaksi untuk rekonsiliasi; jangan menyatakan gagal/refund secara palsu.
        const latestSnap = await requestRef.get();
        if (!latestSnap.exists) return;
        const latest = latestSnap.data() || {};
        const status = text(latest.status).toUpperCase();

        if (status === "RECONCILIATION_REQUIRED" || status === "REFUND_PENDING") {
          return;
        }

        if (status === "SUCCESS" || status === "FAILED") {
          // The financial terminal transition may already have committed before a
          // history/notification write failed. Retry those idempotent side effects.
          const providerData = latest.providerData && typeof latest.providerData === "object"
            ? latest.providerData
            : {
              status: latest.providerStatus || status,
              rc: latest.providerRc || "",
              message: latest.providerMessage || latest.message || "",
              sn: latest.providerSn || "",
            };
          try {
            await writeHistory(requestRef, status, providerData);
            const title = status === "SUCCESS" ? "Transaksi berhasil" : "Transaksi gagal";
            const body = status === "SUCCESS"
              ? `Transaksi ${latest.productName || latest.buyer_sku_code || "PPOB"} berhasil.`
              : (latest.balanceRefunded === true
                ? "Transaksi gagal. Saldo telah dikembalikan."
                : (latest.balanceDebited === true
                  ? "Transaksi gagal. Silakan hubungi CS untuk pemeriksaan saldo."
                  : "Transaksi gagal. Tidak ada saldo yang terpotong."));
            await notify(latest.uid, title, body, requestRef.id, status);
          } catch (sideEffectError) {
            await requestRef.update({
              finalizationSideEffectError: text(sideEffectError.message).slice(0, 300),
              finalizationSideEffectRetryAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
          return;
        }

        const balanceWasDebited = latest.balanceDebited === true &&
          latest.balanceRefunded !== true;

        await requestRef.update({
          status: balanceWasDebited ? "PROCESSING" : "FAILED",
          providerStatus: balanceWasDebited
            ? (latest.providerStatus || "PENDING")
            : "SYSTEM_ERROR",
          providerMessage: balanceWasDebited
            ? "Status transaksi sedang diverifikasi. Jangan lakukan pembayaran ulang."
            : "Terjadi kesalahan sistem. Silakan hubungi CS.",
          internalError: error.message,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    },
);

exports.reconcilePendingTransactions = onSchedule(
    {
      schedule: "every 5 minutes",
      timeZone: "Asia/Jakarta",
      region: REGION,
      timeoutSeconds: 540,
      maxInstances: 1,
      secrets: [DIGIFLAZZ_USERNAME, DIGIFLAZZ_API_KEY],
    },
    async () => {
      const cutoff = Date.now() - 2 * 60 * 1000;
      const processing = await db.collection("transaction_requests")
          .where("status", "==", "PROCESSING")
          .orderBy("updatedAt", "asc").limit(100).get();

      for (const doc of processing.docs) {
        const data = doc.data() || {};
        const updatedAt = data.updatedAt && typeof data.updatedAt.toDate === "function"
          ? data.updatedAt.toDate().getTime()
          : 0;
        if (updatedAt > cutoff) continue;

        // A refund may have committed while the final status update failed.
        // Close that state without dispatching a fresh provider request.
        if (data.balanceRefunded === true) {
          const knownProviderStatus = normalizeStatus(data.providerStatus);
          if (knownProviderStatus === "FAILED") {
            try {
              await finalize(doc.ref, "FAILED", {
                status: data.providerStatus,
                rc: data.providerRc || "",
                message: data.providerMessage || data.message || "Transaksi gagal",
                sn: data.providerSn || "",
              }, data.providerMessage || "Transaksi gagal");
            } catch (_) {
              // A repeated run will retry history/notification finalization safely.
            }
          } else {
            await db.collection("transaction_reconciliation").doc(doc.id).set({
              transactionId: doc.id,
              uid: data.uid || null,
              localStatus: data.status || "PROCESSING",
              providerStatus: data.providerStatus || null,
              providerMessage: data.providerMessage || null,
              reason: "BALANCE_REFUNDED_PROVIDER_STATUS_UNCONFIRMED",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, {merge: true});
            await doc.ref.update({
              status: "RECONCILIATION_REQUIRED",
              reconciliationRequired: true,
              providerConflict: "BALANCE_REFUNDED_PROVIDER_STATUS_UNCONFIRMED",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
          continue;
        }
        if (data.balanceDebited !== true || !text(data.providerRefId)) continue;

        try {
          const provider = await sendToDigiflazz(data, text(data.providerRefId));
          const status = normalizeStatus(provider.status);
          await doc.ref.update({
            reconciliationAttempts: admin.firestore.FieldValue.increment(1),
            lastReconciledAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          if (status === "SUCCESS" || status === "FAILED") {
            await finalize(doc.ref, status, provider,
                provider.message || "Transaksi gagal berdasarkan status provider");
          } else {
            await doc.ref.update({
              status: "PROCESSING",
              providerStatus: provider.status || "PENDING",
              providerDispatchState: "UNKNOWN",
              providerMessage: provider.message || "Menunggu konfirmasi provider",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        } catch (error) {
          await doc.ref.update({
            reconciliationAttempts: admin.firestore.FieldValue.increment(1),
            lastReconciledAt: admin.firestore.FieldValue.serverTimestamp(),
            lastReconcileError: text(error.message).slice(0, 300),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      // Retry any refund that failed after the provider conclusively reported failure.
      const refundPending = await db.collection("transaction_requests")
          .where("status", "==", "REFUND_PENDING")
          .orderBy("updatedAt", "asc").limit(100).get();
      for (const doc of refundPending.docs) {
        const data = doc.data() || {};
        const updatedAt = data.updatedAt && typeof data.updatedAt.toDate === "function"
          ? data.updatedAt.toDate().getTime()
          : 0;
        if (updatedAt > cutoff || data.providerStatus == null) continue;
        if (normalizeStatus(data.providerStatus) !== "FAILED") continue;
        try {
          await finalize(doc.ref, "FAILED", {
            status: data.providerStatus,
            rc: data.providerRc || "",
            message: data.providerMessage || data.message || "Transaksi gagal",
            sn: data.providerSn || "",
          }, data.providerMessage || "Transaksi gagal");
        } catch (error) {
          // finalize records REFUND_PENDING again; next scheduled run retries it.
        }
      }
    },
);

exports.digiflazzWebhook = onRequest(
    {region: REGION, secrets: [DIGIFLAZZ_WEBHOOK_SECRET]},
    handleWebhook,
);
