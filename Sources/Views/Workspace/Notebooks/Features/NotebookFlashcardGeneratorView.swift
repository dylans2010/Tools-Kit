import SwiftUI

struct NotebookFlashcardGeneratorView: View {
    let content: String
    @State private var flashcards: [Flashcard] = []
    @State private var showingAnswer = false
    @State private var currentIndex = 0
    @State private var isGenerating = false
    @State private var errorMessage: String?

    struct Flashcard: Identifiable, Codable {
        let id: UUID
        let question: String
        let answer: String

        enum CodingKeys: String, CodingKey {
            case question, answer
        }

        init(id: UUID = UUID(), question: String, answer: String) {
            self.id = id
            self.question = question
            self.answer = answer
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = UUID()
            self.question = try container.decode(String.self, forKey: .question)
            self.answer = try container.decode(String.self, forKey: .answer)
        }
    }

    var body: some View {
        VStack {
            if isGenerating {
                generatingView
            } else if let error = errorMessage {
                errorView(error)
            } else if flashcards.isEmpty {
                emptyView
            } else {
                cardStackView
            }
        }
        .navigationTitle("Study Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !flashcards.isEmpty && !isGenerating {
                    Button {
                        Task { await generateFlashcards() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            if flashcards.isEmpty {
                await generateFlashcards()
            }
        }
    }

    // MARK: - Subviews

    private var generatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("AI is analyzing your notes...")
                .font(.headline)
            Text("Identifying key concepts and generating questions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)
            Text("Generation Failed")
                .font(.headline)
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                Task { await generateFlashcards() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Content",
            systemImage: "square.stack.3d.up",
            description: Text("Write more in your notebook so I can generate flashcards for you.")
        )
        .frame(maxHeight: .infinity)
    }

    private var cardStackView: some View {
        VStack {
            ZStack {
                let card = flashcards[currentIndex]
                VStack {
                    Text("Card \(currentIndex + 1) Of \(flashcards.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)

                    Spacer()

                    Text(showingAnswer ? "Answer" : "Question")
                        .font(.caption2.bold())
                        .foregroundStyle(showingAnswer ? .green : .blue)
                        .padding(.bottom, 10)

                    ScrollView {
                        Text(showingAnswer ? card.answer : card.question)
                            .font(.title3.bold())
                            .multilineTextAlignment(.center)
                            .padding()
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .padding(30)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                .id(currentIndex)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showingAnswer.toggle()
                }
            }

            HStack(spacing: 40) {
                Button(action: previousCard) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(currentIndex == 0)

                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showingAnswer.toggle()
                    }
                }) {
                    Text(showingAnswer ? "Show Question" : "Reveal Answer")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor, in: Capsule())
                        .foregroundStyle(.white)
                }

                Button(action: nextCard) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(currentIndex == flashcards.count - 1)
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - Logic

    @MainActor
    private func generateFlashcards() async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isGenerating = true
        errorMessage = nil

        let prompt = """
        Based on the following notebook content, generate a list of high-quality study flashcards.
        Each flashcard should have a clear, concise question and a detailed but understandable answer.
        Focus on key concepts, definitions, and important facts.

        Return the result as a JSON array of objects with "question" and "answer" fields.

        Content:
        \(content)
        """

        let schema = """
        [
          {
            "question": "string",
            "answer": "string"
          }
        ]
        """

        do {
            let jsonString = try await AIService.shared.generateStructuredJSON(
                prompt: prompt,
                jsonSchema: schema,
                systemPrompt: "You are an expert educator that creates effective study materials."
            )

            if let data = jsonString.data(using: .utf8) {
                let decoded = try JSONDecoder().decode([Flashcard].self, from: data)
                withAnimation {
                    self.flashcards = decoded
                    self.isGenerating = false
                }
            } else {
                throw AIError.invalidResponse
            }
        } catch {
            errorMessage = "Failed to generate flashcards: \(error.localizedDescription)"
            isGenerating = false
        }
    }

    private func nextCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showingAnswer = false
            currentIndex += 1
        }
    }

    private func previousCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showingAnswer = false
            currentIndex -= 1
        }
    }
}
