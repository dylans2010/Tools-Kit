import SwiftUI

public struct AIGenerateSlides: View {
    @StateObject private var manager = AISlidesManager.shared
    @StateObject private var whiteboardStore = WhiteboardStore.shared

    @State private var rawText = ""
    @State private var notes = ""
    @State private var documents = ""
    @State private var selectedBoardID: UUID?
    @State private var slideCount = 8
    @State private var tone: SlideTone = .formal
    @State private var audience: SlideAudience = .internal
    @State private var density: SlideVisualDensity = .medium
    @State private var includeImages = true

    @State private var generatedDeck: SlideDeck?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Input") {
                    VStack(spacing: 10) {
                        TextField("Topic or presentation goal", text: $rawText, axis: .vertical)
                            .lineLimit(2...5)
                        TextField("Notes (one per line)", text: $notes, axis: .vertical)
                            .lineLimit(2...5)
                        TextField("Document snippets", text: $documents, axis: .vertical)
                            .lineLimit(2...5)

                        Picker("Whiteboard", selection: $selectedBoardID) {
                            Text("None").tag(UUID?.none)
                            ForEach(whiteboardStore.boards) { board in
                                Text(board.title).tag(UUID?.some(board.id))
                            }
                        }
                    }
                }

                GroupBox("Configuration") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Slide Count")
                            Spacer()
                            Text("\(slideCount)")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(get: { Double(slideCount) }, set: { slideCount = Int($0) }), in: 5...15, step: 1)

                        Picker("Tone", selection: $tone) {
                            ForEach(SlideTone.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        Picker("Audience", selection: $audience) {
                            ForEach(SlideAudience.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        Picker("Visual Density", selection: $density) {
                            ForEach(SlideVisualDensity.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        Toggle("Include Images", isOn: $includeImages)
                    }
                }

                Button(action: generate) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(manager.isGenerating ? "Generating..." : "Generate")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.isGenerating)

                if manager.isGenerating {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: manager.progressValue)
                        Text(manager.progressMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let deck = generatedDeck ?? manager.latestDeck {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Slide Preview")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                            ForEach(deck.slides) { slide in
                                NavigationLink {
                                    SlideCanvasView(deck: deck, startAt: slide.id)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(slide.title)
                                            .font(.headline)
                                            .lineLimit(2)
                                        Text(slide.type.capitalized)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("AI Slides")
    }

    private func generate() {
        let board = whiteboardStore.boards.first(where: { $0.id == selectedBoardID })
        let input: SlideInput

        if let board {
            input = WhiteboardAIEngine().slideInput(
                from: board,
                rawText: rawText,
                tone: tone,
                audience: audience,
                slideCount: slideCount,
                includeImages: includeImages,
                density: density
            )
        } else {
            input = SlideInput(
                rawText: rawText,
                notes: notes.split(separator: "\n").map(String.init),
                whiteboardNodes: [],
                documents: documents.split(separator: "\n").map(String.init),
                tone: tone,
                audience: audience,
                slideCount: slideCount,
                includeImages: includeImages,
                visualDensity: density
            )
        }

        Task {
            generatedDeck = await manager.generate(input: input)
        }
    }
}
