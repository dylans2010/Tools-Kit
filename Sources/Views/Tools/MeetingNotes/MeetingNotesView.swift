import SwiftUI

struct MeetingNotesView: View {
    @StateObject private var backend = MeetingNotesBackend()

    var body: some View {
        Form {
            Section(header: Text("Meeting Info")) {
                TextField("Topic", text: $backend.topic)
                TextField("Participants (comma separated)", text: $backend.participants)

                Picker("Meeting Type", selection: $backend.selectedType) {
                    ForEach(MeetingType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
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
                Section(header: Text("Generated Notes")) {
                    TextEditor(text: .constant(backend.generatedNotes))
                        .frame(height: 300)
                        .font(.system(.body, design: .monospaced))

                    Button(action: { UIPasteboard.general.string = backend.generatedNotes }) {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                    }
                }
            }
        }
        .navigationTitle("Meeting Notes")
    }
}

struct MeetingNotesTool: Tool {
    let name = "Meeting Notes"
    let icon = "calendar.badge.clock"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Generate structured meeting minutes and action items"
    let requiresAPI = true
    var view: AnyView { AnyView(MeetingNotesView()) }
}
