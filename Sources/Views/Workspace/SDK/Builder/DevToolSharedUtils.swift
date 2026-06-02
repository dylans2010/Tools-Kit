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

// MARK: - Shared Simple Tool View

public struct SimpleDevToolView: View {
    public let title: String
    public let placeholder: String
    public let transform: (String) -> String

    @State private var input = ""
    @State private var output = ""

    public init(title: String, placeholder: String, transform: @escaping (String) -> String) {
        self.title = title
        self.placeholder = placeholder
        self.transform = transform
    }

    public var body: some View {
        Form {
            Section(header: Text("Input")) {
                TextEditor(text: $input)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 80)
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
                        #if os(iOS)
                        UIPasteboard.general.string = output
                        #elseif os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(output, forType: .string)
                        #endif
                    } label: {
                        Label("Copy Output", systemImage: "doc.on.clipboard")
                    }
                }
            }
        }
    }
}

// MARK: - String Helper

public extension String {
    func leftPadded(to length: Int, with character: Character = "0") -> String {
        let deficit = length - count
        if deficit <= 0 { return self }
        return String(repeating: character, count: deficit) + self
    }
}
