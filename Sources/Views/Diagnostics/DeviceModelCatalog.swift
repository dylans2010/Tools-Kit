import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Single source of truth for iPhone marketing names and hardware features.
///
/// Why this file exists: several Diagnostics views used to copy-paste a
/// hard-coded identifier list that stopped at the iPhone 16 generation
/// (`iPhone17,x`). That is why an iPhone 17 reported "Dynamic Island Not
/// Available": its real identifiers are `iPhone18,1`–`iPhone18,4`, which were
/// not in the list at all. It also wrongly included `iPhone17,5` (iPhone 16e)
/// as a Dynamic Island device, even though the 16e has a notch, and it
/// included phantom identifiers `iPhone17,6`–`iPhone17,8`, which Apple never
/// shipped.
///
/// Confirmed identifiers (Apple machine identifiers, 2025 lineup):
///   iPhone18,1 = iPhone 17 Pro
///   iPhone18,2 = iPhone 17 Pro Max
///   iPhone18,3 = iPhone 17
///   iPhone18,4 = iPhone Air
///   iPhone18,5 = iPhone 17e (2026, notch like the 16e — no Dynamic Island)
///
/// iPhone 18 Pro / iPhone 18 Pro Max and iPhone Duo are NOT yet confirmed
/// with a published machine identifier. They are represented here as
/// provisional, marketing-name entries (no identifier invented), and the
/// fallback in `info(for:)` treats any future `iPhone19,x`+ identifier as a
/// Dynamic Island device, so a real 18 Pro / Duo will be recognised the
/// moment it runs this code. Update the provisional entries with Apple's
/// published identifiers when they appear; do not guess them.
struct DeviceModelInfo: Identifiable, Equatable {
    var id: String { identifier ?? marketingName }
    /// Machine identifier, e.g. "iPhone18,3". Nil for provisional models
    /// whose identifier Apple has not published yet.
    let identifier: String?
    let marketingName: String
    let chip: String
    let year: Int
    let hasDynamicIsland: Bool
    let hasCameraControl: Bool
    let hasActionButton: Bool
    let hasUSBC: Bool
    /// True when this entry is not yet tied to a published identifier.
    let isProvisional: Bool
    let note: String
}

enum DeviceModelCatalog {
    // MARK: - Confirmed models (Dynamic Island era and newer)

