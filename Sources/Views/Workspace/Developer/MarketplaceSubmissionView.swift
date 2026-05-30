import SwiftUI

struct MarketplaceSubmissionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var marketplaceService = MarketplaceService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var currentStep = 0
    @State private var draft: MarketplaceSubmissionDraft
    @State private var isSubmitting = false
    @State private var showSaveConfirmation = false

    init(appID: UUID) {
        let existingDraft = MarketplaceService.shared.drafts.first { $0.appID == appID }
        _draft = State(initialValue: existingDraft ?? MarketplaceSubmissionDraft(appID: appID))
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
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Submitting to Marketplace...")
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .onChange(of: draft) { _ in
            autoSave()
        }
        .toolbar {
            ToolbarItem(placement: .status) {
                if showSaveConfirmation {
                    Text("Saved").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index == currentStep ? Color.accentColor : (index < currentStep ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.3)))
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
    }

    private var metadataStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "App Listing Metadata", subtitle: nil, icon: nil)

                VStack(alignment: .leading, spacing: 12) {
                    submissionField(label: "Listing Title", text: $draft.metadata.title, hint: "My Productivity Tool")
                    submissionField(label: "Subtitle", text: $draft.metadata.subtitle, hint: "Brief summary of what your app does")

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Long Description").font(.caption.bold()).foregroundStyle(.secondary)
                        TextEditor(text: $draft.metadata.description)
                            .frame(height: 150)
                            .padding(4)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    }
                }
            }
            .padding()
        }
    }

    private var assetsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "Visual Assets", subtitle: nil, icon: nil)

                submissionField(label: "Icon URL (512x512 PNG)", text: $draft.assets.iconURL, hint: "https://example.com/icon.png")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Screenshots (URLs, one per line)").font(.caption.bold()).foregroundStyle(.secondary)
                    TextEditor(text: Binding(
                        get: { draft.assets.screenshotURLs.joined(separator: "\n") },
                        set: { draft.assets.screenshotURLs = $0.components(separatedBy: .newlines).filter { !$0.isEmpty } }
                    ))
                    .frame(height: 120)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
            }
            .padding()
        }
    }

    private var technicalStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "Technical Configuration", subtitle: nil, icon: nil)

                HStack(spacing: 16) {
                    submissionField(label: "Version", text: $draft.technicalDetails.version, hint: "1.0.0")
                    submissionField(label: "Build", text: $draft.technicalDetails.buildNumber, hint: "100")
                }

                submissionField(label: "Minimum OS Version", text: $draft.technicalDetails.minOSVersion, hint: "macOS 13.0")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Release Notes").font(.caption.bold()).foregroundStyle(.secondary)
                    TextEditor(text: $draft.technicalDetails.releaseNotes)
                        .frame(height: 100)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
            }
            .padding()
        }
    }

    private var supportStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "Support & Compliance", subtitle: nil, icon: nil)

                submissionField(label: "Support Email", text: $draft.supportConfig.supportEmail, hint: "support@example.com")
                submissionField(label: "Support Website", text: $draft.supportConfig.supportURL, hint: "https://example.com/support")
                submissionField(label: "Privacy Policy URL", text: $draft.supportConfig.privacyPolicyURL, hint: "https://example.com/privacy")

                Divider()

                Toggle("Collects User Data", isOn: $draft.dataHandling.collectsUserData)
                Toggle("Shares with 3rd Parties", isOn: $draft.dataHandling.sharesWithThirdParties)
                Toggle("Uses Encryption", isOn: $draft.dataHandling.usesEncryption)
            }
            .padding()
        }
    }

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "Review & Submit", subtitle: nil, icon: nil)

                VStack(spacing: 12) {
                    reviewRow(label: "App Title", value: draft.metadata.title)
                    reviewRow(label: "Version", value: draft.technicalDetails.version)
                    reviewRow(label: "Support Email", value: draft.supportConfig.supportEmail)
                    reviewRow(label: "Screenshots", value: "\(draft.assets.screenshotURLs.count)")
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !isDraftComplete {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
                        Text("Please complete all required fields (Title, Version, Support, Privacy).").font(.caption).foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    submit()
                } label: {
                    Text("Finalize Submission")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isDraftComplete ? Color.accentColor : Color.secondary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isDraftComplete)

                Text("Submitting will initiate the review process. You can track progress in the Marketplace manager.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    private var footer: some View {
        HStack {
            if currentStep > 0 {
                Button("Previous") { withAnimation { currentStep -= 1 } }
                    .buttonStyle(.bordered)
            }
            Spacer()
            if currentStep < 4 {
                Button("Next Step") { withAnimation { currentStep += 1 } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }

    private func submissionField(label: String, text: Binding<String>, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.bold()).foregroundStyle(.secondary)
            TextField(hint, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func reviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value.isEmpty ? "Required" : value)
                .bold()
                .foregroundStyle(value.isEmpty ? .red : .primary)
        }
        .font(.subheadline)
    }

    private var isDraftComplete: Bool {
        !draft.metadata.title.isEmpty &&
        !draft.technicalDetails.version.isEmpty &&
        !draft.supportConfig.supportEmail.isEmpty &&
        !draft.supportConfig.privacyPolicyURL.isEmpty
    }

    private func autoSave() {
        Task {
            try? await marketplaceService.saveDraft(draft)
            await MainActor.run {
                withAnimation {
                    showSaveConfirmation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showSaveConfirmation = false }
                }
            }
        }
    }

    private func submit() {
        isSubmitting = true
        Task {
            do {
                try await marketplaceService.submitApp(draft: draft)
                // Also update app status to Under Review
                try? await appService.transitionStatus(id: draft.appID, newStatus: .underReview, reason: "Submitted to Marketplace")

                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run { isSubmitting = false }
            }
        }
    }
}
