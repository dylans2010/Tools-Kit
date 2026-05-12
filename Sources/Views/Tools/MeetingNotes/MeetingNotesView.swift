import SwiftUI

struct MeetingNotesView: View {
    @StateObject private var backend = MeetingNotesBackend()

    var body: some View {
        Form {
            Section {
                TextField("Topic", text: $backend.topic)
                TextField("Participants (comma separated)", text: $backend.participants)

                Picker("Meeting Type", selection: $backend.selectedType) {
                    ForEach(MeetingType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            } header: {
                Text("Meeting Info")
            }

            Section {
                Button {
                    Task { await backend.generate() }
                } label: {
                    if backend.isProcessing {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Generate Structured Notes")
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isProcessing)
            }

            if !backend.generatedNotes.isEmpty {
                Section {
                    TextEditor(text: .constant(backend.generatedNotes))
                        .frame(height: 300)
                        .font(.system(.body, design: .monospaced))

                    Button(action: { UIPasteboard.general.string = backend.generatedNotes }) {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                    }
                } header: {
                    Text("Generated Notes")
                }
            }
        }
        .navigationTitle("Meeting Notes")
    }
}

struct MeetingNotesTool: Tool, Sendable {
    let name = "Meeting Notes"
    let icon = "calendar.badge.clock"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Generate structured meeting minutes and action items"
    let requiresAPI = true
    var view: AnyView { AnyView(MeetingNotesView()) }
}
