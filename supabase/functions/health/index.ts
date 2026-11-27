import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (request) => {
  if (request.method !== "GET") return new Response("Method not allowed", { status: 405 });
  const url = Deno.env.get("SUPABASE_URL") || "";
  const namedSecrets = Deno.env.get("SUPABASE_SECRET_KEYS") || "{}";
  let key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
  try { key ||= JSON.parse(namedSecrets).default || ""; } catch { /* use legacy env fallback */ }
  if (!url || !key) return new Response("Unavailable", { status: 503 });
  const supabase = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
  const { error } = await supabase.from("health_probe").select("id").eq("id", true).maybeSingle();
  if (error) return new Response("Unavailable", { status: 503 });
  return new Response("ok", { status: 200, headers: { "content-type": "text/plain" } });
});
