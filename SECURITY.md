# Security Overview - Gramin Health Connect (hs053)

Gramin Health Connect is designed with a "Security-First" architecture to ensure that sensitive medical data and user identities are protected at every layer. Below is a detailed breakdown of the security best practices and implementations integrated into the system.

## 1. Authentication & Identity Management

### Multi-Factor Authentication (MFA) via OTP
The project implements a robust **One-Time Password (OTP)** system for logins and password resets:
- **Backend-Generated**: OTPs are generated on the server using cryptographically secure methods.
- **Strict Expiry**: Every OTP has a hard-coded **5-minute expiration** window.
- **Verification Logic**: A two-step verification process (`send-otp` and `verify-otp`) ensures that only the intended recipient can access the account.
- **Role Validation**: During OTP verification, the system validates the user's role (User, Doctor, or ASHA Worker), preventing role-spoofing attacks.

### Secure Token Management
- **Token-Based Auth**: The app uses token-based authentication for all API requests. 
- **Secure Storage**: Tokens are localized on the mobile device using `flutter_secure_storage`, which utilizes **KeyChain (iOS)** and **KeyStore (Android)** for hardware-backed encryption.

## 2. Data Security & Privacy

### End-to-End Privacy
- **HIPAA Compliance**: The architecture is built following HIPAA (Health Insurance Portability and Accountability Act) guidelines to manage patient health information (PHI) securely.
- **Encrypted Local Storage**: Sensitive data like medicine schedules are stored in a local SQLite database that resides within the app's private directory, protected by the OS's sandbox.

### Secure Communication (WebRTC & APIs)
- **HTTPS Enforcement**: All communication between the Flutter app and the Django backend is designed to run over TLS/SSL (HTTPS).
- **WebRTC Signaling**: Video consultations use a dedicated Node.js signaling server, facilitating peer-to-peer (P2P) connections that keep video streams direct between patient and doctor.

## 3. Backend Hardening (Django)

### Role-Based Access Control (RBAC)
- The Django REST Framework backend strictly enforces roles. A 'User' cannot access 'Doctor' endpoints, and an 'ASHA Worker' can only interact with their assigned village data.
- User status (e.g., `is_verified` for OTPs) is tracked at the database level to ensure persistent session integrity.

### Input Sanitization
- All incoming requests (Phone numbers, patient names, health records) are validated and sanitized via Django Serializers to prevent SQL Injection and Cross-Site Scripting (XSS).

## 4. Operational Security

### Background Execution & Alarms
- **System-Level Scheduling**: Medicine reminders use the `AndroidAlarmManager`, which operates in a restricted system context, ensuring that tasks cannot be hijacked by other malicious apps.
- **Battery & Permission Safety**: The app explicitly requests `SCHEDULE_EXACT_ALARM` and `POST_NOTIFICATIONS` permissions, adhering to modern Android security boundaries.

### Sync Integrity
- **Database Synchronization**: The synchronization logic between the local SQLite and the Django backend uses unique identifiers and timestamps to prevent data collision or unauthorized data injection.

## 5. Summary of Security Stack
| Component | Technology | Security Purpose |
| --- | --- | --- |
| **Auth** | OTP + JWT | Identity Assurance |
| **Storage** | Flutter Secure Storage | Hardware Encryption |
| **Backend** | Django ORM | SQL Injection Prevention |
| **Network** | SSL/TLS | Man-in-the-Middle Protection |
| **Identity** | Role-Based RBAC | Permission Isolation |

---
*Developed for HackStomp 2026 - Team hs053*
