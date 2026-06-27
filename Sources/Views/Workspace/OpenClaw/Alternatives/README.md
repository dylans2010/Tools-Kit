# OpenClaw Alternatives: Pairing & Authentication

This module provides multiple technically valid pairing and authentication methods for OpenClaw, offering flexibility and reliability across different environments.

## 1. Trusted Local Network Pairing (Recommended)
**Directory:** `TrustedLAN/`

### Architecture
- **Protocol:** Uses Bonjour (NWBrowser) for discovery. Once a Mac is selected, a secure control channel is opened.
- **Security:** Relies on manual user approval on the Mac side. Uses asymmetric trust after initial exchange.
- **Discovery:** iPhone uses `NetServiceBrowser` to find `_openclaw-gw._tcp`.
- **Mac Action:** Displays a native approval dialog with iPhone details.
- **User Action:** Selects Mac on iPhone, then clicks "Allow" on Mac.
- **Credentials:** Gateway issues a long-lived HMAC-based trust token.
- **Storage:** Stored in iOS Keychain via `OpenClawSecureStore`.
- **Reconnect:** Automatic using the stored trust token.
- **Failure Cases:** Network isolation, user denial, token expiration.
- **Recovery:** Re-initiate discovery and pairing.
- **Frameworks:** `Network.framework`, `Security`, `CryptoKit`.

## 2. One-Time Pairing Code
**Directory:** `PairingCode/`

### Architecture
- **Protocol:** iPhone connects to Gateway; Gateway sends a challenge requiring a numeric code.
- **Security:** 6-8 digit code with short expiry (5 mins) and rate limiting.
- **Discovery:** Bonjour or Manual IP.
- **Mac Action:** Generates and displays a secure random code.
- **User Action:** Enters the code shown on the Mac into the iPhone.
- **Credentials:** Code is exchanged for a permanent session token.
- **Storage:** Permanent token stored in Keychain.
- **Reconnect:** Automatic using the permanent token.
- **Failure Cases:** Code expiry, brute-force lockout, incorrect entry.
- **Recovery:** Regenerate code on Mac.
- **Frameworks:** `Network.framework`, `Security`.

## 3. QR Code Pairing
**Directory:** `QRCode/`

### Architecture
- **Protocol:** Mac generates a signed QR payload containing connection metadata.
- **Security:** QR contains a one-time use pairing secret.
- **Discovery:** Camera-based (bypasses network discovery issues).
- **Mac Action:** Displays a QR code on screen.
- **User Action:** Scans QR code with iPhone camera.
- **Credentials:** One-time secret exchanged for a trust token.
- **Storage:** Trust token stored in Keychain.
- **Reconnect:** Automatic.
- **Failure Cases:** Camera permission denied, blurry QR, expired secret.
- **Recovery:** Refresh QR code.
- **Frameworks:** `AVFoundation` (scanning), `CoreImage` (generation), `Security`.

## 4. Manual Pairing Token
**Directory:** `ManualToken/`

### Architecture
- **Protocol:** User-driven copy-paste of a high-entropy string.
- **Security:** Long random token (e.g., UUID-based) with manual rotation.
- **Discovery:** Manual IP entry + Token entry.
- **Mac Action:** Displays a pairing token in settings.
- **User Action:** Copies token from Mac, pastes into iPhone.
- **Credentials:** Manual token validated by Gateway, permanent token issued.
- **Storage:** Permanent token stored in Keychain.
- **Reconnect:** Automatic.
- **Failure Cases:** Invalid token, clipboard truncation.
- **Recovery:** Copy a fresh token.
- **Frameworks:** `Security`, `UIKit` (Clipboard).

## 5. Local Approval Pairing
**Directory:** `LocalApproval/`

### Architecture
- **Protocol:** "Open door" policy for new connections on local network.
- **Security:** Least secure initial step, but requires physical access to Mac to "Allow".
- **Discovery:** Bonjour.
- **Mac Action:** Pop-up on every new connection attempt from an unknown device.
- **User Action:** Presses "Allow" or "Deny" on Mac.
- **Credentials:** MAC/ID-bound trust record created on Gateway.
- **Storage:** Device ID record on Gateway, Token on iPhone.
- **Reconnect:** Automatic for approved devices.
- **Failure Cases:** Accidental denial, unauthorized connection spam.
- **Recovery:** Reset device registry on Mac.
- **Frameworks:** `Network.framework`, `Security`.

---

## Shared Implementation Details
- **Logging:** All methods integrate with `OpenClawLoggerService`.
- **Diagnostics:** Each method exposes state, gateway info, and credential status.
- **Keychain:** All sensitive data is managed by `OpenClawSecureStore`.
