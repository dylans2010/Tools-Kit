import SwiftUI

struct ScopeTemplatesView: View {
    @State private var templates: [ScopeTemplate] = []

    var body: some View {
        List {
            Section("Reusable Scope Sets") {
                if templates.isEmpty {
                    Text("No scope templates created. Templates allow you to apply common permission sets to new apps.").foregroundStyle(.secondary)
                } else {
                    ForEach(templates) { template in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name).font(.headline)
                            Text("\(template.scopeIdentifiers.count) scopes").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Scope Templates")
        .toolbar {
            Button { /* Add template */ } label: { Image(systemName: "plus") }
        }
    }
}