    static let confirmed: [DeviceModelInfo] = [
        DeviceModelInfo(identifier: "iPhone15,2", marketingName: "iPhone 14 Pro", chip: "A16 Bionic", year: 2022, hasDynamicIsland: true, hasCameraControl: false, hasActionButton: false, hasUSBC: false, isProvisional: false, note: "First Dynamic Island iPhone."),
        DeviceModelInfo(identifier: "iPhone15,3", marketingName: "iPhone 14 Pro Max", chip: "A16 Bionic", year: 2022, hasDynamicIsland: true, hasCameraControl: false, hasActionButton: false, hasUSBC: false, isProvisional: false, note: "First Dynamic Island iPhone."),
        DeviceModelInfo(identifier: "iPhone16,1", marketingName: "iPhone 15 Pro", chip: "A17 Pro", year: 2023, hasDynamicIsland: true, hasCameraControl: false, hasActionButton: true, hasUSBC: true, isProvisional: false, note: "First iPhone with Action Button and USB-C."),
        DeviceModelInfo(identifier: "iPhone16,2", marketingName: "iPhone 15 Pro Max", chip: "A17 Pro", year: 2023, hasDynamicIsland: true, hasCameraControl: false, hasActionButton: true, hasUSBC: true, isProvisional: false, note: "First iPhone with Action Button and USB-C."),
        DeviceModelInfo(identifier: "iPhone14,7", marketingName: "iPhone 14", chip: "A15 Bionic", year: 2022, hasDynamicIsland: false, hasCameraControl: false, hasActionButton: false, hasUSBC: false, isProvisional: false, note: "Notch, no Dynamic Island."),
        DeviceModelInfo(identifier: "iPhone14,8", marketingName: "iPhone 14 Plus", chip: "A15 Bionic", year: 2022, hasDynamicIsland: false, hasCameraControl: false, hasActionButton: false, hasUSBC: false, isProvisional: false, note: "Notch, no Dynamic Island."),
        DeviceModelInfo(identifier: "iPhone15,4", marketingName: "iPhone 15", chip: "A16 Bionic", year: 2023, hasDynamicIsland: true, hasCameraControl: false, hasActionButton: false, hasUSBC: true, isProvisional: false, note: "Dynamic Island on all iPhone 15 models."),
        DeviceModelInfo(identifier: "iPhone15,5", marketingName: "iPhone 15 Plus", chip: "A16 Bionic", year: 2023, hasDynamicIsland: true, hasCameraControl: false, hasActionButton: false, hasUSBC: true, isProvisional: false, note: "Dynamic Island on all iPhone 15 models."),
        DeviceModelInfo(identifier: "iPhone17,1", marketingName: "iPhone 16 Pro", chip: "A18 Pro", year: 2024, hasDynamicIsland: true, hasCameraControl: true, hasActionButton: true, hasUSBC: true, isProvisional: false, note: "Camera Control introduced."),
        DeviceModelInfo(identifier: "iPhone17,2", marketingName: "iPhone 16 Pro Max", chip: "A18 Pro", year: 2024, hasDynamicIsland: true, hasCameraControl: true, hasActionButton: true, hasUSBC: true, isProvisional: false, note: "Camera Control introduced."),
        DeviceModelInfo(identifier: "iPhone17,3", marketingName: "iPhone 16", chip: "A18", year: 2024, hasDynamicIsland: true, hasCameraControl: true, hasActionButton: true, hasUSBC: true, isProvisional: false, note: "Camera Control introduced."),
        DeviceModelInfo(identifier: "iPhone17,4", marketingName: "iPhone 16 Plus", chip: "A18", year: 2024, hasDynamicIsland: true, hasCameraControl: true, hasActionButton: true, hasUSBC: true, isProvisional: false, note: "Camera Control introduced."),
        // 16e: notch, NOT Dynamic Island, Action Button yes, Camera Control no, MagSafe no.
        DeviceModelInfo(identifier: "iPhone17,5", marketingName: "iPhone 16e", chip: "A18", year: 2025, hasDynamicIsland: false, hasCameraControl: false, hasActionButton: true, hasUSBC: true, isProvisional: false, note: "Notch, not Dynamic Island. Previously misreported as Dynamic Island."),
        // iPhone 17 lineup (2025) — the bug this file fixes.
        DeviceModelInfo(identifier: "iPhone18,1", marketingName: "iPhone 17 Pro", chip: "A19 Pro", year: 2025, hasDynamicIsland: true, hasCameraControl: true, hasActionButton: true, hasUSBC: true, isProvisional: false, note: "Dynamic Island. Previously reported as not available."),
        DeviceModelInfo(identifier: "iPhone18,2", marketingName: "iPhone 17 Pro Max", chip: "A19 Pro", year: 2025, hasDynamicIsland: true, hasCameraControl: true, hasActionButton: true, hasUSBC: true, isProvisional: false, note: "Dynamic Island. Previously reported as not available."),
        DeviceModelInfo(identifier: "iPhone18,3", marketingName: "iPhone 17", chip: "A19", year: 2025, hasDynamicIsland: true, hasCameraControl: true, hasActionButton: true, hasUSBC: true, isProvisional: false, note: "Dynamic Island. Previously reported as not available."),
        DeviceModelInfo(identifier: "iPhone18,4", marketingName: "iPhone Air", chip: "A19 Pro", year: 2025, hasDynamicIsland: true, hasCameraControl: true, hasActionButton: true, hasUSBC: true, isProvisional: false, note: "Ultra-thin iPhone Air. Dynamic Island, eSIM-only in the US."),
        DeviceModelInfo(identifier: "iPhone18,5", marketingName: "iPhone 17e", chip: "A19", year: 2026, hasDynamicIsland: false, hasCameraControl: false, hasActionButton: true, hasUSBC: true, isProvisional: false, note: "Entry-level 2026 model, notch like the 16e — no Dynamic Island."),
    ]

    // MARK: - Provisional (unreleased) models

