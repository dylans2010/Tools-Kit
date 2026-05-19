import Foundation
import SwiftUI

// MARK: - Core Types

enum MarkdownNode: String, CaseIterable, Codable {
    case bold, italic, heading1, heading2, heading3
    case unorderedList, orderedList, blockquote, inlineCode
}

struct MailAIOutputSchema {
    let allowedMarkdownNodes: Set<MarkdownNode>
    let forbiddenPatterns: [String]
    let requiredFields: [String]?
    let placeholderFormat: String
    let maxOutputTokens: Int

    static let defaultForbiddenPatterns = [
        "\\[\\]",
        "\\{\\}",
        "\\{\\{[^}]*\\}\\}",
        "^\\s*(Sure|Of course|Certainly|Great|Absolutely)[!,.]",
        "(Let me know|Feel free|Hope this helps)"
    ]
}

enum MailAIResponseFormat {
    case plainText
    case markdown
    case structured(fields: [String])
}

protocol MailAITool {
    var toolID: String { get }
    var displayName: String { get }
    var systemPrompt: String { get }
    var outputSchema: MailAIOutputSchema { get }
    var supportsStreaming: Bool { get }
    var responseFormat: MailAIResponseFormat { get }
}

// MARK: - Shared Prompts

private enum SharedPrompts {
    static let identity = """
    [IDENTITY]
    You are an expert email writing assistant embedded inside a professional iOS mail client. You specialize in crafting high-impact, professional, and clear communications for business and personal contexts.
    """

    static let constraints = """
    [CONSTRAINTS — CRITICAL]
    - NEVER hallucinate facts, names, dates, company names, or figures not present in the user's input. Use <<PLACEHOLDER: description>> for missing information.
    - NEVER produce stray symbols such as [], {{}}, ##, ***, ---, or markdown fence markers (``` or ~~~) unless semantically required.
    - NEVER begin with a preamble, greeting, or explanation. Start directly with the output.
    - NEVER end with a sign-off, meta-comment, or phrases like "Let me know if you need changes."
    - If input is insufficient, respond with ONLY: {"error": "insufficient_input", "missing": ["<field>"]}
    """

    static let toneControl = """
    [TONE CONTROL]
    - Respect the tone specified in the user prompt. Supported tones: Formal, Friendly, Assertive, Concise, Diplomatic, Professional, Executive, Persuasive.
    - If no tone is specified, default to professional yet conversational.
    - Maintain consistency throughout the entire output. Do not shift register mid-text.
    """

    static let formatting = """
    [FORMATTING]
    - Preserve line breaks: every paragraph must be separated by a double newline (\\n\\n).
    - Keep greeting and sign-off on their own lines separated by blank lines.
    - Ensure proper paragraph spacing for email readability.
    - Output must be email-ready: clear, concise, and properly spaced.
    """

    static let markdownContract = """
    [MARKDOWN RENDERING CONTRACT]
    Allowed subset: **bold**, *italic*, # ## ### headings, - unordered lists, 1. ordered lists, > blockquotes, `inline code`. No tables, HTML tags, or extended markdown syntax. Every heading must be followed by a blank line.
    """
}

// MARK: - Concrete Tools

struct EmailDraftingTool: MailAITool {
    let toolID = "email_drafting"
    let displayName = "Email Drafting"
    let supportsStreaming = true
    let responseFormat: MailAIResponseFormat = .markdown

    let outputSchema = MailAIOutputSchema(
        allowedMarkdownNodes: Set(MarkdownNode.allCases),
        forbiddenPatterns: MailAIOutputSchema.defaultForbiddenPatterns,
        requiredFields: nil,
        placeholderFormat: "<<PLACEHOLDER: %@>>",
        maxOutputTokens: 1000
    )

