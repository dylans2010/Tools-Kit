import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Web Search Tool

struct WebSearchTool {
    func search(query: String) async throws -> String {
        // In a real implementation, this would call a search API.
        // For this AI assistant, we'll simulate a tool that the AI can "call".

        // This struct exists as requested by the user.
        return "Search results for: \(query)\n1. Apple Support: iOS Debugging Guide\n2. StackOverflow: Common iOS device issues\n3. Developer Documentation: Device Diagnostics"
    }
}

// MARK: - View Model

@MainActor
final class DiagnosticsSupportAssistViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var pendingAttachments: [ChatAttachment] = []
    @Published var isWebSearchEnabled: Bool = false
    @Published var searchingStatus: String?

    private let aiService = AIService.shared
    private let webSearchTool = WebSearchTool()

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

        let userMessage = ChatMessage(role: "user", content: trimmedText)
        messages.append(userMessage)

        let attachmentsToSend = pendingAttachments
        let currentInput = trimmedText

        inputText = ""
        pendingAttachments = []
        isLoading = true
        error = nil

        Task {
            do {
                try await performChat(attachments: attachmentsToSend)
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                self.isLoading = false
                // Restore input on failure
                self.inputText = currentInput
                self.pendingAttachments = attachmentsToSend
            }
        }
    }

    private func performChat(attachments: [ChatAttachment]) async throws {
        var currentSystemPrompt = systemPrompt

        // Use FileDecoderHelper to split attachments
        let decoded = FileDecoderHelper.decodeAttachments(attachments)

        // Prepare messages - inject decoded file text into the last user message if available
        var chatMessages = messages
        if !decoded.text.isEmpty && !chatMessages.isEmpty {
            let lastIdx = chatMessages.count - 1
            let updatedContent = chatMessages[lastIdx].content + decoded.text
            chatMessages[lastIdx] = ChatMessage(role: chatMessages[lastIdx].role, content: updatedContent)
        }

        if isWebSearchEnabled {
            currentSystemPrompt += "\n\nCRITICAL: Web search is enabled. You MUST use the [SEARCH: query] tool to gather the latest diagnostic information, error codes, or troubleshooting steps before providing your final response."
            searchingStatus = "Thinking..."
        }

        var response = try await aiService.processMessages(
            messages: [ChatMessage(role: "system", content: currentSystemPrompt)] + chatMessages,
            attachments: decoded.images
        )

        // Enforce web search if enabled
        if isWebSearchEnabled {
            var searchResult: String?
            var queryToUse: String?

            if response.contains("[SEARCH:"), let query = extractSearchQuery(from: response) {
                queryToUse = query
            } else {
                // Manually trigger search if AI didn't follow the "FULLY REQUIRED" rule
                queryToUse = messages.last?.content ?? "iOS diagnostic issues"
            }

            if let query = queryToUse {
                searchingStatus = "Searching: \(query)"
                searchResult = try await webSearchTool.search(query: query)

                let toolResultMessage = ChatMessage(role: "system", content: "Search Result: \(searchResult ?? "")")

                searchingStatus = "Analyzing results..."

                // Get final response after search
                response = try await aiService.processMessages(
                    messages: [ChatMessage(role: "system", content: currentSystemPrompt)] + chatMessages + [toolResultMessage],
                    attachments: []
                )
            }
        }

        searchingStatus = nil
        messages.append(ChatMessage(role: "assistant", content: response))
    }

    private func extractSearchQuery(from text: String) -> String? {
        guard let startRange = text.range(of: "[SEARCH:") else { return nil }
        let remaining = text[startRange.upperBound...]
        guard let endRange = remaining.range(of: "]") else { return nil }
        return String(remaining[..<endRange.lowerBound]).trimmingCharacters(in: .whitespaces)
    }

    func addAttachment(_ attachment: ChatAttachment) {
        pendingAttachments.append(attachment)
    }

    func removeAttachment(at index: Int) {
        if index < pendingAttachments.count {
            pendingAttachments.remove(at: index)
        }
    }

    func clearChat() {
        messages = []
    }
}

// MARK: - View

struct DiagnosticsSupportAssistView: View {
    @StateObject private var viewModel = DiagnosticsSupportAssistViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle blue gradient background
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    chatScrollView

                    if let status = viewModel.searchingStatus {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .symbolEffect(.variableColor.iterative)
                                .foregroundColor(.blue)

                            Text(status)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if let error = viewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }

                    attachmentPreviewBar

                    inputArea
                }
            }
            .navigationTitle("Support Assist")
            .navigationBarTitleDisplayMode(.inline)
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
                    Button(action: viewModel.clearChat) {
                        Image(systemName: "trash")
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
        }
    }

    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.messages.isEmpty {
                        emptyStateView
                    }

                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastId = viewModel.messages.last?.id {
                    // Small delay to prevent UI thread saturation during rapid updates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding(.top, 40)

            Text("Intelligent Diagnostics")
                .font(.headline)

            Text("Ask me anything about your iOS device. Upload logs, crash reports, or photos of hardware issues for analysis.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var attachmentPreviewBar: some View {
        Group {
            if !viewModel.pendingAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.pendingAttachments.indices, id: \.self) { index in
                            AttachmentThumbnail(attachment: viewModel.pendingAttachments[index]) {
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

    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Menu {
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

                TextField("Describe the issue...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .lineLimit(1...5)

                Button(action: viewModel.sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(viewModel.inputText.isEmpty && viewModel.pendingAttachments.isEmpty ? .secondary : .blue)
                }
                .disabled(viewModel.inputText.isEmpty && viewModel.pendingAttachments.isEmpty || viewModel.isLoading)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    private func handleImportedURLs(_ urls: [URL]) {
        guard let url = urls.first else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard var data = try? Data(contentsOf: url) else { return }
        let ext = url.pathExtension.lowercased()
        let mime = mimeType(for: ext)

        // Compress images to reduce payload size and prevent errors
        if mime.hasPrefix("image"), let uiImage = UIImage(data: data) {
            if let compressedData = uiImage.jpegData(compressionQuality: 0.5) {
                data = compressedData
            }
        }

        let attachment = ChatAttachment(data: data, mimeType: mime, fileName: url.lastPathComponent)
        viewModel.addAttachment(attachment)
    }

    private func loadPhoto(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if var data = data {
                        // Compress images to reduce payload size and prevent errors
                        if let uiImage = UIImage(data: data),
                           let compressedData = uiImage.jpegData(compressionQuality: 0.5) {
                            data = compressedData
                        }
                        let attachment = ChatAttachment(data: data, mimeType: "image/jpeg", fileName: "image.jpg")
                        viewModel.addAttachment(attachment)
                    }
                case .failure:
                    break
                }
                self.selectedPhotoItem = nil
            }
        }
    }

    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "pdf": return "application/pdf"
        case "txt": return "text/plain"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Support Components

struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer() }

            VStack(alignment: isUser ? .trailing : .leading) {
                if isUser {
                    Text(message.content)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                } else {
                    SDKMarkdownView(text: message.content)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(15)
                }
            }
            .frame(maxWidth: 300, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer() }
        }
    }
}

struct AttachmentThumbnail: View {
    let attachment: ChatAttachment
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                if attachment.mimeType.hasPrefix("image") {
                    if let uiImage = UIImage(data: attachment.data) {
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
                Text(attachment.fileName)
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
