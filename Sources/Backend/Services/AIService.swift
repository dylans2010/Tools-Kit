import Foundation

enum AIError: LocalizedError {
    case noProviderSelected
    case noModelSelected
    case deviceOffline
    case invalidEndpoint
    case requestFailed(String)
    case decodingFailed
    case missingAPIKey
    case networkError(String)
    case invalidResponse
    case unknownProvider(String)

    var errorDescription: String? {
        switch self {
        case .noProviderSelected:
            return "No AI provider has been selected. Please choose a provider in settings."
        case .noModelSelected:
            return "No AI model has been selected. Please choose a model in settings."
        case .deviceOffline:
            return "The selected device is offline. Ensure LM Studio or your local server is running."
        case .invalidEndpoint:
            return "The provider endpoint is invalid. Check your connection settings."
        case .requestFailed(let message):
            return "AI Request Failed: \(message)"
        case .decodingFailed:
            return "Failed to process the AI response. The format may be unexpected."
        case .missingAPIKey:
            return "Missing API Key for the selected provider."
        case .networkError(let message):
            return "Network Error: \(message)"
        case .invalidResponse:
            return "The server returned an invalid response."
        case .unknownProvider(let provider):
            return "Unknown AI provider: \(provider)"
        }
    }
}

enum AIProviderType: String, CaseIterable {
    case openRouter = "openrouter"
    case lmStudio = "lmstudio"
    case afm = "afm"
    case localModels = "local_models"
}

class AIService {
    static let shared = AIService()

    private let registry = AIProviderRegistry.shared
    private let settingsManager = AIChatSettingsManager.shared
    @MainActor private let featureCheck = AIFeatureCheck.shared
    @MainActor private let modelCatalog = AIModelCatalog.shared

    // MARK: - Current provider helpers

    private var currentProviderID: String {
        return settingsManager.settings.selectedProviderID
    }

    private var currentProvider: (any AIProvider)? {
        registry.provider(for: currentProviderID)
    }

    // MARK: - Skills Manager

    @MainActor
    class SkillsManager: ObservableObject {
        static let shared = SkillsManager()

        @Published var skills: [Skill] = []
        private let skillsDirectory: URL

        init() {
            let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            skillsDirectory = paths[0].appendingPathComponent("Skills", isDirectory: true)
            try? FileManager.default.createDirectory(at: skillsDirectory, withIntermediateDirectories: true)
            loadSkills()
        }

        func loadSkills() {
            guard let files = try? FileManager.default.contentsOfDirectory(at: skillsDirectory, includingPropertiesForKeys: nil) else { return }
            skills = files.compactMap { url in
                guard url.pathExtension == "json" else { return nil }
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(Skill.self, from: data)
            }.sorted(by: { $0.createdAt > $1.createdAt })
        }

        func addSkill(name: String, content: String, category: String = "General", version: String = "1.0.0", priority: Int = 1) {
            let skill = Skill(name: name, content: content, category: category, version: version, priority: priority)
            saveSkill(skill)
            loadSkills()
        }

        func updateSkill(_ skill: Skill) {
            saveSkill(skill)
            loadSkills()
        }

        func deleteSkill(_ skill: Skill) {
            let url = skillsDirectory.appendingPathComponent("\(skill.id.uuidString).json")
            try? FileManager.default.removeItem(at: url)
            loadSkills()
        }

        func importSkill(from url: URL) throws {
            let content = try String(contentsOf: url)
            let name = url.deletingPathExtension().lastPathComponent
            addSkill(name: name, content: content)
        }

        private func saveSkill(_ skill: Skill) {
            let url = skillsDirectory.appendingPathComponent("\(skill.id.uuidString).json")
            if let data = try? JSONEncoder().encode(skill) {
                try? data.write(to: url)
            }
        }

        func activeSkillsPrompt() -> String {
            let active = skills.filter { $0.isActive }
            guard !active.isEmpty else { return "" }

            var prompt = "\n\nAvailable User Skills:\n"
            for skill in active {
                prompt += "--- Skill: \(skill.name) ---\n\(skill.content)\n\n"
            }
            return prompt
        }
    }

    // MARK: - Prompt Builder Logic

