import SwiftUI

struct DeveloperVerificationView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared
    @State private var isProcessing = false

    var verificationSteps: [VerificationStep] {
        [
            VerificationStep(title: "Identity Verification", description: "Verify your legal identity or business entity.", status: profileService.profile.tier != .free ? .completed : .pending),
            VerificationStep(title: "Domain Ownership", description: "Validate ownership of your primary app domain.", status: profileService.profile.website.isEmpty ? .notStarted : .completed),
            VerificationStep(title: "Financial Onboarding", description: "Setup tax and payout information.", status: .completed),
            VerificationStep(title: "Security Review", description: "Mandatory check for high-risk applications.", status: .notStarted)
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                verificationHeader

                VStack(alignment: .leading, spacing: 16) {
                    Text("Checklist").font(.headline)

                    ForEach(verificationSteps) { step in
                        verificationRow(step)
                    }
                }
                .padding()

                if verificationSteps.contains(where: { $0.status == .pending || $0.status == .notStarted }) {
                    Button {
                        startVerification()
                    } label: {
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Text("Continue Verification")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Verification")
    }

    private var verificationHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Developer Status").font(.headline)
                    Text(profileService.profile.tier == .free ? "Standard Access" : "Enterprise Verified").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: profileService.profile.tier == .free ? "person.badge.shield.checkmark" : "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(profileService.profile.tier == .free ? .orange : .blue)
            }

            Text("Complete verification to unlock global marketplace distribution, increased API rate limits, and custom domain hosting.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            let progress = Double(verificationSteps.filter({ $0.status == .completed }).count) / Double(verificationSteps.count)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Completion").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
                    Spacer()
                    Text("\(Int(progress * 100))%").font(.system(size: 10, weight: .black))
                }
                ProgressView(value: progress)
                    .tint(progress == 1.0 ? .green : .orange)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .padding()
    }

    private func verificationRow(_ step: VerificationStep) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(stepStatusColor(step.status).opacity(0.1))
                Image(systemName: stepStatusIcon(step.status)).font(.system(size: 10, weight: .bold)).foregroundStyle(stepStatusColor(step.status))
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title).font(.subheadline.bold())
                Text(step.description).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Spacer()
            if step.status == .notStarted || step.status == .pending {
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.quaternary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func stepStatusColor(_ status: VerificationStatus) -> Color {
        switch status {
        case .completed: return .green
        case .pending: return .orange
        case .notStarted: return .secondary
        case .failed: return .red
        }
    }

    private func stepStatusIcon(_ status: VerificationStatus) -> String {
        switch status {
        case .completed: return "checkmark"
        case .pending: return "clock.fill"
        case .notStarted: return "circle"
        case .failed: return "xmark"
        }
    }

    private func startVerification() {
        isProcessing = true
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run { isProcessing = false }
        }
    }
}

struct VerificationStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let status: VerificationStatus
}

enum VerificationStatus {
    case completed, pending, notStarted, failed
}
