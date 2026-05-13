import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AIChatToolView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @State private var showSettings = false
    @State private var showFileImporter = false
    @State private var showPhotoPicker = false
    @State private var showVisionAlert = false
    @State private var showHistorySheet = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    var body: some View {
        VStack {
            if !viewModel.isApiKeySaved {
                apiKeySetupView
            } else {
                chatView
            }
        }
        .navigationTitle("AI Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isApiKeySaved {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Settings") { showSettings = true }
                        Button("History") { showHistorySheet = true }
                        Button("Clear Chat", role: .destructive, action: viewModel.clearChat)
                        Button("Change API Key") {
                            viewModel.deleteKey()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            AIChatSettingsView(settings: $viewModel.settingsManager.settings)
        }
        .sheet(isPresented: $showHistorySheet) {
            NavigationStack {
                List(viewModel.messages) { message in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(message.role.capitalized).font(.caption).foregroundColor(.secondary)
                        Text(message.content).lineLimit(4)
                        Text(message.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Chat History")
            }
        }
        .sheet(isPresented: $showFileImporter) {
            FileImporterRepresentableView(allowedContentTypes: [.data, .image, .pdf, .text], allowsMultipleSelection: false) { urls in
                handleImportedURLs(urls)
                showFileImporter = false
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item = item else { return }
            loadPhoto(from: item)
        }
        .alert("Vision Not Supported", isPresented: $showVisionAlert) {
            Button("Open Settings") { showSettings = true }
            Button("OK", role: .cancel) {}
        } message: {
            Text("The current model doesn't support image/file attachments. Switch to a vision-capable model (e.g. GPT-4o, Gemini, Claude) in Settings.")
        }
    }

    private var apiKeySetupView: some View {
        let provider = viewModel.currentProvider
        return VStack(spacing: 20) {
            Image(systemName: provider?.icon ?? "key.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("\(provider?.name ?? "AI") API Key")
                .font(.title2)
                .bold()

            Text("Enter your \(provider?.name ?? "AI provider") API key to start chatting. Your key is stored securely in the Keychain.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            SecureField(provider?.apiKeyPlaceholder ?? "API Key", text: $viewModel.apiKey)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            Button(action: viewModel.saveKey) {
                Text("Save and Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(viewModel.apiKey.isEmpty)

            if let url = provider?.apiKeyURL {
                Link("Get an API key from \(provider?.name ?? "your provider")", destination: url)
                    .font(.footnote)
            }

            Button("Change Provider") { showSettings = true }
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(
                                message: message,
                                fontSize: viewModel.settingsManager.settings.fontSize,
                                bubbleColorHex: viewModel.settingsManager.settings.bubbleColorHex,
                                showTimestamp: viewModel.settingsManager.settings.showTimestamps
                            )
                        }
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(18)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }

            if !viewModel.pendingAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.pendingAttachments.indices, id: \.self) { index in
                            AttachmentChip(attachment: viewModel.pendingAttachments[index]) {
                                viewModel.removeAttachment(at: index)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 6)
                .background(Color(.systemBackground))
            }

            HStack(spacing: 8) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }

                Button {
                    if !viewModel.currentModelSupportsVision() {
                        showVisionAlert = true
                    } else {
                        showFileImporter = true
                    }
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }

                TextField("Message", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .skillPicker(text: $viewModel.inputText)

                Button(action: viewModel.sendMessage) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    }
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    private func handleImportedURLs(_ urls: [URL]) {
        guard let url = urls.first else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return }
        let mimeType = mimeType(for: url.pathExtension)
        let attachment = ChatAttachment(data: data, mimeType: mimeType, fileName: url.lastPathComponent)
        if !viewModel.currentModelSupportsVision() {
            showVisionAlert = true
        } else {
            viewModel.addAttachment(attachment)
        }
    }

    private func loadPhoto(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    guard let data = data else { return }
                    let attachment = ChatAttachment(data: data, mimeType: "image/jpeg", fileName: "photo.jpg")
                    if !self.viewModel.currentModelSupportsVision() {
                        self.showVisionAlert = true
                    } else {
                        self.viewModel.addAttachment(attachment)
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
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "pdf": return "application/pdf"
        case "txt": return "text/plain"
        default: return "application/octet-stream"
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    var fontSize: Double = 16
    var bubbleColorHex: String = "007AFF"
    var showTimestamp: Bool = false

    var isUser: Bool { message.role == "user" }

    var bubbleColor: Color {
        isUser ? (Color(hex: bubbleColorHex) ?? .blue) : Color(.secondarySystemBackground)
    }

    var body: some View {
        HStack(alignment: .bottom) {
            if isUser { Spacer() }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
                MarkdownBubbleText(markdown: message.content, fontSize: fontSize, foregroundColor: isUser ? .white : .primary)
                    .font(.system(size: fontSize))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(bubbleColor)
                    .foregroundColor(isUser ? .white : .primary)
                    .cornerRadius(18)
                    .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)

                if showTimestamp {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if !isUser { Spacer() }
        }
    }
}

struct MarkdownBubbleText: View {
    let markdown: String
    let fontSize: Double
    let foregroundColor: Color

    var body: some View {
        if let parsed = try? AttributedString(markdown: markdown) {
            Text(parsed)
                .font(.system(size: fontSize))
                .foregroundColor(foregroundColor)
        } else {
            Text(markdown)
                .font(.system(size: fontSize))
                .foregroundColor(foregroundColor)
        }
    }
}

struct AttachmentChip: View {
    let attachment: ChatAttachment
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(.blue)
            Text(attachment.fileName)
                .font(.caption)
                .lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    var iconName: String {
        if attachment.mimeType.hasPrefix("image") { return "photo" }
        if attachment.mimeType == "application/pdf" { return "doc.fill" }
        return "paperclip"
    }
}

struct AIChatTool: Tool {
    let name = "AI Chat"
    let icon = "bubble.left.and.bubble.right.fill"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "AI chatbot with multi-provider support (OpenAI, Anthropic, Gemini, Mistral, OpenRouter)"
    let requiresAPI = true

    var view: AnyView {
        AnyView(AIChatToolView())
    }
}
