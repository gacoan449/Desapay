import { sendFcm } from "../_shared/fcm.ts";
import { createAdminClient } from "../_shared/admin_client.ts";

const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "content-type, x-callback-signature, x-callback-event",
  "access-control-allow-methods": "POST, OPTIONS",
};

function jsonResponse(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json" },
  });
}

function toHex(bytes: Uint8Array): string {
  return Array.from(bytes, (value) => value.toString(16).padStart(2, "0")).join("");
}

function constantTimeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) return false;
  let mismatch = 0;
  for (let i = 0; i < left.length; i++) mismatch |= left.charCodeAt(i) ^ right.charCodeAt(i);
  return mismatch === 0;
}

async function validSignature(rawBody: string, supplied: string, secret: string): Promise<boolean> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(rawBody));
  const received = supplied.replace(/^sha256=/i, "").trim().toLowerCase();
  return constantTimeEqual(toHex(new Uint8Array(signature)), received);
}

function normalizeStatus(value: unknown): "PENDING" | "PROCESSING" | "SUCCESS" | "FAILED" | null {
  const status = String(value || "").trim().toUpperCase();
  if (["PENDING", "WAITING"].includes(status)) return "PENDING";
  if (["PROCESSING", "IN_PROGRESS"].includes(status)) return "PROCESSING";
  if (["SUCCESS", "SUCCEEDED", "PAID", "SETTLED"].includes(status)) return "SUCCESS";
  if (["FAILED", "FAIL", "CANCELLED", "CANCELED", "EXPIRED"].includes(status)) return "FAILED";
  return null;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return jsonResponse(405, { error: "method_not_allowed" });

  const webhookSecret = Deno.env.get("PAYMENT_WEBHOOK_SECRET");
  const firebaseServiceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!webhookSecret || !firebaseServiceAccount) {
    console.error("Webhook environment is incomplete");
    return jsonResponse(503, { error: "service_unavailable" });
  }

  const rawBody = await request.text();
  const signature = request.headers.get("x-callback-signature") || "";
  if (!await validSignature(rawBody, signature, webhookSecret)) {
    return jsonResponse(401, { error: "invalid_signature" });
  }

  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return jsonResponse(400, { error: "invalid_json" });
  }
  // TriPay uses a stable event label, not a unique event ID. Derive our
  // idempotency key from the signed transaction fields instead.
  if ((request.headers.get("x-callback-event") || "").toLowerCase() !== "payment_status") {
    return jsonResponse(400, { error: "invalid_callback_event" });
  }
  const providerRef = String(payload.merchant_ref || "").trim();
  const tripayReference = String(payload.reference || "").trim();
  const status = normalizeStatus(payload.status);
  const totalAmount = Number(payload.total_amount);
  if (!providerRef || providerRef.length > 128 || !tripayReference || tripayReference.length > 128 || !status || !Number.isSafeInteger(totalAmount) || totalAmount <= 0) {
    return jsonResponse(400, { error: "invalid_callback_fields" });
  }
  const eventDigest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(`${tripayReference}\n${providerRef}\n${payload.status}\n${payload.paid_at ?? ""}`),
  );
  const eventId = `tripay_${toHex(new Uint8Array(eventDigest))}`;

  let supabase: ReturnType<typeof createAdminClient>;
  try { supabase = createAdminClient(); } catch { return jsonResponse(503, { error: "service_unavailable" }); }
  const { data: rpcResult, error: updateError } = await supabase.rpc("record_payment_callback", {
    p_provider_ref: providerRef,
    p_event_id: eventId,
    p_status: status,
    p_message: String(payload.note || "").slice(0, 500),
    p_sn: tripayReference.slice(0, 180),
    p_amount: totalAmount,
  });

  if (updateError) {
    console.error("Callback database update failed", updateError.code);
    return jsonResponse(500, { error: "callback_persist_failed" });
  }

  if (!rpcResult?.found) return jsonResponse(404, { error: "transaction_not_found" });
  if (rpcResult.amountMismatch) return jsonResponse(409, { error: "callback_amount_mismatch" });
  if (rpcResult.eventCollision) return jsonResponse(409, { error: "event_id_collision" });
  if (!rpcResult.changed) return jsonResponse(200, {
    success: true,
    duplicate: Boolean(rpcResult.duplicate),
    ignoredTerminal: Boolean(rpcResult.ignoredTerminal),
  });

  const { data: devices, error: tokenError } = await supabase
    .from("push_tokens")
    .select("token")
    .eq("user_id", rpcResult.userId)
    .limit(20);
  if (tokenError) {
    console.error("Push token lookup failed", tokenError.code);
    return jsonResponse(500, { error: "notification_lookup_failed" });
  }

  const title = status === "SUCCESS" ? "Transaksi berhasil" : status === "FAILED" ? "Transaksi gagal" : "Status transaksi diperbarui";
  const body = status === "SUCCESS" ? "Transaksi Anda telah berhasil diproses." :
    status === "FAILED" ? "Transaksi Anda gagal diproses. Periksa riwayat untuk detail." :
      "Status transaksi Anda telah diperbarui.";
  const sendResults = await Promise.all((devices || []).map(async ({ token }) => {
    try {
      const fcmResult = await sendFcm(firebaseServiceAccount, token, title, body, String(rpcResult.transactionId));
      if (fcmResult.unregistered) {
        await supabase.from("push_tokens").delete().eq("token", token).eq("user_id", rpcResult.userId);
      }
      return fcmResult.ok;
    } catch (error) {
      console.error("FCM send failed", error instanceof Error ? error.message : "unknown");
      return false;
    }
  }));

  // Provider receives success once the event is durably stored. FCM is best
  // effort; a retry of the same event remains idempotent at the DB layer.
  return jsonResponse(200, { success: true, notificationSent: sendResults.filter(Boolean).length });
});
