export function firebaseUidFromVerifiedRequest(request: Request): string | null {
  // Supabase's verify_jwt gateway validates the signature and Firebase third-party
  // project integration before this function runs. Claims are checked again here.
  const authHeader = request.headers.get("authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  try {
    const encoded = parts[1].replaceAll("-", "+").replaceAll("_", "/");
    const payload = JSON.parse(atob(encoded + "=".repeat((4 - encoded.length % 4) % 4))) as Record<string, unknown>;
    const uid = typeof payload.sub === "string" ? payload.sub : "";
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") || "";
    const issuer = `https://securetoken.google.com/${projectId}`;
    if (!uid || !projectId || payload.iss !== issuer || payload.aud !== projectId) return null;
    if (typeof payload.exp !== "number" || payload.exp <= Math.floor(Date.now() / 1000)) return null;
    return uid;
  } catch {
    return null;
  }
}