    var systemPrompt: String {
        """
        \(SharedPrompts.identity)

        [TASK]
        Compose a full, professionally structured email based on a provided topic or intent.

        \(SharedPrompts.constraints)
        \(SharedPrompts.toneControl)
        \(SharedPrompts.formatting)

        [OUTPUT FORMAT]
        Produce a high-quality markdown response. Start with "Subject: " followed by a compelling subject line. Then two newlines, followed by the body of the email.

        \(SharedPrompts.markdownContract)
        """
    }
}

struct EmailRewriteTool: MailAITool {
    let toolID = "email_rewrite"
    let displayName = "Email Rewrite"
    let supportsStreaming = true
    let responseFormat: MailAIResponseFormat = .markdown

    let outputSchema = MailAIOutputSchema(
        allowedMarkdownNodes: Set(MarkdownNode.allCases),
        forbiddenPatterns: MailAIOutputSchema.defaultForbiddenPatterns,
        requiredFields: nil,
        placeholderFormat: "<<PLACEHOLDER: %@>>",
        maxOutputTokens: 1000
    )

    var systemPrompt: String {
        """
        \(SharedPrompts.identity)

        [TASK]
        Rewrite an existing email draft to improve clarity, flow, and impact based on user-selected tone or length options.

        \(SharedPrompts.constraints)
        \(SharedPrompts.toneControl)
        \(SharedPrompts.formatting)

        [OUTPUT FORMAT]
        Return the rewritten email body as markdown. Do not include a subject line unless specifically asked.

        \(SharedPrompts.markdownContract)
        """
    }
}

struct EmailTranslationTool: MailAITool {
    let toolID = "email_translation"
    let displayName = "Email Translation"
    let supportsStreaming = false
    let responseFormat: MailAIResponseFormat = .structured(fields: ["subject", "body"])

    let outputSchema = MailAIOutputSchema(
        allowedMarkdownNodes: Set(MarkdownNode.allCases),
        forbiddenPatterns: MailAIOutputSchema.defaultForbiddenPatterns,
        requiredFields: ["subject", "body"],
        placeholderFormat: "<<PLACEHOLDER: %@>>",
        maxOutputTokens: 1500
    )

    var systemPrompt: String {
        """
        \(SharedPrompts.identity)

        [TASK]
        Translate both the email subject and body into the target language while preserving intent, nuance, and formatting.

        \(SharedPrompts.constraints)
        \(SharedPrompts.toneControl)
        \(SharedPrompts.formatting)

        [OUTPUT FORMAT]
        Return a valid JSON object with the following keys:
        - "subject": The translated subject line as plain text.
        - "body": The translated body as markdown. Preserve line breaks from the original.

        \(SharedPrompts.markdownContract)
        """
    }
}

struct SubjectLineTool: MailAITool {
    let toolID = "subject_line"
    let displayName = "Subject Line Generator"
    let supportsStreaming = true
    let responseFormat: MailAIResponseFormat = .markdown

    let outputSchema = MailAIOutputSchema(
        allowedMarkdownNodes: [.bold, .italic],
        forbiddenPatterns: MailAIOutputSchema.defaultForbiddenPatterns,
        requiredFields: nil,
        placeholderFormat: "<<PLACEHOLDER: %@>>",
        maxOutputTokens: 200
    )

    var systemPrompt: String {
        """
        \(SharedPrompts.identity)

        [TASK]
        Generate 3 to 5 professional, high-open-rate subject line options based on the provided email content.

        \(SharedPrompts.constraints)

        [OUTPUT FORMAT]
        Provide a bulleted list of options. Do not include any other text.

        [TONE & REGISTER]
        Options should range from direct and informative to slightly more creative or urgent, all while remaining professional.

        \(SharedPrompts.markdownContract)
        """
    }
}

struct ToneShiftTool: MailAITool {
    let toolID = "tone_shift"
    let displayName = "Tone Shift"
    let supportsStreaming = true
    let responseFormat: MailAIResponseFormat = .markdown

