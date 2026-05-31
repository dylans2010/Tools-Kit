import SwiftUI

struct DeveloperVerificationView: View {
    @State private var verificationSteps: [VerificationStep] = [
        VerificationStep(title: "Identity Verification", description: "Verify your legal identity or business entity.", status: .completed),
        VerificationStep(title: "Domain Ownership", description: "Validate ownership of your primary app domain.", status: .pending),
        VerificationStep(title: "Financial Onboarding", description: "Setup tax and payout information.", status: .notStarted),
        VerificationStep(title: "Security Review", description: "Mandatory check for high-risk applications.", status: .notStarted)
    ]

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

                if verificationSteps.contains(where: { $0.status == .pending }) {
                    Button {
                        // resolve next pending step
                    } label: {
                        Text("Continue Verification")
                            .font(.headline).frame(maxWidth: .infinity).padding()
                            .background(Color.accentColor).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Verification")
    }

    private var verificationHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Developer Status").font(.headline)
                    Text("Limited Access Mode").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "person.badge.shield.checkmark.fill").font(.title2).foregroundStyle(.orange)
            }

            Text("Complete the verification process to unlock full distribution capabilities, higher rate limits, and marketplace eligibility.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: 0.25)
                .progressViewStyle(.linear)
                .tint(.orange)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }

    private func verificationRow(_ step: VerificationStep) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(stepStatusColor(step.status).opacity(0.1))
                Image(systemName: stepStatusIcon(step.status)).font(.caption.bold()).foregroundStyle(stepStatusColor(step.status))
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title).font(.subheadline.bold())
                Text(step.description).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if step.status == .notStarted {
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
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
