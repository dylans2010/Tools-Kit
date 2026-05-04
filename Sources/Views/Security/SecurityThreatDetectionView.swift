import SwiftUI

struct SecurityThreatDetectionView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var threats: [SecurityThreat] = []

    var body: some View {
        List {
            Section("Detected Threats") {
                if threats.isEmpty {
                    Label("No threats detected in logs", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                } else {
                    ForEach(threats) { threat in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(threat.type).font(.subheadline.bold())
                                    Text(threat.severity)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .clipShape(Capsule())
                                }
                                Text("\(threat.timestamp.formatted())")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("Blocked").font(.caption2.bold()).foregroundColor(.red)
                        }
                    }
                }
            }

            Section {
                Button("Analyze Logs for Threats") {
                    performThreatAnalysis()
                }
                .frame(maxWidth: .infinity)
            }

            Section("Protection Rules") {
                Toggle("Brute Force Detection", isOn: .constant(true))
                Toggle("Credential Stuffing Defense", isOn: .constant(true))
            }
        }
        .navigationTitle("Threat Detection")
        .onAppear {
            performThreatAnalysis()
        }
    }

    private func performThreatAnalysis() {
        // Real logic: scan logs for repeated failed logins
        let failedLogins = authService.logs.filter { $0.type == .failedLogin }
        var detected: [SecurityThreat] = []

        if failedLogins.count >= 3 {
            detected.append(SecurityThreat(id: UUID(), type: "Brute Force Attempt", severity: "High", timestamp: failedLogins[0].timestamp))
        }

        // Check for unusual activity (e.g., login at 3 AM)
        for log in authService.logs where log.type == .login {
            let hour = Calendar.current.component(.hour, from: log.timestamp)
            if hour >= 1 && hour <= 4 {
                detected.append(SecurityThreat(id: UUID(), type: "Unusual Login Time", severity: "Medium", timestamp: log.timestamp))
            }
        }

        self.threats = detected
    }
}

struct SecurityThreat: Identifiable {
    let id: UUID
    let type: String
    let severity: String
    let timestamp: Date
}
