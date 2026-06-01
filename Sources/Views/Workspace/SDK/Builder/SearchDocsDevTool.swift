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

        let patterns: [(DocElement.ElementType, String)] = [
            (.heading1, "<h1[^>]*>(.*?)</h1>"),
            (.heading2, "<h2[^>]*>(.*?)</h2>"),
            (.heading3, "<h3[^>]*>(.*?)</h3>"),
            (.code, "<pre[^>]*><code[^>]*>([\\s\\S]*?)</code></pre>"),
            (.paragraph, "<p[^>]*>(.*?)</p>"),
            (.list, "<li[^>]*>(.*?)</li>")
        ]

        var currentIndex = html.startIndex

        while currentIndex < html.endIndex {
            var earliestMatch: (DocElement.ElementType, NSTextCheckingResult)?

            for (type, pattern) in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                    let range = NSRange(currentIndex..., in: html)
                    if let match = regex.firstMatch(in: html, options: [], range: range) {
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
                if let contentRange = Range(match.range(at: 1), in: html) {
                    let rawContent = String(html[contentRange])
                    let cleanContent = Self.cleanTags(rawContent)
                    if !cleanContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        parsed.append(DocElement(type: type, content: cleanContent))
                    }
                }

                // Safe index advancement using Range(NSRange, in: String)
                if let matchRange = Range(match.range, in: html) {
                    currentIndex = matchRange.upperBound
                } else {
                    // Fallback to avoid infinite loop
                    currentIndex = html.index(after: currentIndex)
                }
            } else {
                break
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
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.chatHistory) { entry in
                            HStack {
                                if entry.role == "user" { Spacer(minLength: 40) }

                                Text(entry.content)
                                    .font(.system(size: 14))
                                    .padding(10)
                                    .background(
                                        entry.role == "user"
                                        ? Color.accentColor
                                        : Color(uiColor: .tertiarySystemBackground)
                                    )
                                    .foregroundStyle(entry.role == "user" ? .white : .primary)
                                    .cornerRadius(12)
                                    .textSelection(.enabled)

                                if entry.role == "assistant" { Spacer(minLength: 40) }
                            }
                            .id(entry.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.chatHistory.count) { _ in
                    if let lastId = viewModel.chatHistory.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Ask about the docs...", text: $viewModel.currentQuery)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(uiColor: .tertiarySystemBackground))
                    .cornerRadius(8)

                Button(action: {
                    Task { await viewModel.askAI() }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(viewModel.currentQuery.isEmpty ? .secondary : Color.accentColor)
                }
                .disabled(viewModel.currentQuery.isEmpty)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
        }
    }
}
