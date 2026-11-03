import SwiftUI
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

// MARK: - Models

struct AttachmentItem: Identifiable {
    let id = UUID()
    let attachment: ChatAttachment
    var decodedText: String?
    var isDecoding: Bool = false
}

// MARK: - View Model

@MainActor
final class DiagnosticsSupportAssistViewModel: ObservableObject {
    @Published var currentSession = DiagnosticChatSession()
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var pendingAttachments: [AttachmentItem] = []
    @Published var foundationModelsMessage = ""

    // Diagnostic Support Assist runs ONLY on Apple Foundation Models.
    // No AIService, no provider selection, no API key, no account, no
    // daily limit, no web search — the on-device system model is the
    // entire backend. See AFMService (FoundationModels framework).
    private var currentTask: Task<Void, Never>?

    init() {
        AFMService.shared.checkAvailability()
        foundationModelsMessage = AFMService.shared.availabilityMessage
    }

    private let systemPrompt = """
    You are the "Diagnostics Support Assist" AI, a fully intelligent system specialized in debugging and diagnosing iOS devices.
    Your expertise covers:
    - Hardware troubleshooting (sensors, battery, display, connectivity).
    - Software debugging (crashes, performance, system logs).
    - Device optimization and support.

    CRITICAL RULES:
    1. You ONLY provide support related to iOS devices and debugging.
    2. If a user asks about anything else, politely decline and redirect them to device diagnostics.
    3. You run entirely on-device on Apple Foundation Models. You have
       no web access, no API key, and no account — do not invent web
       search results, and do not claim to have searched the web.
    4. You can read text, log, crash-report, and PDF attachments the
       user uploads. You cannot see image pixels: if a photo is
       mentioned, ask the user to describe what it shows.
    5. ALWAYS use Markdown for your responses. Organize your content using '##' headers for sections, bullet points for lists, and code blocks for technical details. Ensure a structured, professional, and clear response.
    6. Be precise, technical, and helpful.
    """

    func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty || !pendingAttachments.isEmpty else { return }
        guard !isLoading else { return }

        // Cancel any previous in-flight task
        currentTask?.cancel()
        currentTask = nil

        let userMessage = ChatMessage(role: "user", content: trimmedText)

        // Ensure UI updates are isolated
        withAnimation(.spring(response: 0.3)) {
            messages.append(userMessage)
            isLoading = true
        }

        let attachmentsToSend = pendingAttachments
        let savedInput = inputText

        inputText = ""
        pendingAttachments = []
        error = nil

