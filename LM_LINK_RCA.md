# LM Link Authentication Root Cause Analysis

## Conclusion: Category B, D, and E

The LM Link authentication failure was caused by a combination of factors across the lifecycle:

### 1. Category B: Redirect Reception Reliability
**Issue:** The app relied solely on `ASWebAuthenticationSession` and SwiftUI's `.onOpenURL`.
**Evidence:** `ASWebAuthenticationSession` can occasionally fail to trigger the callback if the browser session state is inconsistent or if the redirect happens while the app is in a specific background state. Additionally, missing the UIKit `scene(_:openURLContexts:)` handler meant that certain cold-start deep link activations were ignored by the app.
**Fix:** Moved to external Safari via `UIApplication.shared.open` and implemented a robust UIKit-based deep link fallback in `SceneDelegate`.

### 2. Category D: Key Type Mismatch
**Issue:** `LMLinkKeyPairService` was generating `Curve25519` keys.
**Evidence:** Project standards and memory suggest that the LM Link protocol (especially for iOS identity) expects EC P-256 keys. Using the wrong elliptic curve would result in LM Studio's backend rejecting the registration during the confirmation step, even if the user clicked "Authorize" in the browser.
**Fix:** Refactored `LMLinkKeyPairService` to use `P256.Signing.PrivateKey` from CryptoKit.

### 3. Category E: Missing/Malformed Handshake Step
**Issue:** The `authentication-confirm` handshake was malformed.
**Evidence:** The previous implementation sent a POST request to `https://lmstudio.ai/authentication-confirm` with query parameters in the URL but no JSON body and no `Content-Type: application/json` header. Standard API practices (and LM Studio's expected contract) require a JSON body for this registration finalization. Without a valid body, LM Studio would show "Success" to the user (as the browser phase was done) but fail to actually register the device in the backend.
**Fix:** Updated `finalizeLink` to send a proper POST request with a JSON body containing `keyId`, `credential`, `userId`, and `platform`.

### Summary of Changes
- Switched to P-256 key generation.
- Replaced `ASWebAuthenticationSession` with external Safari.
- Implemented `SceneDelegate` for reliable deep link handling.
- Fixed the JSON payload in the registration confirmation handshake.
- Added comprehensive logging to track the flow.
- Removed sandbox-violating `localhost` probing.
