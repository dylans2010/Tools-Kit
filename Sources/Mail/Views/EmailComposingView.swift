import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Main Composer View

struct EmailComposingView: View {
    @Environment(\.dismiss) var dismiss
    let account: MailAccount
    var replyTo: MailMessage? = nil

    // Recipients
    @State private var toRecipients: [String] = []
    @State private var newRecipient = ""
    @State private var subject = ""
    @State private var messageBody = ""

    // State
    @State private var isSending = false
    @State private var showingAIPanel = false
    @State private var showingDocumentPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var sendError: String?
    @FocusState private var bodyFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                recipientsField
                Divider().padding(.horizontal)
                subjectField
                Divider().padding(.horizontal)
                bodyEditor
            }
            .navigationTitle(replyTo == nil ? "New Message" : "Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .bottom) { bottomToolbar }
            .onAppear(perform: prefillReply)
            .sheet(isPresented: $showingAIPanel) {
                AIComposerPanel(
                    replyTo: replyTo,
                    currentBody: messageBody
                ) { result in
                    messageBody = result
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPickerWrapper()
            }
            .alert("Send Failed", isPresented: Binding(
                get: { sendError != nil },
                set: { if !$0 { sendError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(sendError ?? "")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Recipients

    private var recipientsField: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("To:")
                .foregroundColor(.secondary)
                .padding(.top, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(toRecipients, id: \.self) { recipient in
                        recipientChip(recipient)
                    }
                    TextField("Add recipient", text: $newRecipient)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                        .onSubmit { commitRecipient() }
                        .frame(minWidth: 140)
                }
                .padding(.vertical, 10)
            }
        }
        .padding(.horizontal)
    }

    private func recipientChip(_ address: String) -> some View {
        HStack(spacing: 4) {
            Text(address)
                .font(.subheadline)
                .lineLimit(1)
            Button {
                toRecipients.removeAll { $0 == address }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.blue.opacity(0.12)))
        .foregroundColor(.blue)
    }

    // MARK: - Subject

    private var subjectField: some View {
        TextField("Subject", text: $subject)
            .font(.headline)
            .padding()
    }

    // MARK: - Body Editor

    private var bodyEditor: some View {
        ZStack(alignment: .topLeading) {
            if messageBody.isEmpty && !bodyFocused {
                Text("Write your message…")
                    .foregroundColor(Color(.placeholderText))
                    .padding(.top, 14)
                    .padding(.leading, 18)
            }
            TextEditor(text: $messageBody)
                .focused($bodyFocused)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") { dismiss() }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                // AI button
                Button { showingAIPanel = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("AI")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                    )
                }

                // Send button
                Button(action: send) {
                    if isSending {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .disabled(cannotSend)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(cannotSend ? Color(.systemGray4) : Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
    }

    private var cannotSend: Bool {
        (toRecipients.isEmpty && newRecipient.isEmpty) || subject.isEmpty || isSending
    }

    // MARK: - Bottom Formatting Toolbar

    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ComposeToolbarButton(icon: "bold",              label: "Bold")       { wrap("**") }
                    ComposeToolbarButton(icon: "italic",            label: "Italic")     { wrap("_") }
                    ComposeToolbarButton(icon: "underline",         label: "Underline")  { wrap("__") }
                    Divider().frame(height: 24)
                    ComposeToolbarButton(icon: "list.bullet",       label: "Bullets")    { insert("\n• ") }
                    ComposeToolbarButton(icon: "list.number",       label: "Numbers")    { insert("\n1. ") }
                    Divider().frame(height: 24)
                    ComposeToolbarButton(icon: "link",              label: "Link")       { insert("[text](url)") }
                    ComposeToolbarButton(icon: "paperclip",         label: "Attach")     { showingDocumentPicker = true }
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Photo", systemImage: "photo.on.rectangle")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 19))
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
        .background(Material.bar)
    }

    // MARK: - Helpers

    private func prefillReply() {
        guard let reply = replyTo else { return }
        toRecipients = [reply.from]
        subject = "Re: \(reply.subject)"
        let dateString = DateFormatter.localizedString(from: reply.date, dateStyle: .medium, timeStyle: .short)
        messageBody = "\n\n--- On \(dateString), \(reply.from) wrote: ---\n\(reply.body)"
    }

    private func commitRecipient() {
        let trimmed = newRecipient.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        toRecipients.append(trimmed)
        newRecipient = ""
    }

    private func insert(_ text: String) {
        messageBody += text
    }

    private func wrap(_ marker: String) {
        messageBody += "\(marker)text\(marker)"
    }

    private func send() {
        var recipients = toRecipients
        if !newRecipient.trimmingCharacters(in: .whitespaces).isEmpty {
            recipients.append(newRecipient.trimmingCharacters(in: .whitespaces))
        }
        guard !recipients.isEmpty else { return }

        isSending = true
        Task {
            do {
                let provider = iCloudMailProvider(account: account)
                let message = MailMessage(
                    id: UUID().uuidString,
                    threadId: replyTo?.threadId ?? UUID().uuidString,
                    from: account.email,
                    to: recipients,
                    cc: [],
                    bcc: [],
                    subject: subject,
                    body: messageBody,
                    htmlBody: nil,
                    date: Date(),
                    isRead: true,
                    isStarred: false,
                    attachments: []
                )
                try await provider.sendMessage(message)
                await MainActor.run {
                    isSending = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    sendError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Compose Toolbar Button

private struct ComposeToolbarButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }
}

// MARK: - AI Composer Panel

struct AIComposerPanel: View {
    let replyTo: MailMessage?
    let currentBody: String
    let onApply: (String) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var prompt = ""
    @State private var selectedAction: AIAction = .generate
    @State private var isWorking = false
    @State private var result: String?
    @State private var shimmerPhase: CGFloat = -1

    enum AIAction: String, CaseIterable {
        case generate       = "Generate"
        case rewrite        = "Rewrite"
        case shorter        = "Make Shorter"
        case professional   = "More Professional"
        case friendly       = "More Friendly"
        case continueWriting = "Continue Writing"

        var systemName: String {
            switch self {
            case .generate:        return "sparkles"
            case .rewrite:         return "arrow.2.squarepath"
            case .shorter:         return "scissors"
            case .professional:    return "briefcase"
            case .friendly:        return "face.smiling"
            case .continueWriting: return "text.append"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            Text("AI Writing Assistant")
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(.top, 16)

            // Action grid
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 10) {
                ForEach(AIAction.allCases, id: \.self) { action in
                    actionButton(action)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)

            // Context prompt (only for generate/rewrite)
            if selectedAction == .generate || selectedAction == .rewrite {
                TextField(selectedAction == .generate ? "What should this email say?" : "Describe changes…",
                          text: $prompt, axis: .vertical)
                    .lineLimit(3)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.15)))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top, 12)
            }

            // Result area
            if isWorking {
                shimmerPlaceholder
                    .padding(.horizontal)
                    .padding(.top, 12)
            } else if let text = result {
                resultArea(text)
                    .padding(.horizontal)
                    .padding(.top, 12)
            }

            // Generate button
            if result == nil {
                Button(action: runAI) {
                    HStack {
                        if isWorking {
                            ProgressView().tint(.purple)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isWorking ? "Working…" : "Generate")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.purple)
                    .cornerRadius(14)
                }
                .disabled(isWorking)
                .padding(.horizontal)
                .padding(.top, 16)
            }

            Spacer()
        }
        .presentationBackground {
            LinearGradient(colors: [.purple.opacity(0.9), .blue.opacity(0.9)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private func actionButton(_ action: AIAction) -> some View {
        Button { selectedAction = action; result = nil } label: {
            VStack(spacing: 6) {
                Image(systemName: action.systemName)
                    .font(.system(size: 20))
                Text(action.rawValue)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedAction == action ? Color.white : Color.white.opacity(0.18))
            .foregroundColor(selectedAction == action ? .purple : .white)
            .cornerRadius(12)
        }
    }

    private var shimmerPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.12))
            .frame(height: 90)
            .overlay(
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.25), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerPhase * geo.size.width)
                        .onAppear {
                            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                                shimmerPhase = 1
                            }
                        }
                }
                .clipped()
            )
    }

    private func resultArea(_ text: String) -> some View {
        VStack(spacing: 10) {
            ScrollView {
                Text(text)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxHeight: 160)
            .background(.ultraThinMaterial)
            .cornerRadius(12)

            HStack(spacing: 10) {
                Button("Retry") { result = nil }
                    .buttonStyle(.bordered)
                    .foregroundColor(.white)

                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.white)

                Button("Insert") {
                    onApply(text)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func runAI() {
        isWorking = true
        result = nil

        Task {
            do {
                let text: String
                switch selectedAction {
                case .generate:
                    let base = prompt.isEmpty ? currentBody : prompt
                    text = try await MailAIService.shared.improveDraft(base, tone: "professional")
                case .rewrite:
                    let base = prompt.isEmpty ? currentBody : "\(prompt)\n\n\(currentBody)"
                    text = try await MailAIService.shared.improveDraft(base, tone: "professional")
                case .shorter:
                    text = try await MailAIService.shared.improveDraft(currentBody, tone: "concise")
                case .professional:
                    text = try await MailAIService.shared.improveDraft(currentBody, tone: "professional")
                case .friendly:
                    text = try await MailAIService.shared.improveDraft(currentBody, tone: "friendly")
                case .continueWriting:
                    let continuePrompt = "Continue writing the following email naturally:\n\n\(currentBody)"
                    text = try await MailAIService.shared.improveDraft(continuePrompt, tone: "natural")
                }
                await MainActor.run {
                    result = text
                    isWorking = false
                }
            } catch {
                await MainActor.run { isWorking = false }
            }
        }
    }
}

// MARK: - Document Picker Wrapper

struct DocumentPickerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .content])
        return picker
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}