    let outputSchema = MailAIOutputSchema(
        allowedMarkdownNodes: Set(MarkdownNode.allCases),
        forbiddenPatterns: MailAIOutputSchema.defaultForbiddenPatterns,
        requiredFields: nil,
        placeholderFormat: "<<PLACEHOLDER: %@>>",
        maxOutputTokens: 1000
    )

    var systemPrompt: String {
        """
        \(SharedPrompts.identity)

        [TASK]
        Transform the tone of the provided text into the requested tone: formal, friendly, assertive, concise, or diplomatic.

        \(SharedPrompts.constraints)
        \(SharedPrompts.toneControl)
        \(SharedPrompts.formatting)

        [OUTPUT FORMAT]
        Return the adjusted text as markdown. Preserve paragraph structure and line breaks.

        \(SharedPrompts.markdownContract)
        """
    }
}

struct SummarizeTool: MailAITool {
    let toolID = "email_summarize"
    let displayName = "Email Summarizer"
    let supportsStreaming = true
    let responseFormat: MailAIResponseFormat = .markdown

    let outputSchema = MailAIOutputSchema(
        allowedMarkdownNodes: [.bold, .italic, .unorderedList, .heading3],
        forbiddenPatterns: MailAIOutputSchema.defaultForbiddenPatterns,
        requiredFields: nil,
        placeholderFormat: "<<PLACEHOLDER: %@>>",
        maxOutputTokens: 500
    )

    var systemPrompt: String {
        """
        \(SharedPrompts.identity)

        [TASK]
        Summarize a long email or thread into clear, digestible bullet points.

        \(SharedPrompts.constraints)

        [OUTPUT FORMAT]
        Use markdown headings for "Summary" and "Key Action Items." Use bullet points for content. Separate sections with blank lines.

        [TONE & REGISTER]
        Objective, brief, and highly functional for an executive reader.

        \(SharedPrompts.markdownContract)
        """
    }
}

struct ReplyDraftTool: MailAITool {
    let toolID = "reply_draft"
    let displayName = "Reply Assistant"
    let supportsStreaming = true
    let responseFormat: MailAIResponseFormat = .markdown

    let outputSchema = MailAIOutputSchema(
        allowedMarkdownNodes: Set(MarkdownNode.allCases),
        forbiddenPatterns: MailAIOutputSchema.defaultForbiddenPatterns,
        requiredFields: nil,
        placeholderFormat: "<<PLACEHOLDER: %@>>",
        maxOutputTokens: 800
    )

    var systemPrompt: String {
        """
        \(SharedPrompts.identity)

        [TASK]
        Draft a contextual reply to a provided email.

        \(SharedPrompts.constraints)
        \(SharedPrompts.toneControl)
        \(SharedPrompts.formatting)

        [OUTPUT FORMAT]
        Return the reply body as markdown. Directly address points raised in the original message.

        \(SharedPrompts.markdownContract)
        """
    }
}

struct FollowUpTool: MailAITool {
    let toolID = "follow_up"
    let displayName = "Follow-Up Generator"
    let supportsStreaming = true
    let responseFormat: MailAIResponseFormat = .markdown

    let outputSchema = MailAIOutputSchema(
        allowedMarkdownNodes: Set(MarkdownNode.allCases),
        forbiddenPatterns: MailAIOutputSchema.defaultForbiddenPatterns,
        requiredFields: nil,
        placeholderFormat: "<<PLACEHOLDER: %@>>",
        maxOutputTokens: 500
    )

    var systemPrompt: String {
        """
        \(SharedPrompts.identity)

        [TASK]
        Generate a polite and effective follow-up for an unanswered email.

        \(SharedPrompts.constraints)
        \(SharedPrompts.toneControl)
        \(SharedPrompts.formatting)

        [OUTPUT FORMAT]
        Return the follow-up email body as markdown. Preserve paragraph spacing.

        [TONE & REGISTER]
        Gentle and non-accusatory. Provide a helpful nudge while offering the recipient a way to easily respond.

        \(SharedPrompts.markdownContract)
        """
    }
}

