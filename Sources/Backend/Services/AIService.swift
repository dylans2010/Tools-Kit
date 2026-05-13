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

    // MARK: - Public API

    @MainActor
    func processText(prompt: String, systemPrompt: String = "", model: String? = nil) async throws -> String {
        guard let provider = currentProvider else {
            throw AIError.unknownProvider(currentProviderID)
        }
        let authorization = try await featureCheck.authorizeRequest(providerID: currentProviderID)
        let apiKey = authorization.apiKey

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

        // Combine System Prompt, App Default System Prompt, and Active Skills
        let appSystemPrompt = settingsManager.settings.systemPrompt
        let activeSkills = SkillsManager.shared.activeSkillsPrompt()

        var finalSystemPrompt = "You are a helpful assistant."
        if !appSystemPrompt.isEmpty {
            finalSystemPrompt = appSystemPrompt
        }
        if !systemPrompt.isEmpty {
            finalSystemPrompt += "\n\nTask-specific instructions: \(systemPrompt)"
        }
        if !activeSkills.isEmpty {
            finalSystemPrompt += activeSkills
        }

        let messages = [
            ChatMessage(role: "system", content: finalSystemPrompt),
            ChatMessage(role: "user", content: prompt)
        ]

        return try await provider.send(messages: messages, model: modelToUse, apiKey: apiKey)
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