        currentTask = Task {
            do {
                try await self.performChat(attachmentItems: attachmentsToSend)
                if !Task.isCancelled {
                    withAnimation { self.isLoading = false }
                    self.autoSaveAndNameSession()
                }
            } catch is CancellationError {
                // Silently handle cancellation
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    self.inputText = savedInput
                    self.pendingAttachments = attachmentsToSend
                }
            }
        }
    }

    func regenerateLastResponse() {
        guard !messages.isEmpty else { return }
        if messages.last?.role == "assistant" {
            messages.removeLast()
        }

        isLoading = true
        currentTask?.cancel()

        currentTask = Task {
            do {
                try await self.performChat(attachmentItems: [])
                if !Task.isCancelled {
                    withAnimation { self.isLoading = false }
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func performChat(attachmentItems: [AttachmentItem]) async throws {
        let chatAttachments = attachmentItems.map { $0.attachment }
        let decoded = await FileDecoderHelper.decodeAttachments(chatAttachments)

        try Task.checkCancellation()

        var chatMessages = messages.filter { $0.role != "system" }
        if !decoded.text.isEmpty, !chatMessages.isEmpty {
            let lastIdx = chatMessages.count - 1
            if chatMessages[lastIdx].role == "user" {
                let updatedContent = chatMessages[lastIdx].content + "\n\n[Attachment Data]:\n" + decoded.text
                chatMessages[lastIdx] = ChatMessage(id: chatMessages[lastIdx].id, role: chatMessages[lastIdx].role, content: updatedContent, timestamp: chatMessages[lastIdx].timestamp)
            }
        }
        if !decoded.images.isEmpty {
            // On-device Foundation Models in this app is text-only: image
            // pixels are never sent anywhere. Say so in the prompt rather
            // than pretending to have analysed the photo.
            let note = "\n\n[Note: the user also attached \(decoded.images.count) image(s). You cannot see image pixels, so do not describe them. Ask the user to describe what the photo shows if it matters.]"
            if !chatMessages.isEmpty {
                let lastIdx = chatMessages.count - 1
                chatMessages[lastIdx] = ChatMessage(id: chatMessages[lastIdx].id, role: chatMessages[lastIdx].role, content: chatMessages[lastIdx].content + note, timestamp: chatMessages[lastIdx].timestamp)
            }
        }

        // Full conversation history is passed in the prompt because
        // AFMService creates a fresh LanguageModelSession per request.
        let history = chatMessages.map { "\($0.role): \($0.content)" }.joined(separator: "\n\n")
        let response = try await AFMService.shared.generateResponse(
            prompt: history,
            systemPrompt: systemPrompt
        )

        try Task.checkCancellation()
        await MainActor.run {
            withAnimation {
                messages.append(ChatMessage(role: "assistant", content: response))
            }
        }
    }

    func addAttachment(_ attachment: ChatAttachment) {
        let newItem = AttachmentItem(attachment: attachment, isDecoding: true)
        let id = newItem.id
        pendingAttachments.append(newItem)

        Task {
            let decoded = await FileDecoderHelper.decode(attachment)
            if let index = pendingAttachments.firstIndex(where: { $0.id == id }) {
                pendingAttachments[index].decodedText = decoded
                pendingAttachments[index].isDecoding = false
            }
        }
    }

    func removeAttachment(at index: Int) {
        if index < pendingAttachments.count {
            pendingAttachments.remove(at: index)
        }
    }

    func clearChat() {
        currentTask?.cancel()
        currentTask = nil
        currentSession = DiagnosticChatSession()
        messages = []
        isLoading = false
        error = nil
    }

    func loadSession(_ session: DiagnosticChatSession) {
        currentSession = session
        messages = session.messages
    }

    private func autoSaveAndNameSession() {
        currentSession.messages = messages
        DiagnosticChatStore.shared.saveSession(currentSession)

        // Auto-name if it's still default and has enough context
        if currentSession.title == "New Diagnostic Session" && messages.count >= 2 {
            Task {
                if let suggestedTitle = await DiagnosticChatNamingService.shared.suggestTitle(for: messages) {
                    await MainActor.run {
                        self.currentSession.title = suggestedTitle
                        DiagnosticChatStore.shared.saveSession(self.currentSession)
                    }
                }
            }
        }
    }
}

// MARK: - View

struct DiagnosticsSupportAssistView: View {
    @StateObject private var viewModel = DiagnosticsSupportAssistViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showFileImporter = false
    @State private var showHistory = false
    @State private var showPresets = false

    private let subtleBlue = Color.blue.opacity(0.05)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chatScrollView

                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }

                attachmentPreviewBar

                inputArea
            }
            .background(
                ZStack {
                    subtleBlue.ignoresSafeArea()
                    LinearGradient(
                        colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ).ignoresSafeArea()
                }
            )
            .navigationTitle("Support Assist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }

                        Menu {
                            Button(role: .destructive, action: viewModel.clearChat) {
                                Label("New Chat", systemImage: "plus.bubble")
                            }
                            Button(action: viewModel.clearChat) {
                                Label("Clear Messages", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showFileImporter) {
                FileImporterRepresentableView(allowedContentTypes: [.data, .pdf, .text], allowsMultipleSelection: false) { urls in
                    handleImportedURLs(urls)
                }
            }
            .sheet(isPresented: $showHistory) {
                DiagnosticChatHistory { session in
                    viewModel.loadSession(session)
                }
            }
            .sheet(isPresented: $showPresets) {
                DiagnosticPresetPromptsSheet { prompt in
                    viewModel.inputText = prompt
                }
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Chat Scroll View

    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        emptyStateView
                    }

                    ForEach(viewModel.messages, id: \.id) { message in
                        MessageBubbleView(message: message) {
                            viewModel.regenerateLastResponse()
                        }
                        .id(message.id)
                    }

                    if viewModel.isLoading {
                        typingIndicator
                            .id("typing-indicator")
                    }
                }
                .padding()
            }
            .background(subtleBlue)
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isLoading) { _, isLoading in
                if isLoading {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        proxy.scrollTo("typing-indicator", anchor: .bottom)
                    }
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = viewModel.messages.last?.id {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .opacity(0.6)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: viewModel.isLoading
                        )
                        .scaleEffect(viewModel.isLoading ? 1.0 : 0.5)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "app.background.dotted")
                .font(.system(size: 60))
                .symbolEffect(.variableColor.iterative)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 40)

            Text("Diagnostic Support Assist")
                .font(.headline)

            Text("Ask me anything about your iOS device. Upload logs, crash reports, or text files for analysis.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Text("Powered only by Apple Foundation Models, on-device. No API key, no account, no sign-in.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Text(viewModel.foundationModelsMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Attachment Preview

    private var attachmentPreviewBar: some View {
        Group {
            if !viewModel.pendingAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.pendingAttachments.indices, id: \.self) { index in
                            AttachmentThumbnail(item: viewModel.pendingAttachments[index]) {
                                viewModel.removeAttachment(at: index)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.secondarySystemBackground))
            }
        }
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Menu {
                    Button {
                        showPresets = true
                    } label: {
                        Label("Preset Prompts", systemImage: "sparkles.rectangle.stack")
                    }
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("Files", systemImage: "doc.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }

                HStack {
                    TextField("Describe The Issue", text: $viewModel.inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .lineLimit(1...5)
                }
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    }
                )

                Button(action: viewModel.sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.inputText.isEmpty && viewModel.pendingAttachments.isEmpty ? .secondary : .blue)
                }
                .disabled((viewModel.inputText.isEmpty && viewModel.pendingAttachments.isEmpty) || viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - File Handling

    private func handleImportedURLs(_ urls: [URL]) {
        guard let url = urls.first else { return }
        let accessing = url.startAccessingSecurityScopedResource()

        let fileName = url.lastPathComponent
        let ext = url.pathExtension.lowercased()
        let mime = mimeType(for: ext)

        // The on-device model is text-only in this app, so photos are
        // not accepted here — accepting them would imply vision that
        // does not exist. The user can describe a photo in words.
        if mime.hasPrefix("image") {
            viewModel.error = "Photos are not analysed by the on-device Foundation Model. Attach a log or text file instead, or describe the photo in your message."
            return
        }

        Task.detached(priority: .userInitiated) {
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            guard var data = try? Data(contentsOf: url) else { return }

            if mime.hasPrefix("image"), let uiImage = UIImage(data: data) {
                if let compressedData = uiImage.jpegData(compressionQuality: 0.5) {
                    data = compressedData
                }
            }

            let attachment = ChatAttachment(data: data, mimeType: mime, fileName: fileName)
            await MainActor.run {
                viewModel.addAttachment(attachment)
            }
        }
    }

    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "heic", "heif": return "image/heic"
        case "pdf": return "application/pdf"
        case "txt": return "text/plain"
        case "json": return "application/json"
        case "swift": return "application/x-swift"
        case "log": return "text/plain"
        case "xml": return "application/xml"
        case "csv": return "text/csv"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ChatMessage
    var onRegenerate: () -> Void = {}

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if isUser {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, Color.blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(ChatBubbleShape(isUser: true))
                        .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        SDKMarkdownView(text: message.content)

                        HStack(spacing: 16) {
                            Button {
                                UIPasteboard.general.string = message.content
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)

                            Button(action: onRegenerate) {
                                Label("Regenerate", systemImage: "arrow.clockwise")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(.secondarySystemGroupedBackground), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(ChatBubbleShape(isUser: false))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }

                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

struct ChatBubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: isUser ?
                [.topLeft, .bottomLeft, .bottomRight] :
                [.topRight, .bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: 18, height: 18)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preset Prompts Sheet

struct DiagnosticPresetPromptsSheet: View {
    var onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var displayedPrompts: [DiagnosticPresetPrompt] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(displayedPrompts, id: \.id) { item in
                        Button {
                            onSelect(item.prompt)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(item.prompt)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    HStack {
                        Text("Suggested Diagnostics")
                        Spacer()
                        Button(action: shuffle) {
                            Label("Shuffle", systemImage: "arrow.2.squarepath")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Diagnostic Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear(perform: shuffle)
        }
    }

    private func shuffle() {
        withAnimation {
            displayedPrompts = Array(DiagnosticPresetPrompts.all.shuffled().prefix(5))
        }
    }
}

// MARK: - Attachment Thumbnail

struct AttachmentThumbnail: View {
    let item: AttachmentItem
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                ZStack {
                    if item.attachment.mimeType.hasPrefix("image") {
                        if let uiImage = UIImage(data: item.attachment.data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    } else {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 30))
                            .frame(width: 60, height: 60)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    if item.isDecoding {
                        Color.black.opacity(0.3)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(width: 60, height: 60)

                Text(item.attachment.fileName)
                    .font(.caption2)
                    .lineLimit(1)
                    .frame(width: 60)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .offset(x: 5, y: -5)
        }
    }
}