struct ProofreadTool: MailAITool {
    let toolID = "proofread"
    let displayName = "AI Proofreader"
    let supportsStreaming = true
    let responseFormat: MailAIResponseFormat = .markdown

    let outputSchema = MailAIOutputSchema(
        allowedMarkdownNodes: Set(MarkdownNode.allCases),
        forbiddenPatterns: [
            "\\[\\]",
            "\\{\\}",
            "\\{\\{[^}]*\\}\\}",
            "^\\s*(Sure|Of course|Certainly|Great|Absolutely)[!,.]",
            "(Let me know|Feel free|Hope this helps)"
        ], // Allowed code fences here for diff display if needed
        requiredFields: nil,
        placeholderFormat: "<<PLACEHOLDER: %@>>",
        maxOutputTokens: 1500
    )

    var systemPrompt: String {
        """
        \(SharedPrompts.identity)

        [TASK]
        Fix grammar, spelling, punctuation, and slight phrasing issues in the provided text. Return a polished version ready for final use.

        \(SharedPrompts.constraints)
        \(SharedPrompts.formatting)

        [OUTPUT FORMAT]
        Return ONLY the corrected version. Do not provide a list of changes or explanations. Preserve the original paragraph structure and line breaks.

        [TONE & REGISTER]
        Preserve the author's original tone and voice exactly, only correcting errors and clear awkwardness.

        \(SharedPrompts.markdownContract)
        """
    }
}

struct BulletToEmailTool: MailAITool {
    let toolID = "bullet_to_email"
    let displayName = "Bullet-to-Email"
    let supportsStreaming = true
    let responseFormat: MailAIResponseFormat = .markdown

    let outputSchema = MailAIOutputSchema(
        allowedMarkdownNodes: Set(MarkdownNode.allCases),
        forbiddenPatterns: MailAIOutputSchema.defaultForbiddenPatterns,
        requiredFields: nil,
        placeholderFormat: "<<PLACEHOLDER: %@>>",
        maxOutputTokens: 1000
    )

    var systemPrompt: String {
        """
        \(SharedPrompts.identity)

        [TASK]
        Expand a provided list of bullet points into a full, professional email with appropriate transitions and structure.

        \(SharedPrompts.constraints)
        \(SharedPrompts.toneControl)
        \(SharedPrompts.formatting)

        [OUTPUT FORMAT]
        Return the full email as markdown. Ensure proper paragraph spacing and line breaks.

        \(SharedPrompts.markdownContract)
        """
    }
}

// MARK: - Registry

final class MailAIToolRegistry {
    static let shared = MailAIToolRegistry()
    private init() {}

    private let tools: [String: any MailAITool] = [
        EmailDraftingTool().toolID:    EmailDraftingTool(),
        EmailRewriteTool().toolID:     EmailRewriteTool(),
        EmailTranslationTool().toolID: EmailTranslationTool(),
        SubjectLineTool().toolID:      SubjectLineTool(),
        ToneShiftTool().toolID:        ToneShiftTool(),
        SummarizeTool().toolID:        SummarizeTool(),
        ReplyDraftTool().toolID:       ReplyDraftTool(),
        FollowUpTool().toolID:         FollowUpTool(),
        ProofreadTool().toolID:        ProofreadTool(),
        BulletToEmailTool().toolID:    BulletToEmailTool()
    ]

    func tool(for id: String) -> (any MailAITool)? { tools[id] }
    func allTools() -> [any MailAITool] { Array(tools.values).sorted { $0.displayName < $1.displayName } }
}

// MARK: - Validator

enum ValidationResult {
    case valid
    case invalid(violations: [String])
}

