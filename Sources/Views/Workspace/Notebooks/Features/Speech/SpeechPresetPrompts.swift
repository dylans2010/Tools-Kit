import Foundation

struct SpeechPresetPrompts {
    static let all: [SpeechPresetPrompt] = [
        // Analysis
        SpeechPresetPrompt(title: "Summarize Briefly", prompt: "Summarize this recording in 3 bullet points.", category: "Analysis"),
        SpeechPresetPrompt(title: "Detailed Summary", prompt: "Provide a detailed summary of the main arguments and conclusions.", category: "Analysis"),
        SpeechPresetPrompt(title: "Extract Action Items", prompt: "What are the specific tasks and deadlines mentioned?", category: "Analysis"),
        SpeechPresetPrompt(title: "Identify Decisions", prompt: "List all major decisions made during this session.", category: "Analysis"),
        SpeechPresetPrompt(title: "Tone Analysis", prompt: "Analyze the tone and sentiment of the speaker(s).", category: "Analysis"),
        SpeechPresetPrompt(title: "Key Takeaways", prompt: "What are the top 5 key takeaways from this audio?", category: "Analysis"),
        SpeechPresetPrompt(title: "Conflict Detection", prompt: "Were there any contradictions or disagreements mentioned?", category: "Analysis"),

        // Creative
        SpeechPresetPrompt(title: "Convert to Blog Post", prompt: "Turn this transcript into a structured blog post with headings.", category: "Creative"),
        SpeechPresetPrompt(title: "Draft Email", prompt: "Draft a follow-up email based on the action items discussed.", category: "Creative"),
        SpeechPresetPrompt(title: "Create LinkedIn Post", prompt: "Write a short, engaging LinkedIn post summarizing these ideas.", category: "Creative"),
        SpeechPresetPrompt(title: "Generate Q&A", prompt: "Create a list of potential questions and answers based on this content.", category: "Creative"),
        SpeechPresetPrompt(title: "Explain to a Child", prompt: "Explain the main concept of this recording as if I were 5 years old.", category: "Creative"),

        // Refinement
        SpeechPresetPrompt(title: "Fix Transcription", prompt: "Correct any obvious transcription errors in the text.", category: "Refinement"),
        SpeechPresetPrompt(title: "Professional Polish", prompt: "Rewrite the key points in a more professional and formal tone.", category: "Refinement"),
        SpeechPresetPrompt(title: "Simplify Jargon", prompt: "Explain any technical jargon used in this recording in simple terms.", category: "Refinement"),
    ] + (1...300).map { i in
        let categories = ["Analysis", "Creative", "Refinement", "Questions", "Insights", "Summary", "Planning"]
        let category = categories[i % categories.count]

        let templates = [
            "What was the most important point made about \(category.lowercased())?",
            "Can you expand on the \(i % 3 == 0 ? "first" : "last") part of the discussion regarding \(category.lowercased())?",
            "How does the content in this recording relate to \(category.lowercased()) best practices?",
            "Identify three ways to improve the \(category.lowercased()) mentioned here.",
            "Summarize the \(category.lowercased()) section in one sentence.",
            "What are the long-term implications of the \(category.lowercased()) discussed?",
            "Compare the different viewpoints on \(category.lowercased()) presented in the audio.",
            "Draft a proposal for \(category.lowercased()) based on these notes.",
            "What follow-up questions should I ask about \(category.lowercased())?",
            "Identify the emotional cues related to \(category.lowercased()) in the speaker's voice."
        ]

        return SpeechPresetPrompt(
            title: "\(category) Insight \(i)",
            prompt: templates[i % templates.count],
            category: category
        )
    }
}
