import SwiftUI

struct MarketplaceSubmissionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var marketplaceService = MarketplaceService.shared
    @State private var currentStep = 0
    @State private var draft: MarketplaceSubmissionDraft
    @State private var isSubmitting = false

    init(appID: UUID) {
        _draft = State(initialValue: MarketplaceSubmissionDraft(appID: appID))
    }

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator

            TabView(selection: $currentStep) {
                metadataStep.tag(0)
                assetsStep.tag(1)
                technicalStep.tag(2)
                supportStep.tag(3)
                reviewStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .navigationTitle("Marketplace Submission")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isSubmitting)
        .overlay {
            if isSubmitting {
                ProgressView("Submitting...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
    }

    private var metadataStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("App Listing Metadata").font(.headline)

                SubmissionWizardSteps.TechnicalField(label: "Listing Title", text: $draft.metadata.title)
                SubmissionWizardSteps.TechnicalField(label: "Subtitle", text: $draft.metadata.subtitle)

                VStack(alignment: .leading) {
                    Text("Description").font(.caption.bold()).foregroundStyle(.secondary)
                    TextEditor(text: $draft.metadata.description)
                        .frame(height: 150)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
            }
            .padding()
        }
    }

    private var assetsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("App Assets").font(.headline)
                SubmissionWizardSteps.TechnicalField(label: "Icon URL", text: $draft.assets.iconURL)
                Text("Icon must be 512x512px PNG.").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private var technicalStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Technical Details").font(.headline)
                SubmissionWizardSteps.TechnicalField(label: "Version", text: $draft.technicalDetails.version)
                SubmissionWizardSteps.TechnicalField(label: "Build Number", text: $draft.technicalDetails.buildNumber)

                VStack(alignment: .leading) {
                    Text("Release Notes").font(.caption.bold()).foregroundStyle(.secondary)
                    TextEditor(text: $draft.technicalDetails.releaseNotes)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
            }
            .padding()
        }
    }

    private var supportStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Support & Privacy").font(.headline)
                SubmissionWizardSteps.TechnicalField(label: "Support Email", text: $draft.supportConfig.supportEmail)
                SubmissionWizardSteps.TechnicalField(label: "Privacy Policy URL", text: $draft.supportConfig.privacyPolicyURL)
            }
            .padding()
        }
    }

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Review & Submit").font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    summaryRow(label: "Title", value: draft.metadata.title)
                    summaryRow(label: "Version", value: draft.technicalDetails.version)
                    summaryRow(label: "Support", value: draft.supportConfig.supportEmail)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    submit()
                } label: {
                    Text("Submit for Review")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isDraftComplete)
            }
            .padding()
        }
    }

    private var footer: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") { currentStep -= 1 }
                    .buttonStyle(.bordered)
            }
            Spacer()
            if currentStep < 4 {
                Button("Next") { currentStep += 1 }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var isDraftComplete: Bool {
        !draft.metadata.title.isEmpty &&
        !draft.technicalDetails.version.isEmpty &&
        !draft.supportConfig.privacyPolicyURL.isEmpty
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value.isEmpty ? "Missing" : value).bold().foregroundStyle(value.isEmpty ? .red : .primary)
        }
    }

    private func submit() {
        isSubmitting = true
        Task {
            try? await marketplaceService.submitApp(draft: draft)
            await MainActor.run {
                isSubmitting = false
                dismiss()
            }
        }
    }
}