    @MainActor
    func buildComprehensiveSystemPrompt(taskSpecific: String = "") async -> String {
        let s = settingsManager.settings
        var sections: [String] = []

        // 1. Core Identity & System Prompt
        let corePrompt = s.systemPrompt.isEmpty ? "You are a helpful assistant." : s.systemPrompt
        sections.append(corePrompt)

        // 2. Personality
        if s.useCustomPersonality {
            var personality = ""
            if !s.personalityName.isEmpty {
                personality += "Your name is \(s.personalityName). "
            }
            if !s.personalityTraits.isEmpty {
                personality += "Traits: \(s.personalityTraits.joined(separator: ", ")). "
            }
            if !personality.isEmpty {
                sections.append("### Personality\n\(personality)")
            }
        }

        // 3. Expertise
        if !s.expertiseAreas.isEmpty {
            sections.append("### Expertise\nAreas: \(s.expertiseAreas.joined(separator: ", "))")
        }

        // 4. Style & Tone
        var style = "Tone: \(s.responseTone.rawValue). Length: \(s.preferredResponseLength.rawValue)."
        if s.useMarkdown { style += " Use Markdown." }
        if s.includeCodeBlocks { style += " Use code blocks for code snippets." }
        if s.useBulletPoints { style += " Prefer bullet points for lists." }
        sections.append("### Style & Tone\n\(style)")

        // 5. Knowledge & Context (RAG)
        var knowledgeParts: [String] = []
        if !s.knowledgeContext.isEmpty {
            knowledgeParts.append(s.knowledgeContext)
        }

        if s.autoInjectContext {
            let insights = await AIContextEngine.shared.generateInsights()
            knowledgeParts.append(contentsOf: insights)
        }

        if !knowledgeParts.isEmpty {
            sections.append("### Knowledge Context\n\(knowledgeParts.joined(separator: "\n"))")
        }

        // 6. Memory
        if s.memoryEnabled {
            let memorySnippet = AIChatMemoryStore.shared.contextSnippet()
            if !memorySnippet.isEmpty {
                sections.append("### Long-term Memory\n\(memorySnippet)")
            }
        }

        // 7. Active Skills
        let skills = SkillsManager.shared.activeSkillsPrompt()
        if !skills.isEmpty {
            sections.append("### Active Skills\n\(skills)")
        }

        // 8. Output Constraints
        var constraints: [String] = []
        constraints.append("- Max paragraphs: \(s.maxParagraphs)")
        constraints.append("- Max sentences per paragraph: \(s.maxSentencesPerParagraph)")
        if s.avoidJargon { constraints.append("- Avoid technical jargon.") }
        if s.familyFriendlyOnly { constraints.append("- Family-friendly content only.") }
        if s.citeSources { constraints.append("- Cite sources when possible.") }
        if s.avoidOpinions { constraints.append("- Avoid stating personal opinions.") }
        sections.append("### Constraints\n\(constraints.joined(separator: "\n"))")

        // 9. Task Specific
        if !taskSpecific.isEmpty {
            sections.append("### Task-Specific Instructions\n\(taskSpecific)")
        }

        let finalPrompt = sections.joined(separator: "\n\n")
        return substituteVariables(in: finalPrompt)
    }

    private func substituteVariables(in text: String) -> String {
        var result = text
        let s = settingsManager.settings

        // Built-in Variables
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        result = result.replacingOccurrences(of: "{{date}}", with: formatter.string(from: now))

        formatter.dateStyle = .none
        formatter.timeStyle = .short
        result = result.replacingOccurrences(of: "{{time}}", with: formatter.string(from: now))

        result = result.replacingOccurrences(of: "{{user_name}}", with: NSFullUserName())
        result = result.replacingOccurrences(of: "{{app_version}}", with: "1.0.0")
        result = result.replacingOccurrences(of: "{{device_model}}", with: "iPhone")

        // Custom Variables
        for variable in s.promptVariables {
            result = result.replacingOccurrences(of: "{{\(variable.name)}}", with: variable.value)
        }

        return result
    }

    // MARK: - Validation Layer

