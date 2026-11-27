# DesaPay: Supabase + Firebase Spark

This scaffold uses Supabase Postgres, Edge Functions, and private Storage as the
backend for new transaction/callback flows. Firebase remains for Auth, FCM, and
Crashlytics. It does not use Firebase Cloud Functions or Firebase Storage for
these new flows.

```text
┌────────────────────── APK ───────────────────────┐
│ Firebase Auth ID token ──┐                        │
│ Supabase publishable key ├── Supabase SDK ────────┼──> Postgres + RLS
│ FCM token ────────────────┘                        │     private Storage
│ Firebase Messaging / Crashlytics                  │
└──────────────────────────────────────────────────┘
                                                   │
Third-party provider ── HTTPS POST + HMAC ──> Supabase Edge Function
                                                   │
                                  verify signature, update transaction
                                  and send FCM HTTP v1 via service account
                                                   │
                                                   └──> Firebase FCM
```

## What this repository contains

- `supabase/migrations/202611260001_hybrid_backend.sql`: starter `transactions`,
  `push_tokens`, private `user-files` and `profile-images` buckets, public-read
  `product-images` for catalog items, and owner-scoped Storage RLS.
- `supabase/functions/payment-webhook`: public HTTPS webhook; verifies HMAC-SHA256
  over the raw request body before updating a known `provider_ref` and notifying
  the device via FCM HTTP v1.
- `supabase/functions/register-device` and `unregister-device`: verify a Firebase
  ID token at the Supabase gateway, check its Firebase issuer/audience again, and
  manage the caller's FCM token server-side.
- `supabase/functions/health`: authenticated probe that makes a real DB query.
- `lib/services/hybrid_backend_service.dart`: optional APK setup for Supabase,
  Firebase Messaging and Crashlytics.

This is a secure integration scaffold, not a completed migration of every old
DesaPay feature. The existing app still contains Firestore/Cloud Functions call
sites. Move each callable/balance/withdrawal/product workflow to Supabase Edge
Functions and PostgreSQL before removing Firebase Blaze-dependent code. Do not
enable or deploy Firebase Functions for the Supabase-only path.

## 1. Dashboard setup — manual

1. Supabase Free project `DesapayProject` (`sukqrxsolvukqunrurfw`) is active.
   Firebase Auth third-party integration is enabled for `desapay-9918f`.
   The RLS/bucket SQL has been applied from the Dashboard SQL Editor. Because
   Dashboard SQL runs are not recorded in the CLI migration history, the checked
   in migration is idempotent and drops/recreates its named policies before a
   later CLI apply.
2. Firebase project `desapay-9918f` has Email/Password Auth and FCM HTTP v1
   enabled. Android app package is currently `com.example.desapay`.
3. Dedicated service account `desapay-fcm-sender@desapay-9918f.iam.gserviceaccount.com`
   was created with **Firebase Cloud Messaging API Admin**. Its JSON key was
   stored in Supabase Edge Function Secrets as `FIREBASE_SERVICE_ACCOUNT_JSON`.
   Do not add it to this repository or APK.
4. Supabase functions `health`, `register-device`, and `unregister-device` are
   deployed. Health returned `200 ok`; device-token calls without a Firebase
   user token returned `401 unauthorized`.
5. **Payment callback is not live yet.** Do not register a production callback URL
   until the real TriPay Private Key is saved in Supabase and `payment-webhook`
   is deployed. The intended callback URL is:

   ```text
   https://sukqrxsolvukqunrurfw.supabase.co/functions/v1/payment-webhook
   ```

   For TriPay, configure the `payment_status` event. The Edge Function checks
   `X-Callback-Signature` as `HMAC-SHA256(exact_raw_HTTP_body,
   PAYMENT_WEBHOOK_SECRET)`, maps `merchant_ref` to our `provider_ref`, derives
   an idempotency key from signed callback fields, and checks `total_amount`
   against the stored amount. `PAYMENT_WEBHOOK_SECRET` must be the actual TriPay
   private key from the merchant account. Success replies use TriPay's required
   `{ "success": true }` body. Refund-ledger accounting is not implemented.

## 2. Supabase CLI deploy

Install the Supabase CLI, then from the repository root:

```powershell
supabase login
supabase link --project-ref sukqrxsolvukqunrurfw
```

Firebase Auth project ID `desapay-9918f` and the Supabase project ref are already
set in config and RLS.

Supabase injects its named server secret key map and project URL into Edge
Functions automatically. Create an ignored local `.env.supabase` file for the
application/provider secrets only. Keep the Firebase service-account JSON on one
line inside the quoted value:

```dotenv
PAYMENT_WEBHOOK_SECRET=<tripay-private-key-from-merchant-dashboard>
FIREBASE_PROJECT_ID=desapay-9918f
FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account","project_id":"...","private_key":"...","client_email":"...","token_uri":"https://oauth2.googleapis.com/token"}'
```

Set these server-only values and apply the SQL:

```powershell
supabase secrets set --env-file .env.supabase
supabase db push
```

In Supabase Dashboard → Project Settings → API Keys, ensure a server-only
`default` secret key exists. Edge Functions read it from the platform-injected
`SUPABASE_SECRET_KEYS` map. Never copy it to Flutter. The legacy
`SUPABASE_SERVICE_ROLE_KEY` environment value is only a compatibility fallback.

Deploy the functions manually from the repository root:

```powershell
supabase functions deploy payment-webhook
supabase functions deploy register-device
supabase functions deploy unregister-device
supabase functions deploy health
```

Do **not** use `--no-verify-jwt` for `register-device`, `unregister-device`, or
`health`. Only `payment-webhook` has gateway JWT verification disabled because
TriPay cannot supply a Supabase user JWT; the function authenticates each callback
with HMAC before processing it.

