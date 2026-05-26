import SwiftUI

struct NotebookFlashcardGeneratorView: View {
    let content: String
    @State private var flashcards: [Flashcard] = []
    @State private var showingAnswer = false
    @State private var currentIndex = 0

    struct Flashcard: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }

    var body: some View {
        VStack {
            if flashcards.isEmpty {
                ContentUnavailableView("No Flashcards", systemImage: "square.stack.3d.up", description: Text("Scanning content for potential questions..."))
                    .frame(maxHeight: .infinity)
            } else {
                cardStack

                HStack(spacing: 40) {
                    Button(action: previousCard) {
                        Image(systemName: "arrow.left.circle.fill").font(.largeTitle)
                    }
                    .disabled(currentIndex == 0)

                    Button(action: { showingAnswer.toggle() }) {
                        Text(showingAnswer ? "Show Question" : "Show Answer")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.accentColor.opacity(0.1), in: Capsule())
                    }

                    Button(action: nextCard) {
                        Image(systemName: "arrow.right.circle.fill").font(.largeTitle)
                    }
                    .disabled(currentIndex == flashcards.count - 1)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Study Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: generateFlashcards)
    }

    private var cardStack: some View {
        ZStack {
            let card = flashcards[currentIndex]
            VStack {
                Text(showingAnswer ? "ANSWER" : "QUESTION")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)

                Text(showingAnswer ? card.answer : card.question)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
            .padding(40)
            .shadow(radius: 5)
            .id(currentIndex)
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
    }

    private func generateFlashcards() {
        var found: [Flashcard] = []

        // Use real content to derive questions
        let lines = content.components(separatedBy: "\n")

        // Strategy 1: Find questions in text
        for line in lines where line.contains("?") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.count > 10 && trimmed.count < 100 {
                found.append(Flashcard(question: trimmed, answer: "Check your notes for the detailed answer."))
            }
        }

        // Strategy 2: Headers as questions
        for line in lines where line.hasPrefix("#") {
            let title = line.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
            if !title.isEmpty {
                found.append(Flashcard(question: "Explain the concept of '\(title)'", answer: "Refer to the section starting with this header."))
            }
        }

        // Fallback
        if found.isEmpty {
            found.append(Flashcard(question: "General Knowledge", answer: "Start writing notes to generate automated flashcards."))
        }

        flashcards = found
    }

    private func nextCard() {
        withAnimation {
            showingAnswer = false
            currentIndex += 1
        }
    }

    private func previousCard() {
        withAnimation {
            showingAnswer = false
            currentIndex -= 1
        }
    }
}
