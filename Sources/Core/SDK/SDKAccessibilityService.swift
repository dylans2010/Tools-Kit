import Foundation
import Combine

@MainActor
public final class SDKAccessibilityService: ObservableObject {
    nonisolated(unsafe) public static let shared = SDKAccessibilityService()

    @Published public var isVoiceOverOptimized = true
    @Published public var preferredContentSize: ContentSizeCategory = .medium
    @Published public var reduceMotion = false
    @Published public var highContrast = false
    @Published public var reduceTransparency = false
    @Published public private(set) var auditResults: [AccessibilityAuditResult] = []

    private init() {}

    // MARK: - Audit

    public func runAudit(on components: [AccessibilityComponent]) -> [AccessibilityAuditResult] {
        var results: [AccessibilityAuditResult] = []

        for component in components {
            if component.label.isEmpty {
                results.append(AccessibilityAuditResult(
                    component: component.name,
                    severity: .critical,
                    issue: "Missing accessibility label",
                    suggestion: "Add a descriptive label for VoiceOver users"
                ))
            }
            if component.hasImages && component.imageDescription.isEmpty {
                results.append(AccessibilityAuditResult(
                    component: component.name,
                    severity: .warning,
                    issue: "Image without description",
                    suggestion: "Add an image description or mark as decorative"
                ))
            }
            if component.minimumTapTarget < 44 {
                results.append(AccessibilityAuditResult(
                    component: component.name,
                    severity: .warning,
                    issue: "Tap target too small (\(component.minimumTapTarget)pt)",
                    suggestion: "Minimum tap target should be 44x44 points"
                ))
            }
            if component.contrastRatio < 4.5 {
                results.append(AccessibilityAuditResult(
                    component: component.name,
                    severity: component.contrastRatio < 3.0 ? .critical : .warning,
                    issue: "Insufficient color contrast ratio (\(String(format: "%.1f", component.contrastRatio)):1)",
                    suggestion: "WCAG AA requires minimum 4.5:1 for normal text"
                ))
            }
            if !component.supportsKeyboardNavigation {
                results.append(AccessibilityAuditResult(
                    component: component.name,
                    severity: .info,
                    issue: "No keyboard navigation support",
                    suggestion: "Add keyboard shortcuts or focus management"
                ))
            }
        }

        auditResults = results
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.accessibility",
            name: "audit.completed",
            data: [
                "total": "\(results.count)",
                "critical": "\(results.count(where: { $0.severity == .critical }))"
            ]
        ))
        return results
    }

    // MARK: - Contrast Helpers

    public func meetsContrastRequirement(foreground: String, background: String, isLargeText: Bool = false) -> Bool {
        let ratio = calculateContrastRatio(foreground: foreground, background: background)
        return isLargeText ? ratio >= 3.0 : ratio >= 4.5
    }

    public func calculateContrastRatio(foreground: String, background: String) -> Double {
        let fgLuminance = relativeLuminance(hex: foreground)
        let bgLuminance = relativeLuminance(hex: background)
        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(hex: String) -> Double {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard clean.count == 6,
              let value = UInt64(clean, radix: 16) else { return 0 }

        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0

        func linearize(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }

    // MARK: - Dynamic Type

    public func scaledFont(size: Double, weight: FontWeight = .regular) -> ScaledFontDescriptor {
        let scale: Double
        switch preferredContentSize {
        case .extraSmall: scale = 0.8
        case .small: scale = 0.9
        case .medium: scale = 1.0
        case .large: scale = 1.1
        case .extraLarge: scale = 1.2
        case .accessibilityMedium: scale = 1.4
        case .accessibilityLarge: scale = 1.6
        }
        return ScaledFontDescriptor(baseSize: size, scaledSize: size * scale, weight: weight)
    }

    // MARK: - Score

    public var accessibilityScore: Int {
        guard !auditResults.isEmpty else { return 100 }
        let criticalPenalty = auditResults.count(where: { $0.severity == .critical }) * 20
        let warningPenalty = auditResults.count(where: { $0.severity == .warning }) * 10
        let infoPenalty = auditResults.count(where: { $0.severity == .info }) * 2
        return max(0, 100 - criticalPenalty - warningPenalty - infoPenalty)
    }
}

// MARK: - Models

public struct AccessibilityComponent: Sendable {
    public let name: String
    public let label: String
    public let hasImages: Bool
    public let imageDescription: String
    public let minimumTapTarget: Double
    public let contrastRatio: Double
    public let supportsKeyboardNavigation: Bool

    public init(name: String, label: String = "", hasImages: Bool = false, imageDescription: String = "", minimumTapTarget: Double = 44, contrastRatio: Double = 7.0, supportsKeyboardNavigation: Bool = true) {
        self.name = name
        self.label = label
        self.hasImages = hasImages
        self.imageDescription = imageDescription
        self.minimumTapTarget = minimumTapTarget
        self.contrastRatio = contrastRatio
        self.supportsKeyboardNavigation = supportsKeyboardNavigation
    }
}

public struct AccessibilityAuditResult: Identifiable, Sendable {
    public let id = UUID()
    public let component: String
    public let severity: AuditSeverity
    public let issue: String
    public let suggestion: String
}

public enum AuditSeverity: String, Codable, Sendable {
    case critical, warning, info
}

public enum ContentSizeCategory: String, Codable, CaseIterable, Sendable {
    case extraSmall, small, medium, large, extraLarge, accessibilityMedium, accessibilityLarge
}

public enum FontWeight: String, Codable, Sendable {
    case regular, medium, semibold, bold
}

public struct ScaledFontDescriptor: Sendable {
    public let baseSize: Double
    public let scaledSize: Double
    public let weight: FontWeight
}
