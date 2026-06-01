import SwiftUI

// MARK: - Shared Data Models

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let title: String
    let detail: String

    init(title: String, detail: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.title = title
        self.detail = detail
    }
}

// MARK: - Protocols & Base Classes

protocol DevToolViewModel: ObservableObject {
    associatedtype State
    var state: State { get }
}

@MainActor
class BaseDevToolViewModel<State>: ObservableObject {
    @Published var state: State

    init(initialState: State) {
        self.state = initialState
    }
}

// MARK: - Shared UI Components

struct SimpleDevToolView: View {
    let title: String
    let placeholder: String
    let transform: (String) -> String
    @State private var input = ""
    @State private var output = ""

    init(title: String, placeholder: String, transform: @escaping (String) -> String) {
        self.title = title
        self.placeholder = placeholder
        self.transform = transform
    }

    var body: some View {
        Form {
            Section(header: Text("Input")) {
                TextEditor(text: $input)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 120)
                    .overlay(alignment: .topLeading) {
                        if input.isEmpty {
                            Text(placeholder)
                                .foregroundStyle(.tertiary)
                                .font(.system(.body, design: .monospaced))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section {
                Button {
                    output = transform(input)
                } label: {
                    Label("Process", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)

            if !output.isEmpty {
                Section(header: Text("Output")) {
                    Text(output)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)

                    Button {
                        UIPasteboard.general.string = output
                    } label: {
                        Label("Copy Output", systemImage: "doc.on.clipboard")
                    }
                }
            }
        }
    }
}
