import SwiftUI

/// Extension to handle hex color conversion for Codable conformance.
extension Color {
    /// Initializes a Color from a CSS-style string (Hex, RGB, or RGBA).
    init(parsing string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if trimmed.hasPrefix("rgb") {
            // Handle rgb() and rgba()
            let components = trimmed
                .replacingOccurrences(of: "rgba(", with: "")
                .replacingOccurrences(of: "rgb(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .compactMap { Double($0.replacingOccurrences(of: "%", with: "")) }

            if components.count >= 3 {
                let r = components[0] / (trimmed.contains("%") && components[0] <= 100 ? 100 : 255)
                let g = components[1] / (trimmed.contains("%") && components[1] <= 100 ? 100 : 255)
                let b = components[2] / (trimmed.contains("%") && components[2] <= 100 ? 100 : 255)
                let a = components.count >= 4 ? (components[3] > 1 ? components[3] / 100 : components[3]) : 1.0
                self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
                return
            }
        }

        // Fallback to hex parsing
        self.init(hex: string)
    }

    /// Initializes a Color from a hex string.
    /// Supports formats: #RGB, #RRGGBB, #RRGGBBAA, and their counterparts without the # prefix.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Converts the Color to a hex string (RRGGBB format).
    func toHex() -> String? {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            // Fallback for colors that aren't in RGB space
            guard let components = uiColor.cgColor.components, components.count >= 3 else {
                return nil
            }
            r = components[0]
            g = components[1]
            b = components[2]
            return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        }

        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        #elseif canImport(AppKit)
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            return nil
        }

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        #else
        return nil
        #endif
    }
}
