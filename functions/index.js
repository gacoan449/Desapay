const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

const db = admin.firestore();

const DIGIFLAZZ_USERNAME = defineSecret("DIGIFLAZZ_USERNAME");
const DIGIFLAZZ_API_KEY = defineSecret("DIGIFLAZZ_API_KEY");

const DIGIFLAZZ_URL = "https://api.digiflazz.com/v1/transaction";

// ============================================================
// HELPER
// ============================================================

function makeSignature(username, apiKey, refId) {
  return crypto
    .createHash("md5")
    .update(username + apiKey + refId)
    .digest("hex");
}

function normalizeStatus(status, rc) {
  const s = String(status || "").toLowerCase();
  const r = String(rc || "");

  if (
    s === "sukses" ||
    s === "success" ||
    r === "00"
  ) {
    return "SUCCESS";
  }

  if (
    s === "pending" ||
    s === "process" ||
    s === "processing" ||
    r === "03"
  ) {
    return "PENDING";
  }

  return "FAILED";
}

// ============================================================
// TRANSAKSI PULSA
// ============================================================

exports.beliPulsa = onCall(
  {
    region: "asia-southeast2",
    secrets: [
      DIGIFLAZZ_USERNAME,
      DIGIFLAZZ_API_KEY,
    ],
    timeoutSeconds: 60,
    memory: "256MiB",
  },

  async (request) => {
    // --------------------------------------------------------
    // 1. CEK LOGIN
    // --------------------------------------------------------

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "User belum login."
      );
    }

    const uid = request.auth.uid;

    // --------------------------------------------------------
    // 2. INPUT
    // --------------------------------------------------------

    const data = request.data || {};

    const customerNo = String(
      data.customerNo || ""
    ).trim();

    const sku = String(
      data.sku || ""
    ).trim();

    if (!customerNo) {
      throw new HttpsError(
        "invalid-argument",
        "Nomor HP belum diisi."
      );
    }

    if (!/^08[0-9]{8,13}$/.test(customerNo)) {
      throw new HttpsError(
        "invalid-argument",
        "Nomor HP tidak valid."
      );
    }

    if (!sku) {
      throw new HttpsError(
        "invalid-argument",
        "SKU produk tidak valid."
      );
    }

    // --------------------------------------------------------
    // 3. CARI PRODUK
    // --------------------------------------------------------

    const productQuery = await db
      .collection("products")
      .where("active", "==", true)
      .where("sku", "==", sku)
      .limit(1)
      .get();

    if (productQuery.empty) {
      throw new HttpsError(
        "not-found",
        "Produk tidak ditemukan atau sudah tidak aktif."
      );
    }

    const productDoc = productQuery.docs[0];

    const product = productDoc.data();

    const cost = Number(product.cost || 0);
    const margin = Number(product.margin || 0);

    const sellingPrice =
      Number(
        product.sellingPrice ||
        (cost + margin)
      );

    if (sellingPrice <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Harga produk tidak valid."
      );
    }

    // --------------------------------------------------------
    // 4. BUAT REF ID
    // --------------------------------------------------------

    const transactionRef = db
      .collection("transactions")
      .doc();

    const refId = transactionRef.id;

    const userRef = db
      .collection("users")
      .doc(uid);

    // --------------------------------------------------------
    // 5. POTONG SALDO SECARA ATOMIC
    // --------------------------------------------------------

    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);

      if (!userSnap.exists) {
        throw new HttpsError(
          "not-found",
          "Data pengguna tidak ditemukan."
        );
      }

      const userData = userSnap.data() || {};

      const balance =
        Number(userData.balance || 0);

      if (balance < sellingPrice) {
        throw new HttpsError(
          "failed-precondition",
          `Saldo tidak cukup. Saldo Anda Rp ${balance.toLocaleString("id-ID")}.`
        );
      }

      const newBalance =
        balance - sellingPrice;

      tx.update(userRef, {
        balance: newBalance,
        updatedAt:
          admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.set(transactionRef, {
        transactionId: refId,
        refId: refId,

        uid: uid,

        type: "PULSA",
        category: "PULSA",

        sku: sku,

        productName:
          String(
            product.name ||
            product.product_name ||
            "-"
          ),

        brand:
          String(
            product.brand ||
            ""
          ),

        customerNo: customerNo,

        amount: sellingPrice,

        cost: cost,
        margin: margin,

        status: "PROCESSING",

        paymentMethod: "SALDO_UTAMA",

        balanceBefore: balance,
        balanceAfter: newBalance,

        createdAt:
          admin.firestore.FieldValue.serverTimestamp(),

        updatedAt:
          admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // --------------------------------------------------------
    // 6. KIRIM KE DIGIFLAZZ
    // --------------------------------------------------------

    const username =
      DIGIFLAZZ_USERNAME.value();

    const apiKey =
      DIGIFLAZZ_API_KEY.value();

    const sign =
      makeSignature(
        username,
        apiKey,
        refId
      );

    const body = {
      username: username,

      buyer_sku_code: sku,

      customer_no: customerNo,

      ref_id: refId,

      sign: sign,

      // ======================================================
      // UNTUK TESTING DIGIFLAZZ
      // Hapus/comment baris ini saat production.
      // ======================================================
      testing: true,
    };

    let responseData;

    try {
      const response = await fetch(
        DIGIFLAZZ_URL,
        {
          method: "POST",

          headers: {
            "Content-Type":
              "application/json",
          },

          body: JSON.stringify(body),
        }
      );

      responseData =
        await response.json();

    } catch (error) {
      // ------------------------------------------------------
      // API TIDAK TERHUBUNG
      // ------------------------------------------------------

      await transactionRef.update({
        status: "FAILED",

        rc: "BACKEND_ERROR",

        message:
          "Gagal menghubungi Digiflazz.",

        updatedAt:
          admin.firestore.FieldValue.serverTimestamp(),
      });

      await refundBalance(
        uid,
        sellingPrice,
        refId
      );

      throw new HttpsError(
        "unavailable",
        "Server Digiflazz tidak dapat dihubungi."
      );
    }

    const result =
      responseData?.data ||
      responseData ||
      {};

    const digiflazzStatus =
      normalizeStatus(
        result.status,
        result.rc
      );

    // --------------------------------------------------------
    // 7. SUCCESS
    // --------------------------------------------------------

    if (
      digiflazzStatus === "SUCCESS"
    ) {
      await transactionRef.update({
        status: "SUCCESS",

        rc:
          String(
            result.rc || "00"
          ),

        message:
          String(
            result.message ||
            "Transaksi berhasil."
          ),

        sn:
          String(
            result.sn || ""
          ),

        digiflazzPrice:
          Number(
            result.price ||
            cost
          ),

        buyerLastSaldo:
          result.buyer_last_saldo ??
          null,

        updatedAt:
          admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,

        transactionId: refId,

        status: "SUCCESS",

        message:
          String(
            result.message ||
            "Transaksi berhasil."
          ),

        sn:
          String(
            result.sn || ""
          ),
      };
    }

    // --------------------------------------------------------
    // 8. PENDING
    // --------------------------------------------------------

    if (
      digiflazzStatus === "PENDING"
    ) {
      await transactionRef.update({
        status: "PENDING",

        rc:
          String(
            result.rc || "03"
          ),

        message:
          String(
            result.message ||
            "Transaksi sedang diproses."
          ),

        sn:
          String(
            result.sn || ""
          ),

        buyerLastSaldo:
          result.buyer_last_saldo ??
          null,

        updatedAt:
          admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,

        transactionId: refId,

        status: "PENDING",

        message:
          String(
            result.message ||
            "Transaksi sedang diproses."
          ),

        sn:
          String(
            result.sn || ""
          ),
      };
    }

    // --------------------------------------------------------
    // 9. FAILED -> REFUND
    // --------------------------------------------------------

    await transactionRef.update({
      status: "FAILED",

      rc:
        String(
          result.rc || "FAILED"
        ),

      message:
        String(
          result.message ||
          "Transaksi gagal."
        ),

      updatedAt:
        admin.firestore.FieldValue.serverTimestamp(),
    });

    await refundBalance(
      uid,
      sellingPrice,
      refId
    );

    return {
      success: false,

      transactionId: refId,

      status: "FAILED",

      message:
        String(
          result.message ||
          "Transaksi gagal. Saldo dikembalikan."
        ),
    };
  }
);

// ============================================================
// REFUND SALDO
// ============================================================

async function refundBalance(
  uid,
  amount,
  transactionId
) {
  const userRef = db
    .collection("users")
    .doc(uid);

  await db.runTransaction(
    async (tx) => {
      const userSnap =
        await tx.get(userRef);

      if (!userSnap.exists) {
        return;
      }

      const data =
        userSnap.data() || {};

      const currentBalance =
        Number(data.balance || 0);

      tx.update(userRef, {
        balance:
          currentBalance + amount,

        updatedAt:
          admin.firestore.FieldValue
            .serverTimestamp(),
      });
    }
  );

  await db
    .collection("transactions")
    .doc(transactionId)
    .update({
      refunded: true,

      refundedAmount: amount,

      refundedAt:
        admin.firestore.FieldValue
          .serverTimestamp(),
    });
}

// ============================================================
// CALLBACK DIGIFLAZZ
// ============================================================

exports.digiflazzCallback = onRequest(
  {
    region: "asia-southeast2",
  },

  async (req, res) => {
    try {
      const data =
        req.body?.data ||
        req.body ||
        {};

      const refId =
        String(
          data.ref_id || ""
        );

      if (!refId) {
        res
          .status(400)
          .json({
            success: false,
            message:
              "ref_id kosong.",
          });

        return;
      }

      const transactionRef =
        db
          .collection("transactions")
          .doc(refId);

      const transactionSnap =
        await transactionRef.get();

      if (!transactionSnap.exists) {
        res
          .status(404)
          .json({
            success: false,
            message:
              "Transaksi tidak ditemukan.",
          });

        return;
      }

      const transaction =
        transactionSnap.data() || {};

      const status =
        normalizeStatus(
          data.status,
          data.rc
        );

      // ------------------------------------------------------
      // CALLBACK SUCCESS
      // ------------------------------------------------------

      if (
        status === "SUCCESS"
      ) {
        await transactionRef.update({
          status: "SUCCESS",

          rc:
            String(
              data.rc || "00"
            ),

          message:
            String(
              data.message ||
              "Transaksi berhasil."
            ),

          sn:
            String(
              data.sn || ""
            ),

          digiflazzStatus:
            data.status || "",

          updatedAt:
            admin.firestore.FieldValue
              .serverTimestamp(),
        });

        res.json({
          success: true,
        });

        return;
      }

      // ------------------------------------------------------
      // CALLBACK FAILED
      // ------------------------------------------------------

      if (
        status === "FAILED"
      ) {
        await transactionRef.update({
          status: "FAILED",

          rc:
            String(
              data.rc || "FAILED"
            ),

          message:
            String(
              data.message ||
              "Transaksi gagal."
            ),

          digiflazzStatus:
            data.status || "",

          updatedAt:
            admin.firestore.FieldValue
              .serverTimestamp(),
        });

        // Refund hanya jika sebelumnya
        // masih PENDING/PROCESSING
        if (
          transaction.status ===
            "PENDING" ||
          transaction.status ===
            "PROCESSING"
        ) {
          await refundBalance(
            transaction.uid,
            Number(
              transaction.amount || 0
            ),
            refId
          );
        }

        res.json({
          success: true,
        });

        return;
      }

      // ------------------------------------------------------
      // MASIH PENDING
      // ------------------------------------------------------

      await transactionRef.update({
        status: "PENDING",

        rc:
          String(
            data.rc || "03"
          ),

        message:
          String(
            data.message ||
            "Transaksi masih diproses."
          ),

        updatedAt:
          admin.firestore.FieldValue
            .serverTimestamp(),
      });

      res.json({
        success: true,
      });

    } catch (error) {
      console.error(
        "DIGIFLAZZ CALLBACK ERROR:",
        error
      );

      res
        .status(500)
        .json({
          success: false,
          message:
            "Internal server error.",
        });
    }
  }
);
