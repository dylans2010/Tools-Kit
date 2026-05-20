import Foundation

enum AIError: Error {
    case missingAPIKey
    case networkError(String)
    case invalidResponse
    case unknownProvider(String)
}

class AIService {
    static let shared = AIService()

    private let registry = AIProviderRegistry.shared
    private let settingsManager = AIChatSettingsManager.shared
    @MainActor private let featureCheck = AIFeatureCheck.shared
    @MainActor private let modelCatalog = AIModelCatalog.shared

    // MARK: - Current provider helpers

    private var currentProviderID: String {
        settingsManager.settings.selectedProviderID
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

        func addSkill(name: String, content: String) {
            let skill = Skill(name: name, content: content)
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

    // MARK: - Public API

    @MainActor
    func processText(prompt: String, systemPrompt: String = "", model: String? = nil) async throws -> String {
        let finalSystemPrompt = await buildComprehensiveSystemPrompt(taskSpecific: systemPrompt)
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
        let authorization = try await featureCheck.authorizeRequest(providerID: currentProviderID)
        let apiKey = authorization.apiKey

        // Check if Dynamic Routing is enabled for OpenRouter
        if currentProviderID == "openrouter" && settingsManager.settings.dynamicRoutingEnabled {
            let router = DynamicAIModelRouting(provider: provider, apiKey: apiKey)
            return try await router.execute(messages: messages, attachments: attachments)
        }

        var modelToUse = model ?? settingsManager.settings.modelID
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

        if attachments.isEmpty {
            return try await provider.send(messages: messages, model: modelToUse, apiKey: apiKey)
        } else {
            return try await provider.sendWithAttachments(messages: messages, attachments: attachments, model: modelToUse, apiKey: apiKey)
        }
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
}

// MARK: - Dynamic AI Model Routing

/// A production-grade routing system for OpenRouter "free" tier models.
/// Implements resilient, fault-tolerant orchestration with automatic fallback and retry logic.
struct DynamicAIModelRouting {
    private let provider: any AIProvider
    private let apiKey: String
    private let modelCatalog = AIModelCatalog.shared

    init(provider: any AIProvider, apiKey: String) {
        self.provider = provider
        self.apiKey = apiKey
    }

    /// Executes the AI request across available free models until success or exhaustion.
    func execute(messages: [ChatMessage], attachments: [ChatAttachment] = []) async throws -> String {
        // 1. Ensure models are loaded for OpenRouter
        if await MainActor.run { modelCatalog.models(for: "openrouter").isEmpty } {
            await modelCatalog.loadModels(for: "openrouter")
        }

        // 2. Fetch and prioritize "free" models
        let freeModels = await MainActor.run {
            modelCatalog.models(for: "openrouter")
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
