# OpenClaw Alternatives — Fabrication & Corruption Audit Remediation Contract

## Audit Results Summary
- **Swift Findings**: Numerous (stubs, DispatchQueue usage, empty ViewModels)
- **xcodeproj Corruption**: 2685 duplicate UUIDs, multiple E-4 (incorrect entry counts), and E-7 (duplicate compile entries) violations.

## remediation Plan

### Part A: xcodeproj Repair
1. **Duplicate UUIDs (E-1)**: For each duplicate UUID, replace instances in `PBXBuildFile` with fresh UUIDs.
2. **Duplicate Compile Entries (E-7)**: Remove redundant build file UUIDs from `PBXSourcesBuildPhase`.
3. **Orphaned References (E-2)**: Remove `PBXBuildFile` entries pointing to missing `PBXFileReference`.
4. **Incorrect Entry Counts (E-4)**: Cleanup redundant entries for Alternatives files to ensure exactly 4 entries per file.

### Part B: Swift Fabrication Fixes
1. **Shared Transport**: Inject `OpenClawTransport` actor into `TLANWebSocketConnection.swift`.
2. **Bonjour Discovery**: Inject `OpenClawBonjourDiscovery` actor into `TLANBonjourBrowser.swift` and `LABonjourBrowser.swift`.
3. **Trusted LAN Flow**: Implement real HMAC-SHA256 handshake in `TLANPairingEngine.swift`.
4. **One-Time Code Flow**: Implement `generateOTP()` and real validation in `PCPairingViewModel.swift` and `PCCodeValidationService.swift`.
5. **QR Code Flow**: Implement `CIFilter` QR generation in `QRPairingViewModel.swift` and `AVCaptureSession` scanning in `QRScannerBridge.swift`.
6. **Manual Token Flow**: Implement cryptographically secure token generation in `MTTokenService.swift`.
7. **Local Approval Flow**: Implement `PairingRequest` and real `NWBrowser` discovery in `LABonjourBrowser.swift`.

### Part C: Implementation Contracts
- All ViewModels must use `@Observable` and Swift Concurrency.
- No `print()`, `DispatchQueue`, or `Combine` allowed.
- Real framework usage (Network, CryptoKit, CoreImage, AVFoundation) only.
