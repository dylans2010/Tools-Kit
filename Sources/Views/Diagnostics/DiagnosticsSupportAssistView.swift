import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

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
    @Published var isWebSearchEnabled: Bool = false
    @Published var searchingStatus: String?
    @Published var lastSearchResults: [AIService.WebSearchResult] = []
    @Published var lastSearchQuery: String = ""
    @Published var showSearchResults: Bool = false

    private let aiService = AIService.shared
    private var currentTask: Task<Void, Never>?

    private let systemPrompt = """
    You are the "Diagnostics Support Assist" AI, a fully intelligent system specialized in debugging and diagnosing iOS devices.
    Your expertise covers:
    - Hardware troubleshooting (sensors, battery, display, connectivity).
    - Software debugging (crashes, performance, system logs).
    - Device optimization and support.

    CRITICAL RULES:
    1. You ONLY provide support related to iOS devices and debugging.
    2. If a user asks about anything else, politely decline and redirect them to device diagnostics.
    3. You have access to a conceptual "WebSearchTool" if you need more context about specific error codes or device issues.
       To use it, respond ONLY with: [SEARCH: your query]
    4. You can analyze images and files uploaded by the user to identify hardware damage or inspect log files.
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
        var currentSystemPrompt = systemPrompt

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

        if isWebSearchEnabled {
            currentSystemPrompt += "\n\nCRITICAL: Web search is ENABLED. You MUST perform a web search before answering any user question. Identify the core technical query and use the [SEARCH: query] tool. Do not provide a final answer until search results are analyzed."
            await MainActor.run { searchingStatus = "Thinking..." }
        }

        try Task.checkCancellation()

        let response = try await aiService.processMessages(
            messages: [ChatMessage(role: "system", content: currentSystemPrompt)] + chatMessages,
            attachments: decoded.images
        )

        try Task.checkCancellation()

        if isWebSearchEnabled, let query = extractSearchQuery(from: response) {
            await MainActor.run { searchingStatus = "Searching: \(query)..." }
            let searchResponse = await aiService.performFullWebSearch(query: query)

            try Task.checkCancellation()

            await MainActor.run {
                lastSearchResults = searchResponse.results
                lastSearchQuery = query
                searchingStatus = "Analyzing Results..."
            }

            let searchContext = ChatMessage(role: "system", content: "Search results for '\(query)':\n\(searchResponse.summary)")
            let updatedMessages = [ChatMessage(role: "system", content: currentSystemPrompt)] + chatMessages + [ChatMessage(role: "assistant", content: response), searchContext]

            let finalResponse = try await aiService.processMessages(
                messages: updatedMessages,
                attachments: decoded.images
            )

            try Task.checkCancellation()
            await MainActor.run {
                searchingStatus = nil
                withAnimation {
                    messages.append(ChatMessage(role: "assistant", content: finalResponse))
                }
            }
        } else {
            await MainActor.run {
                searchingStatus = nil
                withAnimation {
                    messages.append(ChatMessage(role: "assistant", content: response))
                }
            }
        }
    }

    private func extractSearchQuery(from text: String) -> String? {
        guard let startRange = text.range(of: "[SEARCH:") else { return nil }
        let remaining = text[startRange.upperBound...]
        guard let endRange = remaining.range(of: "]") else { return nil }
        return String(remaining[..<endRange.lowerBound]).trimmingCharacters(in: .whitespaces)
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

    func addImageFromLibrary(_ image: UIImage) {
        Task {
            let attachment = await FileDecoderHelper.decodeImageFromLibrary(image)
            addAttachment(attachment)
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
        searchingStatus = nil
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

    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var showHistory = false
    @State private var showPresets = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private let subtleBlue = Color.blue.opacity(0.05)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chatScrollView

                if let status = viewModel.searchingStatus {
                    searchStatusBar(status: status)
                }

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
                ToolbarItem(placement: .principal) {
                    Toggle("Web Search", isOn: $viewModel.isWebSearchEnabled)
                        .toggleStyle(.button)
                        .controlSize(.small)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if !viewModel.lastSearchResults.isEmpty {
                            Button {
                                viewModel.showSearchResults = true
                            } label: {
                                Image(systemName: "globe.badge.chevron.backward")
                            }
                        }

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
                FileImporterRepresentableView(allowedContentTypes: [.data, .image, .pdf, .text], allowsMultipleSelection: false) { urls in
                    handleImportedURLs(urls)
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                if let newItem {
                    loadPhoto(from: newItem)
                }
            }
            .sheet(isPresented: $viewModel.showSearchResults) {
                WebSearchResultsSheet(
                    query: viewModel.lastSearchQuery,
                    results: viewModel.lastSearchResults
                )
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

            Text("Ask me anything about your iOS device. Upload logs, crash reports, or photos of hardware issues for analysis.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Search Status Bar

    private func searchStatusBar(status: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .symbolEffect(.variableColor.iterative)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(status)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            if !viewModel.lastSearchResults.isEmpty {
                Button {
                    viewModel.showSearchResults = true
                } label: {
                    Text("View Sources")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .transition(.move(edge: .bottom).combined(with: .opacity))
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
                        showPhotoPicker = true
                    } label: {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
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

    private func loadPhoto(from item: PhotosPickerItem) {
        Task {
            defer { selectedPhotoItem = nil }
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.addImageFromLibrary(uiImage)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.error = "Failed to load photo: \(error.localizedDescription)"
                }
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

// MARK: - Web Search Results Sheet

struct WebSearchResultsSheet: View {
    let query: String
    let results: [AIService.WebSearchResult]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.blue)
                        Text(query)
                            .font(.subheadline.weight(.medium))
                    }
                } header: {
                    Text("Search Query")
                }

                Section {
                    if results.isEmpty {
                        ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("No web results were found for this query."))
                    } else {
                        ForEach(results, id: \.id) { result in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(result.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)

                                if !result.snippet.isEmpty {
                                    Text(result.snippet)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                }

                                if !result.url.isEmpty {
                                    Link(destination: URL(string: result.url) ?? URL(string: "about:blank")!) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "link")
                                                .font(.caption2)
                                            Text(result.url)
                                                .font(.caption2)
                                                .lineLimit(1)
                                        }
                                        .foregroundStyle(.blue)
                                    }
                                }

                                HStack {
                                    Text(result.source)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Capsule())

                                    Spacer()

                                    Text(result.timestamp, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("\(results.count) Results")
                }
            }
            .navigationTitle("Search Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
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
