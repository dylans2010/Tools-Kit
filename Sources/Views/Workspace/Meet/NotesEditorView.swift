import SwiftUI

struct NotesEditorView: View {
    @Binding var notes: String
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meeting Notes")
                .font(.headline)
            TextEditor(text: $notes)
                .frame(minHeight: 220)
                .padding(8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            HStack {
                Spacer()
                Button("Save Notes", action: onSave)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
