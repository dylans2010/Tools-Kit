import SwiftUI

struct AccessibilityAuditDevTool: DevTool {
    let id = "accessibility-audit"
    let name = "Accessibility Auditor"
    let category: DevToolCategory = .diagnostics
    let icon = "figure.roll"
    let description = "Audit SwiftUI code for accessibility best practices"

    func render() -> some View {
        AccessibilityAuditView()
    }
}

struct AccessibilityAuditView: View {
    @State private var codeInput = ""
    @State private var auditResults: [AuditFinding] = []
    @State private var isAuditing = false

    var body: some View {
        Form {
            Section("SwiftUI Code") {
                TextEditor(text: $codeInput)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 200)
                    .overlay(alignment: .topLeading) {
                        if codeInput.isEmpty {
                            Text("Paste your SwiftUI View code here...")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section {
                Button(action: performAudit) {
                    if isAuditing {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Run Audit", systemImage: "checkmark.seal.fill")
                    }
                }
                .frame(maxWidth: .infinity)
                .disabled(codeInput.isEmpty || isAuditing)
            }

            if !auditResults.isEmpty {
                Section("Findings") {
                    ForEach(auditResults) { finding in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: finding.severityIcon)
                                    .foregroundStyle(finding.severityColor)
                                Text(finding.title)
                                    .font(.headline)
                            }
                            Text(finding.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else if !codeInput.isEmpty && !isAuditing {
                Section {
                    ContentUnavailableView("No Issues Found", systemImage: "checkmark.circle", description: Text("Your code follows basic accessibility patterns."))
                }
            }
        }
    }

    private func performAudit() {
        isAuditing = true
        auditResults = []

        // Simulated processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var findings: [AuditFinding] = []

            // Rule 1: Icon Buttons without Labels
            if codeInput.contains("Button") && codeInput.contains("Image(systemName:") && !codeInput.contains("accessibilityLabel") {
                findings.append(AuditFinding(
                    title: "Missing Accessibility Label",
                    description: "Buttons with only icons should have an .accessibilityLabel() to be usable with VoiceOver.",
                    severity: .high
                ))
            }

            // Rule 2: Images without decorative status or labels
            if codeInput.contains("Image(") && !codeInput.contains("accessibilityHidden") && !codeInput.contains("accessibilityLabel") {
                findings.append(AuditFinding(
                    title: "Ambiguous Image",
                    description: "Images should either be marked .accessibilityHidden(true) if decorative, or have an .accessibilityLabel().",
                    severity: .medium
                ))
            }

            // Rule 3: Contrast/Color reliance (Simple check)
            if codeInput.contains(".foregroundColor(.red)") || codeInput.contains(".foregroundColor(.green)") {
                findings.append(AuditFinding(
                    title: "Color Reliance",
                    description: "Avoid using only color to convey meaning. Ensure information is also available via text or icons.",
                    severity: .low
                ))
            }

            // Rule 4: Touch Target Size
            if codeInput.contains(".frame(width:") {
                // Simplified regex-like check
                let pattern = #"\.frame\(width:\s*([0-3][0-9])"#
                if let _ = codeInput.range(of: pattern, options: .regularExpression) {
                    findings.append(AuditFinding(
                        title: "Small Touch Target",
                        description: "Interactive elements should ideally have a minimum touch target of 44x44pt.",
                        severity: .medium
                    ))
                }
            }

            self.auditResults = findings
            self.isAuditing = false
        }
    }
}

struct AuditFinding: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let severity: Severity

    enum Severity {
        case low, medium, high
    }

    var severityColor: Color {
        switch severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }

    var severityIcon: String {
        switch severity {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.octagon"
        }
    }
}

#Preview {
    AccessibilityAuditView()
}
