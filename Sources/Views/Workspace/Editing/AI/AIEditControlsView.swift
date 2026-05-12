import SwiftUI

struct AIEditControlsView: View {
    @StateObject private var aiEngine = AIEditingEngine.shared
    @State private var prompt = ""
    @State private var isProcessing = false
    @State private var selectedStyle: AIEditStyle = .none
    @State private var smartRemoveActive = false
    @State private var autoGradeApplied = false
    @State private var upscaleInProgress = false
    @State private var generatedPreview: String?

    var body: some View {
        List {
            Section {
                TextField("Describe what you want (e.g., 'sunset on Mars')", text: $prompt, axis: .vertical)
                    .lineLimit(2...4)

                Button {
                    isProcessing = true
                    Task {
                        let _ = await aiEngine.generateBackground(prompt: prompt)
                        await MainActor.run {
                            isProcessing = false
                            generatedPreview = prompt
                        }
                    }
                } label: {
                    HStack {
                        Label("Generate & Apply", systemImage: "wand.and.stars")
                        Spacer()
                        if isProcessing {
                            ProgressView()
                        }
                    }
                }
                .disabled(prompt.isEmpty || isProcessing)

                if let preview = generatedPreview {
                    LabeledContent("Last Generated", value: preview)
                        .font(.caption)
                }
            } header: {
                Label("Generative Background", systemImage: "sparkles")
            }

            Section {
                Picker(selection: $selectedStyle) {
                    ForEach(AIEditStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                } label: {
                    Label("Style Transfer", systemImage: "paintbrush")
                }
                .onChange(of: selectedStyle) { _, style in
                    if style != .none {
                        aiEngine.applyStyleTransfer(style.rawValue)
                    }
                }
            } header: {
                Label("Style", systemImage: "theatermasks")
            }

            Section {
                Button {
                    smartRemoveActive.toggle()
                    if smartRemoveActive {
                        aiEngine.enterSmartRemoveMode()
                    }
                } label: {
                    HStack {
                        Label("Smart Remove", systemImage: "eraser")
                        Spacer()
                        if smartRemoveActive {
                            Text("Active")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button {
                    autoGradeApplied = true
                    aiEngine.autoGrade()
                } label: {
                    HStack {
                        Label("Auto Grade", systemImage: "wand.and.rays")
                        Spacer()
                        if autoGradeApplied {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button {
                    upscaleInProgress = true
                    Task {
                        await aiEngine.upscaleImage()
                        await MainActor.run { upscaleInProgress = false }
                    }
                } label: {
                    HStack {
                        Label("AI Upscale", systemImage: "arrow.up.forward.square")
                        Spacer()
                        if upscaleInProgress {
                            ProgressView()
                        }
                    }
                }
                .disabled(upscaleInProgress)

                Button {
                    aiEngine.autoEnhance()
                } label: {
                    Label("Auto Enhance", systemImage: "sparkle.magnifyingglass")
                }
            } header: {
                Label("Quick Actions", systemImage: "bolt")
            }
        }
        .navigationTitle("AI Editing Tools")
    }
}

enum AIEditStyle: String, CaseIterable, Identifiable, Sendable {
    case none = "None"
    case cinematic = "Cinematic"
    case vintage = "Vintage"
    case watercolor = "Watercolor"
    case sketch = "Sketch"
    case popart = "Pop Art"

    var id: String { rawValue }
}
