# VitalReach Security

This document describes how VitalReach protects health data across Flutter, Django, signaling, offline sync, AI, and future IoT/LoRa paths.

## Cryptography glossary (read first)

| Mechanism | Purpose | NOT |
|-----------|---------|-----|
| **SHA-256** | Hash / integrity (model checksums, HMAC inputs) | Encryption |
| **AES-256-GCM** | Encryption at rest for offline payloads | Hashing |
| **TLS / HTTPS** | Encryption + integrity + auth of data in transit | Networking alone |
| **Django password hashers (PBKDF2 / Argon2)** | Password storage | SHA-256 of passwords |
| **DRF Token** | Session authentication credential | JWT (VitalReach uses tokens, not JWT) |
| **RBAC + object authorization** | Who may access which records | Client-supplied roles |
| **DTLS / SRTP** | WebRTC media security | Raw UDP for PHI |

TCP/IP and UDP move packets. They do **not** encrypt. TLS (and DTLS/SRTP for realtime media) provide confidentiality.

---

## 1. Authentication

- Django REST Framework **TokenAuthentication** with optional TTL (`TOKEN_TTL_HOURS`, default 72h) via `ExpiringTokenAuthentication`.
- Login/OTP **rotates** tokens; logout deletes the token.
- Passwords use Django’s `set_password` / PBKDF2 (never plain SHA-256).
- Register no longer returns a token for an existing phone+role (prevents takeover).
- OTP is never returned in API JSON unless `EXPOSE_OTP_FOR_DEV=1`.
- Flutter stores tokens in **flutter_secure_storage** (not SharedPreferences).

## 2. Authorization

- Server derives role from authenticated user — client `role` / `user_id` / `doctor_id` are not trusted on writes.
- Object-level scoping for patients, health records, emergency alerts, prescriptions, ASHA village visits, livestock cases, screenings.
- Admin APIs require `IsAdminUser`.

## 3. Encryption

- **In transit:** HTTPS/TLS for API; WebRTC media uses DTLS/SRTP.
- **At rest (mobile):** AES-256-GCM for offline outbox bodies and API cache payloads (`SecurePayloadCrypto`).
- **At rest (server):** OS/disk and optional private S3; field-level AES reserved for future high-sensitivity columns.

## 4. Hashing

- SHA-256 verifies on-device TFLite model integrity (`model_integrity.json` + `ModelIntegrity`).
- Device ingest uses HMAC-SHA256 for message authentication.
- Password storage uses Django hashers, **not** SHA-256.

## 5. HTTPS / TLS

- Production (`DEBUG=False`): `SECURE_SSL_REDIRECT`, HSTS, secure cookies, `SECURE_CONTENT_TYPE_NOSNIFF`, `X_FRAME_OPTIONS=DENY`, referrer policy.
- Mobile release cleartext is disabled by default; LAN cleartext only for local domains.
- Certificate validation is **not** bypassed (`badCertificateCallback` is not used).

## 6. TCP/IP

- REST API runs over HTTP(S) typically on TCP (or HTTP/3/QUIC where the platform supports it).
- Assumptions: reverse proxy terminates TLS; Django is not exposed raw on the public internet in production; database is not publicly reachable.

## 7. UDP / WebRTC

- Video/audio uses WebRTC (UDP when available) with **DTLS** and **SRTP**.
- Signaling is authenticated with VitalReach tokens against Django `/api/users/me/`.
- Do not send clinical PHI over raw UDP outside SRTP-protected media.

## 8. Offline security

- OfflineApi / SyncService / ScreeningEvent architecture preserved.
- Outbox + cache encrypted with AES-256-GCM; key in secure storage.
- Each enqueue adds `client_id` for idempotency.
- Server re-validates auth, ownership, and payload on sync.

## 9. Sync security

- Authenticated sync only.
- Idempotent `client_id` on screenings and stock.
- Client identity fields stripped; livestock case must be owned by requester.
- Optional timestamp skew window (`SYNC_TIMESTAMP_MAX_SKEW_DAYS`).

## 10. IoT / LoRa security

- Radio alone is not secure. Application-layer device ID + HMAC + timestamp + nonce + revocation.
- `DeviceCredential` + `POST /api/iot/ingest/` stub.
- ESP32 SoftAP defaults must be changed before deploy (`CHANGE_ME_BEFORE_DEPLOY`).

## 11. AI / Gemini security

- Gemini API key lives **only** on the server (`GEMINI_API_KEY`).
- Flutter calls `POST /api/ai/gemini-chat/` (authenticated).
- Prompts are sanitized; domain safety instructions; decision-support disclaimer.
- On-device TFLite models reduce cloud PHI for screening.

## 12. Database security

- ORM-only queries (no raw SQL with user strings).
- Least privilege recommended for production DB users.
- Scoped querysets prevent cross-user PHI listing.

## 13. File-upload security

- Magic-byte / Pillow validation, size and dimension limits, UUID filenames.
- Private S3 ACL + signed URLs when AWS is configured.
- Local media served only when `DEBUG=True`.

## 14. Audit logging

- `SecurityAuditLog` records actor, action, object type/id, success, IP, non-PHI metadata.
- Never logs passwords, tokens, OTP, or API keys.

## 15. Secrets management

- `SECRET_KEY`, DB URL, Gemini key, SMS keys from environment.
- `.env` gitignored; `.env.example` documents variables.
- **Rotate** any Gemini key that was previously committed in client source.

## 16. Incident considerations

1. Revoke DRF tokens / rotate `SECRET_KEY` if leaked.
2. Revoke Gemini key in Google AI console.
3. Revoke `DeviceCredential` rows.
4. Force password resets for affected accounts.
5. Review `SecurityAuditLog` for suspicious actions.

## 17. Known limitations

- Demo seed passwords remain for hackathon demos — not for production.
- Model SHA-256 hashes in `model_integrity.json` must be filled after training for full integrity enforcement.
- Signaling auth requires Django reachability from the signaling host.
- Full-disk SQLCipher not used; payload-level AES-GCM protects sensitive queue/cache fields.
- Emergency LoRa path is still largely mock hardware.

---

## Architecture (where controls apply)

```
                    VITALREACH
                         |
              +----------+----------+
              |                     |
           Flutter                 Web/Admin
              |                     |
     Secure Storage            HTTPS/TLS
     AES-256-GCM outbox             |
              |                     |
              +----------+----------+
                         |
                    HTTPS/TLS
                         |
                    Django API
                         |
       +-----------------+-----------------+
       |                 |                 |
 Token Auth           RBAC/AuthZ        Validation
       |                 |                 |
       +-----------------+-----------------+
                         |
                  ScreeningEvent
                         |
             +-----------+-----------+
             |           |           |
          Human       Livestock     Child
             |           |           |
             +-----------+-----------+
                         |
              On-device TFLite (SHA-256)
              Gemini proxy (server key)
                         |
              Offline / Sync Layer
                         |
                  Doctor / ASHA / Vet

                     IoT / LoRa
                         |
              HMAC device auth / API
                         |
                   Django Backend
```