## 2.1 GitHub Actions deployment — Supabase only

`.github/workflows/deploy-functions.yml` deploys the health and device-token Edge
Functions to Supabase. It does not install Firebase CLI and does not deploy
Firebase Cloud Functions, Firebase Storage, or Firestore rules. Add this GitHub
Actions repository secret before enabling the workflow:

```text
SUPABASE_ACCESS_TOKEN=<Supabase personal access token>
```

Create the token in the Supabase account dashboard and store it only in GitHub
Actions Secrets. The project ref is non-secret and is configured in the workflow.
The payment callback remains manual until the real TriPay key has been placed in
Supabase Function Secrets; then deploy it with `supabase functions deploy
payment-webhook --project-ref sukqrxsolvukqunrurfw`.

This workflow change alone does not migrate the remaining Firestore and callable
Cloud Functions code paths in the APK. Those features still need migration to
Supabase before the app can run fully on the Firebase Spark plan.

## 3. APK setup

`supabase_flutter` receives the current Firebase ID token for every request.
Only the URL and publishable key belong in the APK; the publishable key is not
an authorization secret. Never include `service_role`, webhook secret, or the
Firebase service-account JSON in Dart code or build-time client defines.

Add these build arguments to Android release builds:

```text
--dart-define=SUPABASE_URL=https://sukqrxsolvukqunrurfw.supabase.co
--dart-define=SUPABASE_PUBLISHABLE_KEY=<sb_publishable_...>
```

Initialize Firebase first, then `HybridBackendService.initialize()` in `main()`.
It uses Firebase Auth for the session, registers/removes FCM tokens through the
JWT-protected Edge Functions, and reports uncaught release crashes through
Crashlytics. Call `HybridBackendService.unregisterCurrentDevice()` before every
`FirebaseAuth.signOut()` call.

The SQL uses Firebase UID (`sub`, a text value) rather than `auth.uid()` (UUID).
RLS checks Firebase `iss` and `aud`, and the row owner. Clients can read only
their transactions. Clients cannot insert or change transaction rows, provider
references, amounts, or provider results; trusted Edge Functions create and
update them. Push tokens are service-role-only and can only be managed through
verified Edge Functions.

Use object paths like `<FIREBASE_UID>/kyc/front.jpg` in the private
`user-files` bucket. Do not make this bucket public. KYC documents use signed
URLs for previews and the database stores the object path. Profile photos use a
private bucket and signed URLs; only catalog product images are public-read.
Uploads are still restricted to the current Firebase UID folder by RLS. The
owner path policy rejects a path whose first segment is not the current Firebase
UID.

## 4. Public HTTPS, IPs, and keep-alive

Supabase Edge Functions run on a distributed serverless platform with dynamic
egress IPs. The inbound callback uses a stable HTTPS function URL plus HMAC
signature/header secret; it does not depend on a static source IP.

If a provider requires a static IP for **outbound** requests, a free Cloudflare
Worker can be a relay only when the provider accepts the Worker platform's
non-dedicated/dynamic egress or another authentication method. It does not
magically provide a dedicated fixed egress IP. There is no reliable guarantee
of a free, no-card hosted static-IP proxy. Ask the provider to allow
signature-based authentication or use a paid fixed-egress proxy if strict IP
allowlisting is mandatory. Avoid public free proxies for payment traffic and
secrets.

To reduce Supabase Free inactivity pauses, create a UptimeRobot HTTP/API monitor
for:

```text
GET https://sukqrxsolvukqunrurfw.supabase.co/functions/v1/health
Headers: apikey: <SUPABASE_PUBLISHABLE_KEY>
         Authorization: Bearer <SUPABASE_PUBLISHABLE_KEY>
Expected response: 200 `ok`
```

The health endpoint is currently JWT-gated by Supabase and returns no database
details. The publishable key is intended for public clients; never use a
service-role or secret key in the monitor.

UptimeRobot Free currently checks every 5 minutes. Monitoring causes a database
query, which helps count as activity. Supabase says a Free project can still be
paused after about a week of insufficient database activity; a monitor is a
mitigation, not an uptime guarantee. Check Supabase project status/usage and
restore a paused project from the dashboard if needed.

## 5. Release checklist

- [ ] Supabase project ref and Firebase project ID placeholders replaced in
      both config and migration; issuer and audience exactly match Firebase.
- [x] Third-Party Auth → Firebase integration enabled in Supabase Dashboard.
- [x] Initial schema/RLS and three Storage buckets applied in Supabase SQL Editor.
- [ ] Reconcile CLI migration history before first `supabase db push`.
- [ ] Bucket is private; cross-user select/insert/update/delete attempts fail.
- [x] FCM service-account JSON is stored in Supabase Edge Function Secrets.
- [ ] Actual TriPay private key configured as `PAYMENT_WEBHOOK_SECRET`; no `service_role`, webhook secret, or
      service-account key in Git, APK, logs, or provider dashboard URLs.
- [ ] Callback provider is configured for the deployed HTTPS URL and the exact
      HMAC scheme; replay the same event and confirm it does not regress a final
      transaction or send duplicate state changes.
- [x] FCM service account has the Firebase Cloud Messaging API Admin role.
- [x] Health and device-token functions are deployed.
- [ ] Token send works on a test device, logout unregisters its token, and
      invalid tokens are removed.
- [ ] UptimeRobot monitor returns 200 using the publishable-key headers and
      alerts when the endpoint fails.
- [ ] Migrate old Firebase callable/Firestore features one by one. Keep Firebase
      Spark services only for Auth, FCM, and Crashlytics; don't deploy Firebase
      Functions or use Firebase Storage for the new architecture.
