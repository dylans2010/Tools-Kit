import SwiftUI

struct SDKAPIBrowserView: View {
    @State private var searchText = ""

    var body: some View {
        List {
            Section("Available Methods") {
                ForEach(filteredMethods, id: \.self) { method in
                    VStack(alignment: .leading) {
                        Text(method).font(.system(.subheadline, design: .monospaced)).bold()
                        Text("Documentation for \(method)...").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("API Browser")
    }

    private var filteredMethods: [String] {
        let methods = [
            "workspace.notes.list()",
            "workspace.notes.create(title, content)",
            "workspace.tasks.create(title, dueDate)",
            "workspace.mail.send(to, subject, body)",
            "workspace.calendar.createEvent(title, start, end)",
            "workspace.persona.query(prompt)"
        ]
        if searchText.isEmpty { return methods }
        return methods.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
}
