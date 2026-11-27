import { firebaseUidFromVerifiedRequest } from "../_shared/firebase_uid.ts";
import { createAdminClient } from "../_shared/admin_client.ts";

Deno.serve(async (request) => {
  if (request.method !== "POST") return Response.json({ error: "method_not_allowed" }, { status: 405 });
  const uid = firebaseUidFromVerifiedRequest(request);
  if (!uid) return Response.json({ error: "unauthorized" }, { status: 401 });
  let input: Record<string, unknown>;
  try { input = await request.json(); } catch { return Response.json({ error: "invalid_json" }, { status: 400 }); }
  const token = typeof input.token === "string" ? input.token.trim() : "";
  if (token.length < 40 || token.length > 4096) return Response.json({ error: "invalid_token" }, { status: 400 });
  let supabase: ReturnType<typeof createAdminClient>;
  try { supabase = createAdminClient(); } catch { return Response.json({ error: "service_unavailable" }, { status: 503 }); }
  const { error } = await supabase.from("push_tokens").delete().eq("token", token).eq("user_id", uid);
  if (error) return Response.json({ error: "unregistration_failed" }, { status: 500 });
  return Response.json({ unregistered: true });
});
