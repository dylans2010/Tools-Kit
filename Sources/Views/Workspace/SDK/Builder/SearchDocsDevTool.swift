import SwiftUI
import Combine

// MARK: - Models

struct DocElement: Identifiable, Sendable {
    let id = UUID()
    let type: ElementType
    let content: String

    enum ElementType: Sendable {
        case heading1, heading2, heading3, paragraph, code, list
    }
}

struct ChatMessageEntry: Identifiable {
    let id = UUID()
    let role: String
    let content: String
    let timestamp = Date()
}

// MARK: - Tool Implementation

struct SearchDocsDevTool: DevTool {
    let id = "docs-intel-system"
    let name = "SearchDocs"
    let category: DevToolCategory = .utilities
    let icon = "doc.text.magnifyingglass"
    let description = "Transform any documentation site into an AI-powered reading environment"

    func render() -> some View {
        SearchDocsView()
    }
}

// MARK: - View Model

@MainActor
class SearchDocsViewModel: ObservableObject {
    @Published var urlString: String = ""
    @Published var isLoading: Bool = false
    @Published var elements: [DocElement] = []
    @Published var chatHistory: [ChatMessageEntry] = []
    @Published var currentQuery: String = ""
    @Published var errorMessage: String?
    @Published var viewMode: DocViewMode = .reader
    @Published var isTyping: Bool = false

    enum DocViewMode {
        case reader, chat
    }

    func fetchDocs() async {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }

        isLoading = true
        errorMessage = nil
        elements = []

        do {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            guard let html = String(data: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }

            // Move parsing to background to avoid blocking main thread
            let parsedElements = try await Task.detached(priority: .userInitiated) {
                try Self.parseHTML(html)
            }.value

            self.elements = parsedElements
            self.viewMode = .reader

        } catch {
            errorMessage = "Failed to fetch documentation: \(error.localizedDescription)"
        }

        isLoading = false
    }

    nonisolated private static func parseHTML(_ html: String) throws -> [DocElement] {
        var parsed: [DocElement] = []

        // 1. Pre-process: Strip noisy tags that shouldn't be parsed
        var cleanHTML = html
        let noisePatterns = [
            "<script[\\s\\S]*?>[\\s\\S]*?</script>",
            "<style[\\s\\S]*?>[\\s\\S]*?</style>",
            "<nav[\\s\\S]*?>[\\s\\S]*?</nav>",
            "<footer[\\s\\S]*?>[\\s\\S]*?</footer>",
            "<!--[\\s\\S]*?-->"
        ]

        for pattern in noisePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                cleanHTML = regex.stringByReplacingMatches(in: cleanHTML, options: [], range: NSRange(location: 0, length: cleanHTML.utf16.count), withTemplate: "")
            }
        }

        // 2. Try to isolate main content area
        var targetHTML = cleanHTML
        let contentContainers = ["<main[\\s\\S]*?>([\\s\\S]*?)</main>", "<article[\\s\\S]*?>([\\s\\S]*?)</article>", "<div[^>]*class=\"[^\"]*content[^\"]*\"[\\s\\S]*?>([\\s\\S]*?)</div>"]

        for containerPattern in contentContainers {
            if let regex = try? NSRegularExpression(pattern: containerPattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: targetHTML.utf16.count)
                if let match = regex.firstMatch(in: targetHTML, options: [], range: range),
                   let contentRange = Range(match.range(at: 1), in: targetHTML) {
                    targetHTML = String(targetHTML[contentRange])
                    break
                }
            }
        }

        // 3. Extract semantic blocks
        let patterns: [(DocElement.ElementType, String)] = [
            (.heading1, "<h1[^>]*>([\\s\\S]*?)</h1>"),
            (.heading2, "<h2[^>]*>([\\s\\S]*?)</h2>"),
            (.heading3, "<h3[^>]*>([\\s\\S]*?)</h3>"),
            (.code, "<pre[^>]*>([\\s\\S]*?)</pre>"),
            (.paragraph, "<p[^>]*>([\\s\\S]*?)</p>"),
            (.list, "<li[^>]*>([\\s\\S]*?)</li>")
        ]

        var currentIndex = targetHTML.startIndex
        while currentIndex < targetHTML.endIndex {
            var earliestMatch: (DocElement.ElementType, NSTextCheckingResult)?

            for (type, pattern) in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                    let range = NSRange(currentIndex..., in: targetHTML)
                    if let match = regex.firstMatch(in: targetHTML, options: [], range: range) {
                        if let earliest = earliestMatch {
                            if match.range.location < earliest.1.range.location {
                                earliestMatch = (type, match)
                            }
                        } else {
                            earliestMatch = (type, match)
                        }
                    }
                }
            }

            if let (type, match) = earliestMatch {
                if let contentRange = Range(match.range(at: 1), in: targetHTML) {
                    let rawContent = String(targetHTML[contentRange])
                    let cleanContent = Self.cleanTags(rawContent)
                    if !cleanContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        parsed.append(DocElement(type: type, content: cleanContent))
                    }
                }

                if let matchRange = Range(match.range, in: targetHTML) {
                    currentIndex = matchRange.upperBound
                } else {
                    currentIndex = targetHTML.index(after: currentIndex)
                }
            } else {
                break
            }
        }

        // 4. Fallback: If nothing found, grab all text from body
        if parsed.isEmpty {
            let bodyPattern = "<body[\\s\\S]*?>([\\s\\S]*?)</body>"
            if let regex = try? NSRegularExpression(pattern: bodyPattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: cleanHTML, options: [], range: NSRange(location: 0, length: cleanHTML.utf16.count)),
               let contentRange = Range(match.range(at: 1), in: cleanHTML) {
                let bodyText = Self.cleanTags(String(cleanHTML[contentRange]))
                if !bodyText.isEmpty {
                    parsed.append(DocElement(type: .paragraph, content: bodyText))
                }
            }
        }

        return parsed
    }

    nonisolated private static func cleanTags(_ html: String) -> String {
        return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func askAI() async {
        guard !currentQuery.isEmpty else { return }

        let userMsg = chatHistory.isEmpty ? currentQuery : currentQuery
        chatHistory.append(ChatMessageEntry(role: "user", content: userMsg))
        let query = currentQuery
        currentQuery = ""

        isTyping = true

        let context = elements.map { "\($0.type): \($0.content)" }.joined(separator: "\n")
        let prompt = """
        Use ONLY the following documentation context to answer the user's question.
        If the information is not present in the context, explicitly say "I cannot find that information in the provided documentation."

        Context:
        \(context.prefix(15000))

        Question: \(query)
        """

        do {
            let response = try await AIService.shared.processText(prompt: prompt, systemPrompt: "You are a documentation assistant. Be precise and strictly follow the provided context.")
            chatHistory.append(ChatMessageEntry(role: "assistant", content: response))
        } catch {
            chatHistory.append(ChatMessageEntry(role: "assistant", content: "Error communicating with AI: \(error.localizedDescription)"))
        }

        isTyping = false
    }
}

