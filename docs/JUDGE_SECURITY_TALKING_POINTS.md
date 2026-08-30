# VitalReach — Judges Security Cheat Sheet

Canonical deep dive: [`SECURITY.md`](../SECURITY.md) (repo root).  
Sync / crowding / timeout / blackout / TrustShield viva: [`JUDGE_SYNC_RESILIENCE_TALKING_POINTS.md`](./JUDGE_SYNC_RESILIENCE_TALKING_POINTS.md).

Use this page for **pitch + viva**. Keep claims honest; flash the file paths below if judges ask for code.

---

## 30-second opener (English)

> VitalReach treats health data as sensitive: **encrypted offline on device**, **TLS in transit**, **expiring server tokens** with **role-based authorization**, **API keys never in the app**, and an **audit trail** — plus a **blackout resilience** path for critical records.

## 30-second opener (Hindi)

> VitalReach health data ko sensitive maanta hai: phone pe **AES encrypt offline outbox**, network pe **HTTPS/TLS**, server pe **expiring token + RBAC**, **Gemini key app mein nahi**, **audit log** — aur critical records ke liye **blackout / TEMP vault** demo.

Phir 4 pillars: **AuthN → AuthZ → Encrypt → Privacy/AI**.

---

## Pillar 1 — Authentication (kaun hai)

| Bolna | Dikhana / file |
|-------|----------------|
| “Opaque DRF tokens with TTL (72h), not forever JWTs.” | `backend/django_api/apps/common/authentication.py` → `ExpiringTokenAuthentication` |
| “Login / OTP / password-change **rotates** the token — old session dies.” | Same file → `rotate_token()`; `users/views.py` → `change_password` |
| “Passwords: Django PBKDF2 — not SHA-256 of passwords.” | `config/settings.py` → `PASSWORD_HASHERS` |
| “Mobile tokens live in Keystore/Keychain, not SharedPreferences.” | `mobile_app/lib/core/security/secure_session_store.dart` |
| “OTP is rate-limited; never returned in prod JSON.” | Throttles in settings; `EXPOSE_OTP_FOR_DEV=0` in prod |

**Live demo:** Login → token in response → Profile/Settings → Change password (≥8) → old token fails on `/api/users/me/` → login again.

**Endpoints:** `POST /api/users/change-password/` · `POST /api/auth/login/` (role required)

---

## Pillar 2 — Authorization / RBAC (kya dekh sakta hai)

Roles: `user` | `doctor` | `asha_worker` | `medical_staff` + Django `is_staff` (admin).

| Bolna | Dikhana / file |
|-------|----------------|
| “UI is role-shaped; **security is server-side** — client `role` / `user_id` not trusted on writes.” | `apps/common/permissions.py` |
| “Object-scoped querysets: patients, Rx, emergencies, chat peers, stock.” | Domain viewsets + chat `ALLOWED_PEERS` |
| “Admin React requires `is_staff`.” | `web_admin/.../AuthContext.jsx`, `AppRoutes.jsx` |
| “IDOR blocked — patient cannot list another’s emergencies.” | `apps/security_audit/tests.py` |

**Live demo:** Wrong role module → 403. Patient vs Doctor dashboards. Doctor Prescribe vs ASHA Update Health.

---

## Pillar 3 — Encryption (data protect)

| Layer | Mechanism | File |
|-------|-----------|------|
| Offline at rest | **AES-256-GCM** outbox / cache | `secure_payload_crypto.dart` + `local_store.dart` (`encryptJson`) |
| Key | In flutter_secure_storage | `vr_outbox_aes_key_v1` |
| In transit | HTTPS/TLS; prod SSL redirect + HSTS | Django settings + `network_security_config.xml` |
| Video | WebRTC DTLS/SRTP | `SECURITY.md` §7 |
| Models | SHA-256 integrity (not encrypt) | `model_integrity.json` |

**Live demo:** Airplane mode → ASHA/patient write → queued → reconnect sync with `client_id` idempotency.

**Mat bolo:** “Full SQLCipher DB” — sirf **payload-level** AES-GCM.

---

## Pillar 4 — AI / privacy

| Bolna | File / proof |
|-------|----------------|
| “Gemini API key only on server `.env`.” | `apps/ai_proxy/` · Flutter client key empty |
| “App calls authenticated proxy.” | `POST /api/ai/gemini-chat/` |
| “PII sanitized before Gemini.” | `_sanitize_user_text` in `ai_proxy/views.py` |
| “On-device TFLite → less PHI to cloud.” | Screening flows + AIML doc |
| “Not a diagnosis” disclaimers + TrustShield (LLM not sole truth). | TrustShield + screening UI |