    @MainActor
    private func validateRequest(providerID: String, modelID: String) async throws {
        SDKLogStore.shared.log("Validating AI Request - Provider: \(providerID), Model: \(modelID)", source: "AIService", level: .info)

        guard !providerID.isEmpty else { throw AIError.noProviderSelected }
        guard !modelID.isEmpty else { throw AIError.noModelSelected }

        if providerID == "lmstudio" {
            guard let device = LMConnectionManager.shared.selectedDevice else {
                throw AIError.deviceOffline
            }

            // Phase 10: Strict reachability check
            let url = URL(string: "\(device.baseURL)/v1/models")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 3.0

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw AIError.deviceOffline
                }
            } catch {
                throw AIError.deviceOffline
            }
        }

        if providerID == "afm" {
            let available = AFMModelManager.shared.availableModels
            if !available.contains(modelID) {
                throw AIError.requestFailed("Model \(modelID) is not available on this device.")
            }
        }
    }

    // MARK: - Public API

    @MainActor
    func processText(prompt: String, systemPrompt: String = "", model: String? = nil) async throws -> String {
        let finalSystemPrompt = await buildComprehensiveSystemPrompt(taskSpecific: systemPrompt)

        // Phase 10: Policy-driven routing
        let selectedProvider = settingsManager.settings.selectedProviderID
        let modelToUse = model ?? settingsManager.settings.modelID

        try await validateRequest(providerID: selectedProvider, modelID: modelToUse)

        switch selectedProvider {
        case "lmstudio":
            SDKLogStore.shared.log("Routing to LM Studio via LM Link", source: "AIService", level: .info)
            return try await LMConnectionManager.shared.sendChatRequest(prompt: prompt, systemPrompt: finalSystemPrompt)
        case "afm":
            SDKLogStore.shared.log("Routing to Apple Foundation Models", source: "AIService", level: .info)
            return try await AFMService.shared.generateResponse(prompt: prompt, systemPrompt: finalSystemPrompt)
        case "local_models":
            SDKLogStore.shared.log("Routing to Local Model (Manual)", source: "AIService", level: .info)
            // Fall through to processMessages for standardized manual local model handling
        default:
            break
        }

        let messages = [
            ChatMessage(role: "system", content: finalSystemPrompt),
            ChatMessage(role: "user", content: prompt)
        ]
        return try await processMessages(messages: messages, model: model)
    }

    @MainActor
    func processMessages(messages: [ChatMessage], attachments: [ChatAttachment] = [], model: String? = nil) async throws -> String {
        guard let provider = currentProvider else {
            throw AIError.unknownProvider(currentProviderID)
        }

        // Ensure we always pull the latest modelID from settings if not explicitly provided
        var modelToUse = model ?? settingsManager.settings.modelID

        try await validateRequest(providerID: currentProviderID, modelID: modelToUse)

        let authorization = try await featureCheck.authorizeRequest(providerID: currentProviderID)
        let apiKey = authorization.apiKey

        // Check if Dynamic Routing is enabled for OpenRouter
        if currentProviderID == "openrouter" && settingsManager.settings.dynamicRoutingEnabled {
            let router = DynamicAIModelRouting(provider: provider, apiKey: apiKey)
            return try await router.execute(messages: messages, attachments: attachments)
        }

        if modelToUse.isEmpty {
            await modelCatalog.loadModels(for: provider.id)
            let availableModels = await MainActor.run { modelCatalog.models(for: provider.id) }
            modelToUse = availableModels.first?.id ?? ""
            if modelToUse.isEmpty {
                throw AIError.invalidResponse
            }
            await MainActor.run {
                if settingsManager.settings.modelID.isEmpty {
                    settingsManager.settings.modelID = modelToUse
                }
            }
        }

        var response: String
        SDKLogStore.shared.log("AI Request: \(modelToUse) (Provider: \(provider.id))", source: "AIService", level: .info)

        do {
            if attachments.isEmpty {
                response = try await provider.send(messages: messages, model: modelToUse, apiKey: apiKey)
            } else if provider.supportsVision(model: modelToUse) {
                response = try await provider.sendWithAttachments(messages: messages, attachments: attachments, model: modelToUse, apiKey: apiKey)
            } else {
                // Model does not support vision — fall back to text descriptions for image attachments
                var fallbackMessages = messages
                var imageDescriptions: [String] = []
                for att in attachments {
                    if att.mimeType.hasPrefix("image/") {
                        imageDescriptions.append("[Attached image: \(att.fileName) (type: \(att.mimeType)) — vision not supported by current model, image cannot be displayed]")
                    }
                }
                if !imageDescriptions.isEmpty, !fallbackMessages.isEmpty {
                    let lastIdx = fallbackMessages.count - 1
                    let appendedContent = fallbackMessages[lastIdx].content + "\n\n" + imageDescriptions.joined(separator: "\n")
                    fallbackMessages[lastIdx] = ChatMessage(role: fallbackMessages[lastIdx].role, content: appendedContent)
                }
                response = try await provider.send(messages: fallbackMessages, model: modelToUse, apiKey: apiKey)
            }
            SDKLogStore.shared.log("AI Response Success: \(response)", source: "AIService", level: .info)
        } catch {
            SDKLogStore.shared.log("AI Error: \(error.localizedDescription)", source: "AIService", level: .error)
            throw error
        }

        // Handle tool calls in response (pattern [SEARCH: query])
        if response.contains("[SEARCH:"), let query = extractSearchQuery(from: response) {
            let searchResult = await performWebSearch(query: query)
            let toolResultMessage = ChatMessage(role: "system", content: "Search Result: \(searchResult)")

            // Continue conversation with search results, maintaining attachment context if it was a multi-modal request
            let updatedMessages = messages + [ChatMessage(role: "assistant", content: response), toolResultMessage]
            if attachments.isEmpty {
                return try await provider.send(messages: updatedMessages, model: modelToUse, apiKey: apiKey)
            } else {
                return try await provider.sendWithAttachments(messages: updatedMessages, attachments: attachments, model: modelToUse, apiKey: apiKey)
            }
        }

        // Handle MCP Tool Calls (pattern [MCP_CALL: ...])
        let mcpResults = await MCPExecutionEngine.shared.processAIResponse(response)

        if !mcpResults.isEmpty {
            var currentMessages = messages + [ChatMessage(role: "assistant", content: response)]

            for result in mcpResults {
                currentMessages.append(ChatMessage(role: "system", content: result.summary))
            }

            // Recurse to generate final response incorporating all tool outputs
            return try await processMessages(messages: currentMessages, attachments: attachments, model: modelToUse)
        }

        return response
    }

    private func extractSearchQuery(from text: String) -> String? {
        guard let startRange = text.range(of: "[SEARCH:") else { return nil }
        let remaining = text[startRange.upperBound...]
        guard let endRange = remaining.range(of: "]") else { return nil }
        return String(remaining[..<endRange.lowerBound]).trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Web Search Result Model

    struct WebSearchResult: Identifiable, Codable {
        let id: UUID
        let title: String
        let snippet: String
        let url: String
        let source: String
        let timestamp: Date

        init(title: String, snippet: String, url: String, source: String) {
            self.id = UUID()
            self.title = title
            self.snippet = snippet
            self.url = url
            self.source = source
            self.timestamp = Date()
        }
    }

    struct WebSearchResponse {
        let query: String
        let results: [WebSearchResult]
        let summary: String
        let rawText: String
    }

    func performWebSearch(query: String) async -> String {
        let response = await performFullWebSearch(query: query)
        return response.rawText
    }

    func performFullWebSearch(query: String) async -> WebSearchResponse {
        let googleKey = APIKeyManager.shared.getKey(for: "google-search")
        let cx = APIKeyManager.shared.getKey(for: "google-search-cx")

        var results: [WebSearchResult] = []
        var rawText = ""

        if let key = googleKey, let cx = cx {
            do {
                let (googleResults, googleRaw) = try await performGoogleSearchStructured(query: query, apiKey: key, cx: cx)
                results = googleResults
                rawText = googleRaw
            } catch {
                let (ddgResults, ddgRaw) = await performDuckDuckGoSearchStructured(query: query)
                results = ddgResults
                rawText = ddgRaw
            }
        } else {
            let (ddgResults, ddgRaw) = await performDuckDuckGoSearchStructured(query: query)
            results = ddgResults
            rawText = ddgRaw
        }

        if results.isEmpty {
            let (braveResults, braveRaw) = await performBraveHTMLSearch(query: query)
            if !braveResults.isEmpty {
                results = braveResults
                rawText = braveRaw
            }
        }

        // Fetch and append page content for top results
        var enrichedText = rawText
        for result in results.prefix(3) {
            let content = await fetchPageContent(urlString: result.url)
            if !content.isEmpty {
                enrichedText += "\n\n--- Content from: \(result.title) (\(result.url)) ---\n\(content)\n--- End ---\n"
            }
        }

        return WebSearchResponse(
            query: query,
            results: results,
            summary: enrichedText,
            rawText: enrichedText
        )
    }

    private func fetchPageContent(urlString: String) async -> String {
        guard let url = URL(string: urlString) else { return "" }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return "" }
            guard let html = String(data: data, encoding: .utf8) else { return "" }
            return extractTextFromHTML(html)
        } catch {
            return ""
        }
    }

    private func extractTextFromHTML(_ html: String) -> String {
        var text = html
        // Remove script and style blocks
        let patterns = ["<script[^>]*>[\\s\\S]*?</script>", "<style[^>]*>[\\s\\S]*?</style>", "<nav[^>]*>[\\s\\S]*?</nav>", "<footer[^>]*>[\\s\\S]*?</footer>", "<header[^>]*>[\\s\\S]*?</header>"]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
            }
        }
        // Remove remaining HTML tags
        if let tagRegex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) {
            text = tagRegex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: " ")
        }
        // Decode HTML entities
        text = text.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        // Collapse whitespace
        if let wsRegex = try? NSRegularExpression(pattern: "\\s+", options: []) {
            text = wsRegex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: " ")
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Limit to ~2000 chars
        if trimmed.count > 2000 {
            return String(trimmed.prefix(2000)) + "..."
        }
        return trimmed
    }

    private func performBraveHTMLSearch(query: String) async -> ([WebSearchResult], String) {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://search.brave.com/search?q=\(encodedQuery)&source=web"
        guard let url = URL(string: urlString) else { return ([], "") }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return ([], "") }
            guard let html = String(data: data, encoding: .utf8) else { return ([], "") }
            return parseBraveResults(html, query: query)
        } catch {
            return ([], "")
        }
    }

    private func parseBraveResults(_ html: String, query: String) -> ([WebSearchResult], String) {
        var results: [WebSearchResult] = []
        var rawText = ""

        // Extract snippets using common Brave result patterns
        let snippetPattern = "<div class=\"snippet-description[^\"]*\"[^>]*>([^<]+)</div>"
        let titlePattern = "<a class=\"result-header[^\"]*\"[^>]*href=\"([^\"]+)\"[^>]*>.*?<span class=\"snippet-title\">([^<]+)</span>"

        if let snippetRegex = try? NSRegularExpression(pattern: snippetPattern, options: .caseInsensitive) {
            let matches = snippetRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            for match in matches.prefix(5) {
                if let range = Range(match.range(at: 1), in: html) {
                    let snippet = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !snippet.isEmpty {
                        results.append(WebSearchResult(title: "Result", snippet: snippet, url: "", source: "Brave"))
                    }
                }
            }
        }

        if let titleRegex = try? NSRegularExpression(pattern: titlePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = titleRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            for (i, match) in matches.prefix(5).enumerated() {
                if let urlRange = Range(match.range(at: 1), in: html),
                   let titleRange = Range(match.range(at: 2), in: html) {
                    let url = String(html[urlRange])
                    let title = String(html[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if i < results.count {
                        results[i] = WebSearchResult(title: title, snippet: results[i].snippet, url: url, source: "Brave")
                    } else {
                        results.append(WebSearchResult(title: title, snippet: "", url: url, source: "Brave"))
                    }
                }
            }
        }

        // Build raw text
        for (index, result) in results.enumerated() {
            rawText += "\(index + 1). \(result.title)\n\(result.snippet)\nURL: \(result.url)\n\n"
        }

        return (results, rawText.isEmpty ? "No search results found for '\(query)'." : rawText)
    }

    private func performDuckDuckGoSearchStructured(query: String) async -> ([WebSearchResult], String) {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://api.duckduckgo.com/?q=\(encodedQuery)&format=json"
        guard let url = URL(string: urlString) else { return ([], "Invalid Search URL") }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return ([], "Search error: Status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return ([], "Search error: Unable to parse JSON response")
            }
            return formatDuckDuckGoResultsStructured(json, query: query)
        } catch {
            return ([], "Search error: \(error.localizedDescription)")
        }
    }

    private func formatDuckDuckGoResultsStructured(_ json: [String: Any], query: String) -> ([WebSearchResult], String) {
        var results: [WebSearchResult] = []
        var rawText = ""

        if let abstract = json["AbstractText"] as? String, !abstract.isEmpty {
            let source = json["AbstractSource"] as? String ?? "Source"
            let url = json["AbstractURL"] as? String ?? ""
            results.append(WebSearchResult(title: source, snippet: abstract, url: url, source: "DuckDuckGo"))
            rawText += "Abstract (\(source)):\n\(abstract)\nURL: \(url)\n\n"
        }

        if let topics = json["RelatedTopics"] as? [[String: Any]] {
            let extracted = extractTopicsStructured(topics)
            results.append(contentsOf: extracted.results)
            rawText += extracted.text
        }

        if let directResults = json["Results"] as? [[String: Any]] {
            for res in directResults {
                guard results.count < 8 else { break }
                if let text = res["Text"] as? String, let url = res["FirstURL"] as? String {
                    results.append(WebSearchResult(title: text.components(separatedBy: " - ").first ?? text, snippet: text, url: url, source: "DuckDuckGo"))
                    rawText += "\(results.count). \(text)\nURL: \(url)\n\n"
                }
            }
        }

        if results.isEmpty {
            return ([], "No search results found for '\(query)'.")
        }
        return (results, rawText)
    }

    private func extractTopicsStructured(_ topics: [[String: Any]]) -> (results: [WebSearchResult], text: String) {
        var results: [WebSearchResult] = []
        var text = ""

        for topic in topics {
            guard results.count < 8 else { break }
            if let nestedTopics = topic["Topics"] as? [[String: Any]] {
                let nested = extractTopicsStructured(nestedTopics)
                results.append(contentsOf: nested.results)
                text += nested.text
            } else if let topicText = topic["Text"] as? String, let url = topic["FirstURL"] as? String {
                let parts = topicText.components(separatedBy: " - ")
                let title = parts.first ?? "Result"
                let snippet = parts.count > 1 ? parts[1] : ""
                results.append(WebSearchResult(title: title, snippet: snippet, url: url, source: "DuckDuckGo"))
                text += "\(results.count). \(title)\n\(snippet)\nURL: \(url)\n\n"
            }
        }

        return (results, text)
    }

    private func performGoogleSearchStructured(query: String, apiKey: String, cx: String) async throws -> ([WebSearchResult], String) {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://www.googleapis.com/customsearch/v1?q=\(encodedQuery)&key=\(apiKey)&cx=\(cx)&num=5"
        guard let url = URL(string: urlString) else { throw AIError.networkError("Invalid Search URL") }

        let request = URLRequest(url: url)
        let (data, response): (Data, URLResponse) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AIError.networkError("Search API returned status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        let json: [String: Any] = (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        guard let items = json["items"] as? [[String: Any]] else {
            return ([], "No results found for '\(query)'.")
        }

        var results: [WebSearchResult] = []
        var rawText = ""
        for (index, item) in items.prefix(5).enumerated() {
            let title = item["title"] as? String ?? "No Title"
            let snippet = item["snippet"] as? String ?? "No Snippet"
            let link = item["link"] as? String ?? ""
            results.append(WebSearchResult(title: title, snippet: snippet, url: link, source: "Google"))
            rawText += "\(index + 1). \(title)\n\(snippet)\nURL: \(link)\n\n"
        }

        return (results, rawText.isEmpty ? "No search results available." : rawText)
    }

    func summarize(text: String) async throws -> String {
        let prompt = "Summarize the following text, providing key points and action items:\n\n\(text)"
        return try await processText(prompt: prompt)
    }

    func summarizeEmail(text: String) async throws -> String {
        let prompt = """
        You are a fine-tuned executive email analyst.
        Summarize this email in markdown with sections:
        ## TL;DR
        ## Key Points
        ## Action Items
        Keep it concise and practical.

        Email:
        \(text)
        """
        return try await processText(prompt: prompt, systemPrompt: "You are an expert email copilot that writes clear markdown.")
    }

    func extractEmailActionItems(text: String) async throws -> String {
        let prompt = """
        Extract action items from this email.
        Return markdown checklist bullets with owner and due date when available.
        If none, say \"- [ ] No explicit action items found.\"

        Email:
        \(text)
        """
        return try await processText(prompt: prompt, systemPrompt: "You identify commitments, follow-ups, and deadlines in email.")
    }

    func assessEmailTone(text: String) async throws -> String {
        let prompt = """
        Analyze the tone of this email.
        Return markdown with:
        - Overall tone
        - Urgency (Low/Medium/High)
        - Suggested reply style
        - Risk flags (if any)

        Email:
        \(text)
        """
        return try await processText(prompt: prompt, systemPrompt: "You are a communications analyst.")
    }

    func draftReply(to text: String, from sender: String, subject: String) async throws -> String {
        let prompt = """
        Draft a polished reply to this email.
        Output markdown with:
        - Suggested subject line
        - Draft body
        - Optional alternate shorter version

        Context:
        Sender: \(sender)
        Subject: \(subject)
        Email body:
        \(text)
        """
        return try await processText(prompt: prompt, systemPrompt: "You are an expert executive assistant who writes concise, professional email replies.")
    }

    func debugCode(code: String) async throws -> String {
        let prompt = "Analyze the following code for bugs, logic errors, and optimization opportunities. Return structured suggestions:\n\n\(code)"
        return try await processText(prompt: prompt, systemPrompt: "You are an expert software engineer.")
    }

    func generateReminders(topic: String) async throws -> String {
        let prompt = "Generate a list of reminders for: \(topic). Extract intent, date, time, and priority where possible."
        return try await processText(prompt: prompt)
    }

    func autofill(context: String, field: String) async throws -> String {
        let prompt = "Based on the context: \"\(context)\", what should be the value for the field: \"\(field)\"?"
        return try await processText(prompt: prompt)
    }

    func generateResponse(prompt: String) async throws -> String {
        return try await processText(prompt: prompt)
    }


    @MainActor
    func generateStructuredJSON(
        prompt: String,
        jsonSchema: String,
        preferredModel: String? = nil,
        systemPrompt: String = "You are a precise assistant that returns valid JSON only."
    ) async throws -> String {
        let decoratedPrompt = """
        Return ONLY JSON that strictly follows this schema:
        \(jsonSchema)

        User task:
        \(prompt)
        """

        let response = try await processText(
            prompt: decoratedPrompt,
            systemPrompt: systemPrompt,
            model: preferredModel
        )
        return normalizeJSONObject(from: response)
    }

    @MainActor
    func processWithOpenRouter(
        prompt: String,
        modelID: String,
        responseSchema: String? = nil
    ) async throws -> String {
        let authorization = try await featureCheck.authorizeRequest(providerID: "openrouter")
        let apiKey = authorization.apiKey

        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var payload: [String: Any] = [
            "model": modelID,
            "messages": [
                ["role": "system", "content": "Return clear, safe answers. If schema is supplied, output JSON only."],
                ["role": "user", "content": prompt]
            ]
        ]

        if let responseSchema {
            payload["response_format"] = [
                "type": "json_schema",
                "json_schema": [
                    "name": "strict_response",
                    "strict": true,
                    "schema": (try? JSONSerialization.jsonObject(with: Data(responseSchema.utf8))) ?? [:]
                ]
            ]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown OpenRouter error"
            throw AIError.networkError(message)
        }

        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = root["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw AIError.invalidResponse
        }

        return normalizeJSONObject(from: content)
    }

    private func normalizeJSONObject(from response: String) -> String {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```") {
            let cleaned = trimmed
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned
        }
        return trimmed
    }

    // MARK: - Designer Module Helpers

    @MainActor
    func generateDesignMarkdown(title: String, colors: [String], fonts: [String], radii: [String]) async -> String {
        let systemPrompt = """
        You are the 'Ultimate Designer AI'. Your task is to generate a comprehensive, professional, and intuitive 'DESIGN.md' file based on extracted design tokens.

        This file is NOT just a list; it is a 'Design Persona' training document. It should describe the 'soul' of the design so that another AI model, upon reading this file, can perfectly replicate the brand's aesthetic, tone, and UI behavior.

        Guidelines for the DESIGN.md:
        1. **Executive Summary**: Describe the overall vibe (e.g., "Minimalist high-tech", "Warm organic", "Corporate brutalist").
        2. **Color Palette**: Categorize the colors (Primary, Secondary, Surface, Accents). Explain their semantic purpose.
        3. **Typography**: Analyze the font choices and suggest a hierarchy (Headings, Body, Captions).
        4. **Shape & Form**: Describe the use of corner radii and spacing (e.g., "Soft pill-shaped buttons", "Sharp aggressive edges").
        5. **Persona Training Section**: Write a specific block titled 'AI Styling Instructions' that a user can paste into an AI to 'train' it on this specific style.

        Output ONLY the Markdown content.
        """

        let prompt = """
        Generate a Designer.md file for a project titled '\(title)'.

        Extracted Tokens:
        - Colors: \(colors.joined(separator: ", "))
        - Fonts: \(fonts.joined(separator: ", "))
        - Corner Radii: \(radii.joined(separator: ", "))

        Make it beautiful, technical, and ready for AI persona training.
        """

        do {
            return try await processText(prompt: prompt, systemPrompt: systemPrompt)
        } catch {
            // Fallback to basic markdown if AI fails
            var markdown = "# \(title) (Basic Export)\n\n"
            markdown += "## Colors\n" + colors.map { "* \($0)" }.joined(separator: "\n") + "\n\n"
            markdown += "## Fonts\n" + fonts.map { "* \($0)" }.joined(separator: "\n") + "\n\n"
            markdown += "## Radii\n" + radii.map { "* \($0)" }.joined(separator: "\n") + "\n"
            return markdown
        }
    }

    func saveDesignDocument(content: String) {
        let fileName = "Design.md"
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsURL.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Successfully saved design document to \(fileURL.path)")
        } catch {
            print("Failed to save design document: \(error)")
        }
    }
}

// MARK: - Dynamic AI Model Routing

/// A production-grade routing system for OpenRouter "free" tier models.
/// Implements resilient, fault-tolerant orchestration with automatic fallback and retry logic.
struct DynamicAIModelRouting {
    private let provider: any AIProvider
    private let apiKey: String

    init(provider: any AIProvider, apiKey: String) {
        self.provider = provider
        self.apiKey = apiKey
    }

    /// Executes the AI request across available free models until success or exhaustion.
    func execute(messages: [ChatMessage], attachments: [ChatAttachment] = []) async throws -> String {
        // 1. Ensure models are loaded for OpenRouter
        if await MainActor.run { AIModelCatalog.shared.models(for: "openrouter").isEmpty } {
            await AIModelCatalog.shared.loadModels(for: "openrouter")
        }

        // 2. Fetch and prioritize "free" models
        let freeModels = await MainActor.run {
            AIModelCatalog.shared.models(for: "openrouter")
                .filter { $0.id.lowercased().contains("free") }
                .sorted { m1, m2 in
                    // Prioritize newer/larger models if known, otherwise alphabetic
                    if m1.id.contains("gemini-2.0") && !m2.id.contains("gemini-2.0") { return true }
                    if !m1.id.contains("gemini-2.0") && m2.id.contains("gemini-2.0") { return false }
                    return m1.id < m2.id
                }
        }

        guard !freeModels.isEmpty else {
            throw AIError.networkError("No free OpenRouter models available for dynamic routing.")
        }

        var lastError: Error?

        // 3. Iterate through eligible models with retry logic
        for model in freeModels {
            // Support for Task cancellation
            try Task.checkCancellation()

            // Skip if vision is required but not supported by this specific model
            if !attachments.isEmpty && !provider.supportsVision(model: model.id) {
                continue
            }

            do {
                // Attempt request
                if attachments.isEmpty {
                    return try await provider.send(messages: messages, model: model.id, apiKey: apiKey)
                } else {
                    return try await provider.sendWithAttachments(messages: messages, attachments: attachments, model: model.id, apiKey: apiKey)
                }
            } catch {
                // Store error and continue to the next model in the fallback chain
                lastError = error
                // In production, we might log this internally for telemetry
                continue
            }
        }

        // 4. Exhausted all options
        throw AIError.networkError("All available free models exhausted. Last error: \(lastError?.localizedDescription ?? "Unknown")")
    }
}