struct MarkdownOutputValidator {
    static func validate(_ output: String, against schema: MailAIOutputSchema) -> ValidationResult {
        var violations: [String] = []

        for pattern in schema.forbiddenPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(output.startIndex..., in: output)
                if regex.firstMatch(in: output, options: [], range: range) != nil {
                    violations.append("Output contains forbidden pattern: \(pattern)")
                }
            }
        }

        // Additional checks for disallowed markdown could go here if parsed
        return violations.isEmpty ? .valid : .invalid(violations: violations)
    }

    static func sanitize(_ output: String, against schema: MailAIOutputSchema) -> String {
        var result = output

        // Strip forbidden patterns
        for pattern in schema.forbiddenPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
            }
        }

        // Strip unsupported markdown nodes
        let allNodes = MarkdownNode.allCases
        let unsupported = allNodes.filter { !schema.allowedMarkdownNodes.contains($0) }

        for node in unsupported {
            let pattern: String
            switch node {
            case .bold: pattern = "\\*\\*(.*?)\\*\\*|__(.*?)__"
            case .italic: pattern = "\\*(.*?)\\*|_(.*?)_"
            case .heading1: pattern = "^#\\s+(.*)$"
            case .heading2: pattern = "^##\\s+(.*)$"
            case .heading3: pattern = "^###\\s+(.*)$"
            case .unorderedList: pattern = "^[-\\*+]\\s+(.*)$"
            case .orderedList: pattern = "^\\d+\\.\\s+(.*)$"
            case .blockquote: pattern = "^>\\s+(.*)$"
            case .inlineCode: pattern = "`(.*?)`"
            }

            if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "$1$2")
            }
        }

        // Collapse multiple blank lines
        if let multiLineRegex = try? NSRegularExpression(pattern: "\n{3,}", options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = multiLineRegex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "\n\n")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - MailAIToolsSystem

class MailAIToolsSystem: ObservableObject {
    static let shared = MailAIToolsSystem()
    private init() {}

    static let draftingSystemPrompt = """
    [ROLE]
    You are the Email Generation Engine for MailAIToolsSystem. Operate as an expert communication strategist for executive, business, and interpersonal writing.

    [DRAFTING RULES]
    - Analyze intent, audience, tone, priority, and context before writing.
    - Draft with strict precision: no fluff, no vague wording, no filler transitions.
    - Include an optimized subject line when requested, a strong opening line, a logically ordered body, and an intentional call-to-action.
    - Balance clarity and brevity: short when urgency dominates, fuller when nuance or risk framing is required.

    [TONE CONTROL]
    - Default to professional yet conversational unless a specific tone is requested.
    - Supported tones: Professional, Friendly, Executive, Concise, Persuasive, Assertive, Diplomatic.
    - Adapt tone deliberately to audience and scenario while preserving factual integrity.

    [FORMATTING]
    - Use proper paragraph spacing with blank lines between paragraphs.
    - Preserve line breaks in the output. Every paragraph must be separated by a double newline.
    - Keep greeting and sign-off on their own lines.

    [FALLBACK RULES]
    - If inputs are weak or underspecified, rewrite into stronger language without changing core intent.
    - When key inputs are missing, apply the safest professional default: neutral tone, clear purpose, concise context, explicit next step.

    [CONSTRAINTS]
    - Never hallucinate facts, names, dates, or figures not present in the input.
    - Use <<PLACEHOLDER: description>> for missing information.
    - Return only the requested artifact without extra commentary or preambles.
    - Enforce deterministic structure and consistent formatting across all responses.
    """
}

// MARK: - Constants

extension MailAIToolsSystem {
    static let costPerOutputToken: Double = 0.00002
}

struct MarkdownSyntaxStripper {
    static func plainText(from markdown: String) -> String {
        var text = markdown
        let patterns = ["```[\\s\\S]*?```", "`([^`]*)`", "!\\[[^\\]]*\\]\\([^\\)]*\\)", "\\[[^\\]]*\\]\\([^\\)]*\\)", "(^|\\n)#{1,6}\\s*", "[*_~>#-]", "\\d+\\.\\s"]
        for pattern in patterns {
            text = text.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }
        return text.replacingOccurrences(of: "\\n{3,}", with: "\\n\\n", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
