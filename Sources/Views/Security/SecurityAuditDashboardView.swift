import SwiftUI

struct SecurityAuditDashboardView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var healthScore: Double = 0.0
    @State private var recommendations: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Security Health Score")
                        .font(.headline)
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 15)
                        Circle()
                            .trim(from: 0, to: healthScore)
                            .stroke(healthScore > 0.8 ? Color.green : .orange, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        VStack {
                            Text("\(Int(healthScore * 100))%")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                            Text(healthScore > 0.8 ? "Excellent" : "Needs Attention")
                                .font(.caption.bold())
                                .foregroundStyle(healthScore > 0.8 ? Color.green : Color.orange)
                        }
                    }
                    .frame(width: 180, height: 180)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(20)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Audit Results")
                        .font(.headline)

                    if recommendations.isEmpty {
                        Label("All security checks passed!", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } else {
                        ForEach(recommendations, id: \.self) { rec in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                                Text(rec).font(.subheadline)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(20)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Security Audit")
        .onAppear {
            runAudit()
        }
    }

    private func runAudit() {
        var score = 1.0
        var recs: [String] = []

        // Check Biometrics
        let useBiometrics = UserDefaults.standard.bool(forKey: "com.toolskit.security.useBiometrics")
        if !useBiometrics {
            score -= 0.3
            recs.append("Enable Face ID / Touch ID for faster and safer access.")
        }

        // Check recent failures
        let failedLogins = authService.logs.filter { $0.type == .failedLogin && Date().timeIntervalSince($0.timestamp) < 86400 }
        if !failedLogins.isEmpty {
            score -= 0.1 * Double(failedLogins.count)
            recs.append("Recent failed login attempts detected.")
        }

        // Check setup
        if !authService.isSetup {
            score = 0.0
            recs.append("Vault not initialized.")
        }

        self.healthScore = max(0, score)
        self.recommendations = recs
    }
}
