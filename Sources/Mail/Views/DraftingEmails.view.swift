import SwiftUI

struct DraftingEmailResult {
    let recipient: String
    let subject: String
    let body: String
}

struct DraftingEmailsView: View {
    enum MailStyle: String, CaseIterable, Identifiable, Hashable {
        case professional = "Professional"
        case friendly = "Friendly"
        case executive = "Executive"
        case persuasive = "Persuasive"

        var id: String { rawValue }
    }

    enum MailGoal: String, CaseIterable, Identifiable, Hashable {
        case statusUpdate = "Status Update"
        case followUp = "Follow Up"
        case proposal = "Proposal"
        case support = "Support"
        case introduction = "Introduction"

        var id: String { rawValue }
    }

    enum OutputLength: String, CaseIterable, Identifiable, Hashable {
        case short = "Short"
        case medium = "Medium"
        case long = "Long"

        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var recipient = ""
    @State private var subject = ""
    @State private var context = ""
    @State private var selectedGoal: MailGoal = .statusUpdate
    @State private var selectedStyle: MailStyle = .professional
    @State private var selectedLength: OutputLength = .medium

    @State private var generatedBody = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    let currentBody: String
    let onApply: (DraftingEmailResult) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        inputCard(title: "Recipient & Subject", icon: "person.fill") {
                            VStack(spacing: 12) {
                                customTextField("To:", text: $recipient, placeholder: "email@example.com")
                                customTextField("Subject:", text: $subject, placeholder: "Enter subject")
                            }
                        }

                        inputCard(title: "Context", icon: "text.justify.left") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What is this email about?")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                TextEditor(text: $context)
                                    .frame(minHeight: 120)
                                    .padding(8)
                                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        inputCard(title: "Style & Tone", icon: "slider.horizontal.3") {
                            VStack(spacing: 16) {
                                chipSelector(title: "Goal", selection: $selectedGoal, options: MailGoal.allCases)
                                chipSelector(title: "Style", selection: $selectedStyle, options: MailStyle.allCases)
                                chipSelector(title: "Length", selection: $selectedLength, options: OutputLength.allCases)
                            }
                        }

                        if !generatedBody.isEmpty || isGenerating {
                            outputPreview
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Drafting Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
            .onAppear {
                if generatedBody.isEmpty {
                    generatedBody = currentBody
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("AI Drafting Assistant")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Craft the perfect message with tailored goals and styles.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button("Cancel") { dismiss() }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08), in: Capsule())
                .foregroundStyle(.white)

            Button {
                Task { await generateDraft() }
            } label: {
                Group {
                    if isGenerating {
                        ProgressView()
                    } else {
                        Text("Generate")
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .disabled(context.isEmpty || isGenerating)
            .background(context.isEmpty || isGenerating ? Color.gray.opacity(0.35) : Color.blue, in: Capsule())
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private func inputCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.blue)

            content()
        }
        .padding(18)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func customTextField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            TextField(placeholder, text: text)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .padding(12)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }

    private func chipSelector<T: RawRepresentable & Hashable & Identifiable>(title: String, selection: Binding<T>, options: [T]) where T.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.id) { option in
                        Button {
                            selection.wrappedValue = option
                        } label: {
                            Text(option.rawValue)
                                .font(.caption.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selection.wrappedValue == option ? Color.blue : Color.white.opacity(0.1), in: Capsule())
                                .foregroundStyle(selection.wrappedValue == option ? .white : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var outputPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Generated Draft", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.purple)
                Spacer()
                if !generatedBody.isEmpty {
                    Button("Use This") {
                        onApply(.init(recipient: recipient, subject: subject, body: generatedBody))
                        dismiss()
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue, in: Capsule())
                    .foregroundStyle(.white)
                }
            }

            if isGenerating {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                Text(generatedBody)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(18)
        .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.purple.opacity(0.2), lineWidth: 1))
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#09090B") ?? .black, Color(hex: "#12121A") ?? .black],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @MainActor
    private func generateDraft() async {
        isGenerating = true
        errorMessage = nil

        do {
            let prompt = """
            Write a \(selectedLength.rawValue.lowercased()) \(selectedStyle.rawValue.lowercased()) email.
            Goal: \(selectedGoal.rawValue).
            Context: \(context)
            Return only the email body.
            """

            let result = try await AIService.shared.processText(prompt: prompt)
            await MainActor.run {
                generatedBody = result.trimmingCharacters(in: .whitespacesAndNewlines)
                isGenerating = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }
}
