import SwiftUI

struct DraftingEmailResult {
    let recipient: String
    let subject: String
    let body: String
}

struct DraftingEmailsView: View {
    /// Default creativity level balances conservative business tone with useful phrasing variety.
    private static let defaultCreativity = 0.55

    enum MailStyle: String, CaseIterable, Identifiable, Hashable {
        case professional = "Professional"
        case friendly = "Friendly"
        case executive = "Executive"
        case persuasive = "Persuasive"
        case empathetic = "Empathetic"
        case technical = "Technical"
        case casual = "Casual"

        var id: String { rawValue }
    }

    enum MailGoal: String, CaseIterable, Identifiable, Hashable {
        case statusUpdate = "Status Update"
        case followUp = "Follow Up"
        case proposal = "Proposal"
        case support = "Support"
        case introduction = "Introduction"
        case apology = "Apology"
        case negotiation = "Negotiation"
        case meetingRequest = "Meeting Request"

        var id: String { rawValue }
    }

    enum OutputLength: String, CaseIterable, Identifiable, Hashable {
        case short = "Short"
        case medium = "Medium"
        case long = "Long"
        case veryLong = "Very Long"

        var id: String { rawValue }
    }

    enum Urgency: String, CaseIterable, Identifiable, Hashable {
        case low = "Low"
        case normal = "Normal"
        case high = "High"
        case critical = "Critical"

        var id: String { rawValue }
    }

    enum Audience: String, CaseIterable, Identifiable, Hashable {
        case executive = "Executive"
        case client = "Client"
        case teammate = "Teammate"
        case support = "Support Team"
        case recruiter = "Recruiter"

        var id: String { rawValue }
    }

    enum OutputFormat: String, CaseIterable, Identifiable, Hashable {
        case paragraph = "Paragraph"
        case bullets = "Bullets"
        case checklist = "Checklist"

        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var recipient = ""
    @State private var subject = ""
    @State private var context = ""
    @State private var selectedGoal: MailGoal = .statusUpdate
    @State private var selectedStyle: MailStyle = .professional
    @State private var selectedLength: OutputLength = .medium
    @State private var selectedUrgency: Urgency = .normal
    @State private var selectedAudience: Audience = .client
    @State private var selectedFormat: OutputFormat = .paragraph
    @State private var includeActionItems = true
    @State private var includeSubjectSuggestions = false
    @State private var includeGreeting = true
    @State private var includeClosing = true
    @State private var includeCallToAction = true
    @State private var includeMeetingTimes = false
    @State private var includeBulletSummary = false
    @State private var creativity: Double = defaultCreativity
    @State private var requiredPoints = ""
    @State private var avoidPhrases = ""
    @State private var additionalConstraints = ""

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
                                chipSelector(title: "Urgency", selection: $selectedUrgency, options: Urgency.allCases)
                                Toggle("Include action items", isOn: $includeActionItems)
                                    .font(.caption.bold())
                                Toggle("Include subject suggestions", isOn: $includeSubjectSuggestions)
                                    .font(.caption.bold())
                            }
                        }

                        inputCard(title: "Drafting Tools", icon: "wand.and.stars") {
                            VStack(spacing: 16) {
                                chipSelector(title: "Audience", selection: $selectedAudience, options: Audience.allCases)
                                chipSelector(title: "Format", selection: $selectedFormat, options: OutputFormat.allCases)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Creativity \(Int(creativity * 100))%")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                    Slider(value: $creativity, in: 0.1...1, step: 0.05)
                                        .tint(.purple)
                                }

                                Toggle("Include greeting", isOn: $includeGreeting)
                                    .font(.caption.bold())
                                Toggle("Include closing", isOn: $includeClosing)
                                    .font(.caption.bold())
                                Toggle("Include clear CTA", isOn: $includeCallToAction)
                                    .font(.caption.bold())
                                Toggle("Offer meeting-time options", isOn: $includeMeetingTimes)
                                    .font(.caption.bold())
                                Toggle("Add bullet summary at top", isOn: $includeBulletSummary)
                                    .font(.caption.bold())

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Must Include")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                    TextEditor(text: $requiredPoints)
                                        .frame(minHeight: 72)
                                        .padding(8)
                                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Avoid Phrases")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                    TextField("e.g. just checking in, per my last email", text: $avoidPhrases)
                                        .padding(10)
                                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Additional Constraints")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                    TextEditor(text: $additionalConstraints)
                                        .frame(minHeight: 72)
                                        .padding(8)
                                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }

                        if !generatedBody.isEmpty || isGenerating {
                            outputPreview
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: [.purple, .blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                .modifier(DraftingHeaderEffect())
            Text("AI Drafting Studio")
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
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.14), Color.blue.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(.ultraThinMaterial.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
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

    private func chipSelector<T: RawRepresentable & Hashable & Identifiable>(title: String, selection: Binding<T>, options: [T]) -> some View where T.RawValue == String {
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
            Urgency: \(selectedUrgency.rawValue).
            Audience: \(selectedAudience.rawValue).
            Format: \(selectedFormat.rawValue).
            Creativity: \(Int(creativity * 100))%.
            Include action items: \(includeActionItems ? "yes" : "no").
            Include subject suggestions: \(includeSubjectSuggestions ? "yes" : "no").
            Include greeting: \(includeGreeting ? "yes" : "no").
            Include closing: \(includeClosing ? "yes" : "no").
            Include clear call-to-action: \(includeCallToAction ? "yes" : "no").
            Include bullet summary: \(includeBulletSummary ? "yes" : "no").
            Include meeting time options: \(includeMeetingTimes ? "yes" : "no").
            Must include: \(requiredPoints.isEmpty ? "none provided" : requiredPoints).
            Avoid phrases: \(avoidPhrases.isEmpty ? "none provided" : avoidPhrases).
            Additional constraints: \(additionalConstraints.isEmpty ? "none provided" : additionalConstraints).
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

private struct DraftingHeaderEffect: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.bounce.byLayer, options: .repeating, isActive: true)
        } else {
            content
        }
    }
}
