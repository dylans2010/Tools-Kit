import SwiftUI

struct LoremIpsumGeneratorDevTool: DevTool {
    let id = "lorem-ipsum-generator"
    let name = "Lorem Ipsum Generator"
    let category = DevToolCategory.utilities
    let icon = "text.alignleft"
    let description = "Generate placeholder text"

    func render() -> some View {
        LoremIpsumGeneratorView()
    }
}

struct LoremIpsumGeneratorView: View {
    @StateObject private var viewModel = LoremIpsumGeneratorViewModel()

    var body: some View {
        List {
            Section("Content Type") {
                Picker("Source Type", selection: $viewModel.contentType) {
                    Text("Standard").tag(LoremContentType.standard)
                    Text("Technobabble").tag(LoremContentType.techno)
                    Text("Developer").tag(LoremContentType.dev)
                }
                .pickerStyle(.segmented)

                Picker("Unit", selection: $viewModel.unit) {
                    Text("Paragraphs").tag(LoremUnit.paragraphs)
                    Text("Sentences").tag(LoremUnit.sentences)
                    Text("Words").tag(LoremUnit.words)
                }

                Stepper("Count: \(viewModel.count)", value: $viewModel.count, in: 1...50)
            }

            Section {
                ZStack(alignment: .bottomTrailing) {
                    TextEditor(text: .constant(viewModel.output))
                        .frame(minHeight: 250)
                        .font(.system(.subheadline, design: .serif))
                        .padding(4)

                    if !viewModel.output.isEmpty {
                        Button {
                            UIPasteboard.general.string = viewModel.output
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                                .padding(12)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        viewModel.generate()
                    } label: {
                        Label("Generate", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        viewModel.shareOutput()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .padding(8)
                            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Generated Preview")
            }

            Section("Metadata") {
                LabeledContent("Word Count", value: "\(viewModel.output.split(separator: " ").count)")
                LabeledContent("Character Count", value: "\(viewModel.output.count)")
            }
        }
        .navigationTitle("Lorem Ipsum")
        .onAppear { viewModel.generate() }
    }
}

enum LoremContentType {
    case standard, techno, dev
}

enum LoremUnit {
    case paragraphs, sentences, words
}

class LoremIpsumGeneratorViewModel: ObservableObject {
    @Published var contentType = LoremContentType.standard
    @Published var unit = LoremUnit.paragraphs
    @Published var count = 3
    @Published var output = ""

    func generate() {
        let baseText: String
        switch contentType {
        case .standard:
            baseText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur."
        case .techno:
            baseText = "Synthesizing the neural-link protocol requires an optimized quantum-state backbuffer. Bypassing the firewall involves recurring polymorphic sub-routines in the hyper-visor. The mainframe architecture is currently undergoing a non-linear data-stream synchronization."
        case .dev:
            baseText = "Refactoring the legacy singleton pattern to an observable architecture improved thread safety. The continuous integration pipeline executed all unit tests with 100% code coverage. Implementing a generic repository layer reduced boilerplate code significantly."
        }

        switch unit {
        case .paragraphs:
            output = Array(repeating: baseText, count: count).joined(separator: "\n\n")
        case .sentences:
            let sentences = baseText.components(separatedBy: ". ")
            var result = ""
            for i in 0..<count {
                result += sentences[i % sentences.count] + ". "
            }
            output = result.trimmingCharacters(in: .whitespaces)
        case .words:
            let words = baseText.components(separatedBy: " ")
            var result = ""
            for i in 0..<count {
                result += words[i % words.count] + " "
            }
            output = result.trimmingCharacters(in: .whitespaces)
        }
    }

    func shareOutput() {
        let av = UIActivityViewController(activityItems: [output], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

#Preview {
    LoremIpsumGeneratorView()
}
