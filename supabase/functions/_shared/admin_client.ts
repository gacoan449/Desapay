import { createClient } from "npm:@supabase/supabase-js@2";

export function createAdminClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const namedSecrets = Deno.env.get("SUPABASE_SECRET_KEYS");
  let secretKey = "";
  if (namedSecrets) {
    try { secretKey = JSON.parse(namedSecrets).default || ""; } catch { /* use legacy runtime variable below */ }
  }
  // Legacy variable remains temporarily supported by Supabase; new projects
  // should use the automatically injected named secret key above.
  secretKey ||= Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
  if (!url || !secretKey) throw new Error("Supabase server credentials are unavailable");
  return createClient(url, secretKey, { auth: { persistSession: false, autoRefreshToken: false } });
}