**Mat bolo:** “HIPAA certified.” Bolo: *privacy-aware design*.

---

## Extra hardening (10-second bullets)

- **Rate limits:** login ~10/min, OTP ~5/min, upload/analyze scoped  
- **Uploads:** magic-byte / Pillow sniff, size caps, UUID rename — `apps/common/uploads.py`  
- **Audit:** `SecurityAuditLog` — no passwords/tokens/OTP in metadata  
- **Prod headers:** HSTS, secure cookies, `X_FRAME_OPTIONS=DENY`, nosniff  
- **Secrets:** `.env` gitignored; weak `SECRET_KEY` blocked when not DEBUG  
- **IoT stub:** HMAC-SHA256 device ingest — `POST /api/iot/ingest/`  
- **Permissions UX:** in-app rationale before OS prompt — `permission_dialog_service.dart`

---

## Live demo script (~3–4 min)

| # | Time | Action | What to say |
|---|------|--------|-------------|
| 1 | 30s | Patient vs Doctor login; wrong role | “Role wall — server enforces module.” |
| 2 | 30s | Flash `SecureSessionStore` + `Authorization: Token …` | “Token in Keystore, not prefs.” |
| 3 | 60s | Airplane → write → reconnect | “AES-256-GCM outbox → sync with client_id.” |
| 4 | 30s | Patient cannot see another’s emergency (or show test) | “RBAC + object scope, not client trust.” |
| 5 | 20s | `.env.example` has `GEMINI_API_KEY`; app does not | “Keys only on server; TFLite on device.” |
| 6 | 40s | Open blackout board → Snapshot / Simulate / Recover | “Resilience demo for critical records.” |
| 7 | 20s | Close | “Hackathon-hardened; next: biometrics, cert pinning. See SECURITY.md.” |

### Demo URLs (verified in codebase)

| Surface | URL / path |
|---------|------------|
| Blackout projector board | `http://<host>/api/blackout/display/` **or** `http://<host>/blackout/display/` |
| Blackout APIs | `/api/blackout/status/`, `snapshot/`, `simulate/`, `wipe/`, `recover/` |
| Mobile blackout button | ASHA dashboard / livestock screening → `SimulateBlackoutButton` → `POST /blackout/simulate/` |
| Change password | Mobile Settings → `POST /users/change-password/` (min 8 chars; **rotates token**) |
| Offline encrypt path | `LocalStore` enqueue → `SecurePayloadCrypto.encryptJson` |

---

## Honest Q&A — mat claim karo

| Agar bolein… | Tum bolo |
|--------------|----------|
| JWT? | “DRF opaque Token + TTL.” |
| HIPAA? | “Privacy-aware practices — not a certification.” |
| Cert pinning? | “System TLS trust; we don’t bypass validation; pinning is next.” |
| Biometric / PIN? | “OS Keystore today; app Face ID/PIN is a natural next step.” |
| Encrypted TEMP vault? | “Demo vault is plaintext JSON for the blackout board — phone outbox is AES-GCM.” |
| Blackout open APIs? | “Demo control plane (`AllowAny`) for the live board — production would lock it down.” |
| Full DB encryption? | “Payload AES-GCM on offline queues, not SQLCipher.” |
| Admin token in browser? | “Staff-only dashboard; token in localStorage — XSS-aware, HTTPS + staff gate.” |

---

## Code walk order (viva)

1. [`SECURITY.md`](../SECURITY.md)  
2. `backend/django_api/apps/common/authentication.py`  
3. `backend/django_api/apps/common/permissions.py`  
4. `mobile_app/lib/core/security/secure_session_store.dart`  
5. `mobile_app/lib/core/security/secure_payload_crypto.dart`  
6. `backend/django_api/apps/security_audit/`  
7. `backend/django_api/apps/ai_proxy/views.py`  

---

## Architecture (one glance)

```
Flutter (secure storage + AES outbox) ──HTTPS──► Django (Token TTL + RBAC + audit)
                │                                      │
           WebRTC DTLS/SRTP                      Gemini key (server only)
                │                                      │
         Admin React (is_staff)              Blackout board / TEMP vault demo
```
