import Foundation
import UIKit

struct ClipboardFinding: Identifiable {
    let id = UUID()
    let type: FindingType
    let snippet: String
    let description: String

    enum FindingType: String {
        case jwt = "JWT Token"
        case apiKey = "API Key"
        case email = "Email Address"
        case password = "Password Pattern"
        case creditCard = "Credit Card"
        case privateKey = "Private Key"
        case ipAddress = "IP Address"
        case url = "URL"
        case phoneNumber = "Phone Number"

        var icon: String {
            switch self {
            case .jwt: return "key.horizontal.fill"
            case .apiKey: return "lock.doc.fill"
            case .email: return "envelope.fill"
            case .password: return "lock.fill"
            case .creditCard: return "creditcard.fill"
            case .privateKey: return "key.fill"
            case .ipAddress: return "network"
            case .url: return "link"
            case .phoneNumber: return "phone.fill"
            }
        }
        var riskLevel: String {
            switch self {
            case .jwt, .apiKey, .password, .creditCard, .privateKey: return "High"
            case .email, .phoneNumber: return "Medium"
            case .url, .ipAddress: return "Low"
            }
        }
    }
}

@MainActor
final class ClipboardMonitorBackend: ObservableObject {
    @Published var findings: [ClipboardFinding] = []
    @Published var rawPreview = ""
    @Published var isClean = true
    @Published var hasChecked = false

    func check() {
        let text = UIPasteboard.general.string ?? ""
        let truncated = String(text.prefix(500))
        rawPreview = truncated.isEmpty ? "(clipboard is empty)" : truncated
        findings = analyze(text: text)
        isClean = findings.isEmpty
        hasChecked = true
    }

    func clear() {
        findings = []
        rawPreview = ""
        isClean = true
        hasChecked = false
    }

    private func analyze(text: String) -> [ClipboardFinding] {
        guard !text.isEmpty else { return [] }
        var found: [ClipboardFinding] = []

        let patterns: [(ClipboardFinding.FindingType, String)] = [
            (.jwt, #"eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+"#),
            (.privateKey, #"-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"#),
            (.creditCard, #"\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|6(?:011|5[0-9][0-9])[0-9]{12})\b"#),
            (.email, #"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}"#),
            (.apiKey, #"(?i)(api[_\-]?key|secret|token|bearer|authorization)[\s:='"]+[A-Za-z0-9\-_\.]{20,}"#),
            (.ipAddress, #"\b(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\b"#),
            (.phoneNumber, #"(?:\+?1[-.\s]?)?\(?[0-9]{3}\)?[-.\s][0-9]{3}[-.\s][0-9]{4}"#),
            (.url, #"https?://[^\s]+"#)
        ]

        let seenTypes = NSMutableSet()
        for (type, pattern) in patterns {
            guard !seenTypes.contains(type.rawValue) else { continue }
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                let range = Range(match.range, in: text)!
                var snippet = String(text[range])
                if snippet.count > 40 { snippet = String(snippet.prefix(20)) + "…" + String(snippet.suffix(10)) }
                found.append(ClipboardFinding(
                    type: type,
                    snippet: snippet,
                    description: "Detected \(type.rawValue) – Risk: \(type.riskLevel)"
                ))
                seenTypes.add(type.rawValue)
            }
        }
        return found
    }
}
