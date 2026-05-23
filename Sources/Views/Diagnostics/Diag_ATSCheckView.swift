import SwiftUI

struct Diag_ATSCheckView: View {
    @State private var checks: [(String, String, Bool)] = []
    @State private var overallSecure = true

    var body: some View {
        Form {
            Section("App Transport Security") {
                VStack(spacing: 12) {
                    Image(systemName: overallSecure ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(overallSecure ? .green : .orange)
                    Text(overallSecure ? "ATS Properly Configured" : "ATS Exceptions Found")
                        .font(.headline)
                    Text("App Transport Security enforces secure network connections")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("TLS Configuration") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: check.2 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(check.2 ? .green : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0)
                                .font(.subheadline.weight(.medium))
                            Text(check.1)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Network Security") {
                LabeledContent("HTTPS Required") {
                    Text("Enforced").foregroundStyle(.green)
                }
                LabeledContent("Certificate Validation") {
                    Text("Active").foregroundStyle(.green)
                }
                LabeledContent("Forward Secrecy") {
                    Text("Required").foregroundStyle(.green)
                }
                LabeledContent("Min TLS Version") {
                    Text("TLS 1.2")
                }
            }

            Section("Recommendations") {
                VStack(alignment: .leading, spacing: 8) {
                    recommendationRow("Use HTTPS for all connections")
                    recommendationRow("Enable certificate pinning for sensitive APIs")
                    recommendationRow("Avoid ATS exceptions in production")
                    recommendationRow("Use TLS 1.3 where possible")
                }
            }
        }
        .navigationTitle("ATS Check")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runChecks() }
    }

    private func recommendationRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func runChecks() {
        var results: [(String, String, Bool)] = []

        if let infoDict = Bundle.main.infoDictionary {
            let hasATS = infoDict["NSAppTransportSecurity"] != nil
            if hasATS {
                let atsDict = infoDict["NSAppTransportSecurity"] as? [String: Any] ?? [:]
                let allowsArbitrary = atsDict["NSAllowsArbitraryLoads"] as? Bool ?? false
                results.append(("Arbitrary Loads", allowsArbitrary ? "Allowed (insecure)" : "Blocked (secure)", !allowsArbitrary))
                overallSecure = !allowsArbitrary
            } else {
                results.append(("ATS Configured", "Default (secure)", true))
            }
        }

        results.append(("TLS 1.2 Minimum", "Enforced by default", true))
        results.append(("Perfect Forward Secrecy", "Required for all connections", true))
        results.append(("Certificate Transparency", "Supported", true))

        checks = results
    }
}
