import SwiftUI

struct ClipboardManagerView: View {
    @StateObject private var backend = ClipboardManagerBackend()
    @State private var textToCopy = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("New Entry").font(.caption).foregroundColor(.secondary)
                HStack {
                    TextField("Type or Paste Text", text: $textToCopy)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Copy") {
                        backend.copyToClipboard(textToCopy)
                        textToCopy = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(textToCopy.isEmpty)
                }

                Button(action: {
                    let pasted = backend.pasteFromClipboard()
                    if textToCopy.isEmpty { textToCopy = pasted }
                }) {
                    Label("Paste From Clipboard", systemImage: "doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.secondarySystemBackground))

            List {
                Section(header: Text("History")) {
                    if backend.history.isEmpty {
                        Text("No History Yet").foregroundColor(.secondary)
                    } else {
                        ForEach(backend.history) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.content)
                                    .lineLimit(3)
                                    .font(.system(.subheadline, design: .monospaced))

                                HStack {
                                    Text(entry.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button(action: { UIPasteboard.general.string = entry.content }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: backend.deleteEntry)
                    }
                }
            }
            .listStyle(PlainListStyle())

            if !backend.history.isEmpty {
                Button("Clear History", role: .destructive) {
                    backend.clearHistory()
                }
                .padding()
            }
        }
        .navigationTitle("Clipboard Manager")
    }
}

struct ClipboardManagerTool: Tool {
    let name = "Clipboard Manager"
    let icon = "paperclip"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Keep track of your recently copied text and manage history"
    let requiresAPI = false
    var view: AnyView { AnyView(ClipboardManagerView()) }
}
