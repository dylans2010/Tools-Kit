import SwiftUI

struct CitationFormatsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Academic Formats") {
                    CitationRow(name: "APA (7th ed.)", format: "Author, A. A. (Year). Title of work. Publisher.")
                    CitationRow(name: "MLA (9th ed.)", format: "Author. Title of Work. Publisher, Year.")
                    CitationRow(name: "Chicago (17th ed.)", format: "Author. Title of Work. City: Publisher, Year.")
                }

                Section("Professional Formats") {
                    CitationRow(name: "IEEE", format: "[1] A. Author, Title of Work. City: Publisher, Year.")
                    CitationRow(name: "Harvard", format: "Author, A. (Year) Title of work. City: Publisher.")
                }
            }
            .navigationTitle("Citations")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct CitationRow: View {
    let name: String
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.subheadline.bold())
            Text(format)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
