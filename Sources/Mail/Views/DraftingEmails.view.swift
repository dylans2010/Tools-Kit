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
        case client = "Client"
        case internalTeam = "Internal Team"
        case executive = "Executive"
        case partner = "Partner"
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
    @State private var includeActionItems = true
    @State private var includeSubjectSuggestions = false
    @State private var includeBulletSummary = true
    @State private var includeCallToAction = true
    @State private var includeMeetingSlots = false
    @State private var selectedAudience: Audience = .client
    @State private var keywords = ""
    @State private var selectedFramework = "Standard"

    @State private var generatedBody = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showTemplatesSheet = false

    private let frameworks = ["Standard", "AIDA", "PAS", "SCQA", "STAR"]
    private let quickTemplates = [
        ("Status + Blockers", "Provide current status, key blockers, and requested support."),
        ("Follow-up Reminder", "Friendly reminder with clear next steps and deadline."),
        ("Meeting Confirmation", "Confirm meeting details and agenda in concise format."),
        ("Customer Escalation", "Summarize issue impact, urgency, and ask for immediate action.")
    ]

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
                                customTextField("Subject:", text: $subject, placeholder: "Enter Subject")
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

                                customTextField("Keywords:", text: $keywords, placeholder: "deadline, budget, next steps")
                            }
                        }

                        inputCard(title: "Style & Tone", icon: "slider.horizontal.3") {
                            VStack(spacing: 16) {
                                chipSelector(title: "Goal", selection: $selectedGoal, options: MailGoal.allCases)
                                chipSelector(title: "Style", selection: $selectedStyle, options: MailStyle.allCases)
                                chipSelector(title: "Length", selection: $selectedLength, options: OutputLength.allCases)
                                chipSelector(title: "Urgency", selection: $selectedUrgency, options: Urgency.allCases)
                                chipSelector(title: "Audience", selection: $selectedAudience, options: Audience.allCases)
                                chipSelector(title: "Framework", selection: $selectedFramework, options: frameworks)
                                Toggle("Include action items", isOn: $includeActionItems)
                                    .font(.caption.bold())
                                Toggle("Include subject suggestions", isOn: $includeSubjectSuggestions)
                                    .font(.caption.bold())
                                Toggle("Include bullet summary", isOn: $includeBulletSummary)
                                    .font(.caption.bold())
                                Toggle("Include call to action", isOn: $includeCallToAction)
                                    .font(.caption.bold())
                                Toggle("Include meeting time suggestions", isOn: $includeMeetingSlots)
                                    .font(.caption.bold())
                            }
                        }

                        if !generatedBody.isEmpty || isGenerating {
                            outputPreview
                        }
                    }
                    .padding(16)
                }

                if isGenerating {
                    ModernSheetLoadingView(
                        title: "Generating Draft",
                        subtitle: "Building a polished email style, tone, and structure."
                    )
                    .transition(.opacity)
                }
            }
            .navigationTitle("AI Composing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
            .sheet(isPresented: $showTemplatesSheet) {
                templateSheet
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
            Text("Draft New Mail")
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
                showTemplatesSheet = true
            } label: {
                Image(systemName: "square.grid.2x2")
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)

            Button {
                Task { await generateDraft() }
            } label: {
                Group {
                    if isGenerating {
                        Text("Generating…")
                            .bold()
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

    private func chipSelector(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selection.wrappedValue = option
                        } label: {
                            Text(option)
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
                Text("Creating your draft…")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
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

    private var templateSheet: some View {
        NavigationStack {
            List {
                Section("Quick Templates") {
                    ForEach(quickTemplates, id: \.0) { template in
                        Button {
                            context = template.1
                            if subject.isEmpty { subject = template.0 }
                            showTemplatesSheet = false
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.0).font(.subheadline.weight(.semibold))
                                Text(template.1).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Draft Tools")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showTemplatesSheet = false }
                }
            }
        }
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
            Copywriting framework: \(selectedFramework).
            Include action items: \(includeActionItems ? "yes" : "no").
            Include subject suggestions: \(includeSubjectSuggestions ? "yes" : "no").
            Include bullet summary: \(includeBulletSummary ? "yes" : "no").
            Include call to action: \(includeCallToAction ? "yes" : "no").
            Include suggested meeting slots: \(includeMeetingSlots ? "yes" : "no").
            Keywords to include when relevant: \(keywords).
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
