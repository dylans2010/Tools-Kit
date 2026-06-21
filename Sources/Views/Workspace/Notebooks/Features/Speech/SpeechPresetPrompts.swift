import Foundation

struct SpeechPresetPrompts {
    static let all: [NotebookSpeechPresetPrompt] = [
        // Analysis
        NotebookSpeechPresetPrompt(title: "Summarize Briefly", prompt: "Summarize this recording in 3 bullet points.", category: "Analysis"),
        NotebookSpeechPresetPrompt(title: "Detailed Summary", prompt: "Provide a detailed summary of the main arguments and conclusions.", category: "Analysis"),
        NotebookSpeechPresetPrompt(title: "Extract Action Items", prompt: "What are the specific tasks and deadlines mentioned?", category: "Analysis"),
        NotebookSpeechPresetPrompt(title: "Identify Decisions", prompt: "List all major decisions made during this session.", category: "Analysis"),
        NotebookSpeechPresetPrompt(title: "Tone Analysis", prompt: "Analyze the tone and sentiment of the speaker(s).", category: "Analysis"),
        NotebookSpeechPresetPrompt(title: "Key Takeaways", prompt: "What are the top 5 key takeaways from this audio?", category: "Analysis"),
        NotebookSpeechPresetPrompt(title: "Conflict Detection", prompt: "Were there any contradictions or disagreements mentioned?", category: "Analysis"),

        // Creative
        NotebookSpeechPresetPrompt(title: "Convert to Blog Post", prompt: "Turn this transcript into a structured blog post with headings.", category: "Creative"),
        NotebookSpeechPresetPrompt(title: "Draft Email", prompt: "Draft a follow-up email based on the action items discussed.", category: "Creative"),
        NotebookSpeechPresetPrompt(title: "Create LinkedIn Post", prompt: "Write a short, engaging LinkedIn post summarizing these ideas.", category: "Creative"),
        NotebookSpeechPresetPrompt(title: "Generate Q&A", prompt: "Create a list of potential questions and answers based on this content.", category: "Creative"),
        NotebookSpeechPresetPrompt(title: "Explain to a Child", prompt: "Explain the main concept of this recording as if I were 5 years old.", category: "Creative"),

        // Refinement
        NotebookSpeechPresetPrompt(title: "Fix Transcription", prompt: "Correct any obvious transcription errors in the text.", category: "Refinement"),
        NotebookSpeechPresetPrompt(title: "Professional Polish", prompt: "Rewrite the key points in a more professional and formal tone.", category: "Refinement"),
        NotebookSpeechPresetPrompt(title: "Simplify Jargon", prompt: "Explain any technical jargon used in this recording in simple terms.", category: "Refinement"),

        // Strategy & Planning
        NotebookSpeechPresetPrompt(title: "SWOT Analysis", prompt: "Perform a SWOT analysis based on the recording.", category: "Strategy"),
        NotebookSpeechPresetPrompt(title: "Risk Assessment", prompt: "Identify potential risks mentioned or implied in this discussion.", category: "Strategy"),
        NotebookSpeechPresetPrompt(title: "Next Steps Roadmap", prompt: "Create a 30-60-90 day roadmap based on these discussions.", category: "Strategy"),

        // Questions & Exploration
        NotebookSpeechPresetPrompt(title: "Missing Information", prompt: "What crucial information is missing from this recording to make a final decision?", category: "Questions"),
        NotebookSpeechPresetPrompt(title: "Assumption Audit", prompt: "List all assumptions made by the speakers in this audio.", category: "Questions"),
        NotebookSpeechPresetPrompt(title: "Counter-Arguments", prompt: "Generate strong counter-arguments to the main points presented.", category: "Questions")
    ] + (1...300).map { i in
        let categories = ["Analysis", "Creative", "Refinement", "Questions", "Insights", "Summary", "Planning", "Strategy", "Education", "Legal", "Financial"]
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
            "Identify the emotional cues related to \(category.lowercased()) in the speaker's voice.",
            "Create a checklist for \(category.lowercased()) from this content.",
            "Analyze the impact of \(category.lowercased()) on the project timeline.",
            "Who are the key stakeholders for \(category.lowercased()) mentioned?",
            "Extract any metrics or data related to \(category.lowercased()).",
            "How should we communicate the \(category.lowercased()) updates to the team?"
        ]

        return NotebookSpeechPresetPrompt(
            title: "\(category) Deep Dive \(i)",
            prompt: templates[i % templates.count],
            category: category
        )
    }
}
