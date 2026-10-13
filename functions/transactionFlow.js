"use strict";

const crypto = require("crypto");
const admin = require("firebase-admin");
const {defineSecret} = require("firebase-functions/params");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");

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

function isAccountDisabled(userData) {
  const data = userData || {};
  const status = text(data.status || data.accountStatus).toLowerCase();
  return data.disabled === true ||
    data.isDisabled === true ||
    data.isActive === false ||
    ["disabled", "blocked", "suspended", "nonaktif", "dinonaktifkan", "diblokir"].includes(status);
}

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

async function refund(requestRef, reason) {
  const ledgerRef = db.collection("balance_ledger").doc();
  const mutasiRef = db.collection("mutasi_saldo").doc();

  return db.runTransaction(async (tx) => {
    const requestSnap = await tx.get(requestRef);
    if (!requestSnap.exists) throw new Error("TRANSACTION_NOT_FOUND");
    const data = requestSnap.data() || {};
    const currentStatus = text(data.status).toUpperCase();

    if (currentStatus === "SUCCESS" || data.balanceRefunded === true) {
      return {refunded: false};
    }
    if (data.balanceDebited !== true) return {refunded: false};

    const uid = text(data.uid);
    const amount = integer(data.amount);
    if (!uid || amount === null || amount <= 0) {
      throw new Error("INVALID_REFUND_DATA");
    }

    const userRef = db.collection("users").doc(uid);
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) throw new Error("USER_NOT_FOUND");
    const saldoAwal = integer((userSnap.data() || {}).balance);
    if (saldoAwal === null || saldoAwal < 0) throw new Error("INVALID_BALANCE");
    const saldoAkhir = saldoAwal + amount;
    if (!Number.isSafeInteger(saldoAkhir)) throw new Error("BALANCE_OVERFLOW");

    tx.update(userRef, {
      balance: saldoAkhir,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(ledgerRef, {
      uid, type: "REFUND", amount, before: saldoAwal, after: saldoAkhir,
      reason: reason || "Refund transaksi Digiflazz",
      source: "DIGIFLAZZ_REFUND", transactionId: requestRef.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(mutasiRef, {
      uid, tipe: "MASUK", nominal: amount,
      saldoAwal, saldoAkhir,
      keterangan: reason || "Refund transaksi Digiflazz",
      sumber: "DIGIFLAZZ_REFUND", transactionId: requestRef.id,
      waktu: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(requestRef, {
      balanceRefunded: true,
      refundAmount: amount,
      refundSaldoAwal: saldoAwal,
      refundSaldoAkhir: saldoAkhir,
      refundLedgerId: ledgerRef.id,
      refundMutasiId: mutasiRef.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {refunded: true, saldoAkhir};
  });
}

async function writeHistory(requestRef, status, providerData) {
  const snap = await requestRef.get();
  if (!snap.exists) return;
  const data = snap.data() || {};
  const historyRef = db.collection("transactions").doc(requestRef.id);

  await db.runTransaction(async (tx) => {
    const historySnap = await tx.get(historyRef);
    if (historySnap.exists) {
      tx.update(historyRef, {
        status,
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
      amount: integer(data.amount) ?? 0,
      sellingPrice: integer(data.trustedPrice) ?? integer(data.amount) ?? 0,
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
  await db.collection("notifications").add({
    uid, title, body, transactionId: requestId, status,
    read: false, createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function finalize(requestRef, status, providerData, refundReason) {
  const requestSnap = await requestRef.get();
  if (!requestSnap.exists) return;
  const current = requestSnap.data() || {};
  const currentStatus = text(current.status).toUpperCase();

  if (currentStatus === "SUCCESS" || currentStatus === "FAILED") return;

  if (status === "FAILED") {
    try {
      await refund(requestRef, refundReason || providerData.message || "Transaksi gagal");
    } catch (error) {
      await requestRef.update({
        status: "REFUND_PENDING",
        refundError: error.message,
        providerStatus: providerData.status || null,
        providerRc: providerData.rc || null,
        message: providerData.message || "Refund gagal diproses",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      throw error;
    }
  }

  await requestRef.update({
    status,
    providerStatus: providerData.status || null,
    providerRc: providerData.rc || null,
    providerMessage: providerData.message || null,
    providerSn: providerData.sn || null,
    providerData,
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await writeHistory(requestRef, status, providerData);

  const title = status === "SUCCESS" ? "Transaksi berhasil" : "Transaksi gagal";
  const body = status === "SUCCESS"
    ? `Transaksi ${current.productName || current.buyer_sku_code || "PPOB"} berhasil.`
    : `Transaksi gagal. Saldo dikembalikan.`;
  await notify(current.uid, title, body, requestRef.id, status);
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
  });
  const json = await response.json();
  if (!response.ok) throw new Error(`HTTP Digiflazz ${response.status}`);
  return json.data || json;
}

async function processRequest(requestRef) {
  const snap = await requestRef.get();
  if (!snap.exists) return;
  const data = snap.data() || {};
  if (text(data.status).toUpperCase() !== "WAITING") return;

  await requestRef.update({
    status: "PROCESSING",
    processingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const uid = text(data.uid);
  const sku = text(data.buyer_sku_code || data.sku);
  const customerNo = text(data.customerNo || data.customer_no);
  if (!uid || !sku || !customerNo) {
    await finalize(requestRef, "FAILED", {status: "Gagal", rc: "40", message: "Data transaksi tidak lengkap"}, "Data transaksi tidak lengkap");
    return;
  }

  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists || (userSnap.data() || {}).role !== "user" || isAccountDisabled(userSnap.data())) {
    await finalize(requestRef, "FAILED", {status: "Gagal", rc: "AUTH", message: "User tidak valid"}, "User tidak valid");
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

  await requestRef.update({
    trustedPrice: trusted.price,
    amount: trusted.price,
    sellingPrice: trusted.price,
    productName: productData.name || productData.nama || data.productName || sku,
    serverValidatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const providerRefId = `dp-${Date.now()}-${requestRef.id.slice(0, 16)}`;
  await requestRef.update({
    providerRefId,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  try {
    await debit(requestRef, uid, trusted.price, sku, customerNo);
  } catch (error) {
    const message = error.message === "INSUFFICIENT_BALANCE"
      ? "Saldo tidak mencukupi"
      : "Transaksi tidak dapat diproses";
    await requestRef.update({
      status: "FAILED",
      providerStatus: "NOT_SENT",
      providerMessage: message,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await writeHistory(requestRef, "FAILED", {status: "Gagal", rc: "BALANCE", message});
    await notify(uid, "Transaksi gagal", message, requestRef.id, "FAILED");
    return;
  }

  try {
    await requestRef.update({
      providerSubmissionStartedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
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
      await finalize(requestRef, "SUCCESS", provider);
    } else if (status === "FAILED") {
      await finalize(requestRef, "FAILED", provider);
    }
  } catch (error) {
    await requestRef.update({
      status: "PROCESSING",
      providerStatus: "PENDING",
      providerMessage: "Menunggu status provider",
      providerError: error.message,
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

        if (status === "SUCCESS" || status === "FAILED" || status === "REFUND_PENDING") {
          return;
        }

        const balanceWasDebited = latest.balanceDebited === true &&
          latest.balanceRefunded !== true;
        const providerMayHaveReceived = Boolean(latest.providerSubmissionStartedAt);

        if (balanceWasDebited && !providerMayHaveReceived) {
          try {
            await finalize(requestRef, "FAILED", {
              status: "Gagal", rc: "NOT_SENT",
              message: "Transaksi gagal sebelum dikirim ke provider; saldo dikembalikan.",
            }, "Gagal sebelum pengiriman ke provider");
            return;
          } catch (refundError) {
            const afterRefundFailure = await requestRef.get();
            const afterData = afterRefundFailure.data() || {};
            await requestRef.update({
              status: "REFUND_PENDING",
              refundError: refundError.message,
              providerStatus: "NOT_SENT",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return;
          }
        }

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

exports.digiflazzWebhook = onRequest(
    {region: REGION, secrets: [DIGIFLAZZ_WEBHOOK_SECRET]},
    handleWebhook,
);