// MARK: - UI

struct SearchDocsView: View {
    @StateObject private var viewModel = SearchDocsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // URL Bar
            HStack(spacing: 10) {
                TextField("Docs URL", text: $viewModel.urlString)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)

                Button(action: {
                    Task { await viewModel.fetchDocs() }
                }) {
                    if viewModel.isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                }
                .disabled(viewModel.urlString.isEmpty || viewModel.isLoading)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))

            if !viewModel.elements.isEmpty {
                Picker("Mode", selection: $viewModel.viewMode) {
                    Text("Reader").tag(SearchDocsViewModel.DocViewMode.reader)
                    Text("Chat").tag(SearchDocsViewModel.DocViewMode.chat)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                ZStack {
                    if viewModel.viewMode == .reader {
                        readerView
                    } else {
                        chatView
                    }
                }
            } else if !viewModel.isLoading {
                ContentUnavailableView(
                    "No Documentation Loaded",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Enter a documentation URL to begin.")
                )
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Parsing documentation structure...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    private var readerView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.elements) { element in
                    switch element.type {
                    case .heading1:
                        Text(element.content)
                            .font(.system(size: 28, weight: .bold))
                            .padding(.top, 10)
                    case .heading2:
                        Text(element.content)
                            .font(.system(size: 22, weight: .bold))
                            .padding(.top, 6)
                    case .heading3:
                        Text(element.content)
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.top, 4)
                    case .paragraph:
                        Text(element.content)
                            .font(.body)
                            .lineSpacing(4)
                    case .code:
                        Text(element.content)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    case .list:
                        HStack(alignment: .top, spacing: 8) {
                            Text("•").bold()
                            Text(element.content)
                        }
                        .padding(.leading, 8)
                    }
                }
            }
            .padding()
        }
    }

    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.chatHistory) { entry in
                            chatBubble(entry)
                        }

                        if viewModel.isTyping {
                            typingIndicator
                                .id("typingIndicator")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.chatHistory.count) { _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: viewModel.isTyping) { _ in
                    scrollToBottom(proxy)
                }
            }

            // Modern Message Input
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    HStack {
                        TextField("Ask about the docs...", text: $viewModel.currentQuery, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(1...5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .tertiarySystemBackground))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.1), lineWidth: 1))

                    Button(action: {
                        Task { await viewModel.askAI() }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(viewModel.currentQuery.isEmpty ? .secondary : Color.accentColor)
                    }
                    .disabled(viewModel.currentQuery.isEmpty)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }

    @ViewBuilder
    private func chatBubble(_ entry: ChatMessageEntry) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if entry.role == "user" { Spacer(minLength: 40) }

            if entry.role == "assistant" {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .padding(8)
                    .background(Color.accentColor.opacity(0.1), in: Circle())
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: entry.role == "user" ? .trailing : .leading, spacing: 4) {
                if entry.role == "user" {
                    Text(entry.content)
                        .font(.system(size: 15))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(18, corners: [.topLeft, .topRight, .bottomLeft])
                } else {
                    SDKMarkdownView(text: entry.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .tertiarySystemBackground))
                        .cornerRadius(18, corners: [.topLeft, .topRight, .bottomRight])
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                }
            }
            .id(entry.id)

            if entry.role == "assistant" { Spacer(minLength: 40) }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .padding(8)
                .background(Color.accentColor.opacity(0.1), in: Circle())
                .foregroundStyle(Color.accentColor)

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 6, height: 6)
                        .offset(y: viewModel.isTyping ? -3 : 0)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(index) * 0.2), value: viewModel.isTyping)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(18)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            if viewModel.isTyping {
                proxy.scrollTo("typingIndicator", anchor: .bottom)
            } else if let lastId = viewModel.chatHistory.last?.id {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

// Helper for selective corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