    /// No machine identifier is invented for these. They appear in the
    /// supported-models list and in the System Model Catalog tool, and the
    /// future-identifier fallback below covers them on-device.
    static let provisional: [DeviceModelInfo] = [
        DeviceModelInfo(identifier: nil, marketingName: "iPhone 18 Pro", chip: "Next-generation Pro chip (unconfirmed)", year: 2026, hasDynamicIsland: true, hasCameraControl: true, hasActionButton: true, hasUSBC: true, isProvisional: true, note: "Provisional: Apple has not published a machine identifier yet. Dynamic Island expected to carry over; update this entry when the identifier is confirmed."),
        DeviceModelInfo(identifier: nil, marketingName: "iPhone 18 Pro Max", chip: "Next-generation Pro chip (unconfirmed)", year: 2026, hasDynamicIsland: true, hasCameraControl: true, hasActionButton: true, hasUSBC: true, isProvisional: true, note: "Provisional: Apple has not published a machine identifier yet. Dynamic Island expected to carry over; update this entry when the identifier is confirmed."),
        DeviceModelInfo(identifier: nil, marketingName: "iPhone Duo", chip: "Next-generation chip (unconfirmed)", year: 2026, hasDynamicIsland: true, hasCameraControl: true, hasActionButton: true, hasUSBC: true, isProvisional: true, note: "Provisional foldable/dual-display model: Apple has not published a machine identifier yet. Dynamic Island is expected on the primary display; confirm against the shipped hardware and update this entry."),
    ]

    static var all: [DeviceModelInfo] { confirmed + provisional }

    /// The 2025–2026 lineup the user asked to support, in marketing order.
    static var supportedLineup: [DeviceModelInfo] {
        let names = ["iPhone 17", "iPhone Air", "iPhone 17 Pro", "iPhone 17 Pro Max", "iPhone 17e", "iPhone 18 Pro", "iPhone 18 Pro Max", "iPhone Duo"]
        return names.compactMap { name in all.first { $0.marketingName == name } }
    }

    // MARK: - Lookup

    static func currentIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        return mirror.children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }
    }

    /// Marketing name for an identifier, or the identifier itself if unknown.
    static func marketingName(for identifier: String) -> String {
        if let match = confirmed.first(where: { $0.identifier == identifier }) {
            return match.marketingName
        }
        return identifier
    }

    static func hasDynamicIsland(for identifier: String) -> Bool {
        info(for: identifier).hasDynamicIsland
    }

    /// Resolve an identifier. Unknown future iPhones (`iPhone19,x` and later)
    /// are assumed to keep Dynamic Island — that is the forward-compatible
    /// behaviour that prevents this exact bug from recurring on the next
    /// generation — and are flagged provisional so the UI never presents a
    /// guess as a confirmed fact.
    static func info(for identifier: String) -> DeviceModelInfo {
        if let match = confirmed.first(where: { $0.identifier == identifier }) {
            return match
        }
        if let major = majorNumber(of: identifier), major >= 19 {
            return DeviceModelInfo(
                identifier: identifier,
                marketingName: "Future iPhone (\(identifier))",
                chip: "Unknown",
                year: 2026,
                hasDynamicIsland: true,
                hasCameraControl: true,
                hasActionButton: true,
                hasUSBC: true,
                isProvisional: true,
                note: "Unrecognised future identifier: Dynamic Island is assumed (it has been present on every non-e model since iPhone 14 Pro) until this catalog is updated with Apple's published data."
            )
        }
        return DeviceModelInfo(
            identifier: identifier,
            marketingName: identifier,
            chip: "Unknown",
            year: 0,
            hasDynamicIsland: false,
            hasCameraControl: false,
            hasActionButton: false,
            hasUSBC: false,
            isProvisional: true,
            note: "Identifier is not in this catalog. Add it to DeviceModelCatalog.confirmed with Apple's published data."
        )
    }

    static func currentInfo() -> DeviceModelInfo {
        info(for: currentIdentifier())
    }

    private static func majorNumber(of identifier: String) -> Int? {
        guard identifier.hasPrefix("iPhone") else { return nil }
        let rest = identifier.dropFirst("iPhone".count)
        let major = rest.split(separator: ",").first.map(String.init) ?? ""
        return Int(major)
    }
}
