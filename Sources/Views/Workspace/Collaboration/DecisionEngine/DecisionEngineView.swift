import SwiftUI

struct DecisionEngineView: View {
    @StateObject private var manager = DecisionEngineManager.shared
    let spaceID: UUID

    @State private var showingCreate = false
    @State private var newTitle = ""
    @State private var newOptions = ["", ""]

    var body: some View {
        List {
            ForEach(manager.sessions[spaceID] ?? []) { session in
                VStack(alignment: .leading, spacing: 12) {
                    Text(session.title).font(.headline)

                    ForEach(session.options) { option in
                        HStack {
                            Text(option.text)
                            Spacer()
                            Text("\(option.votes) votes").font(.caption).foregroundColor(.secondary)
                            Button("Vote") {
                                manager.vote(spaceID: spaceID, sessionID: session.id, optionID: option.id, weight: 1.0)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Decision Engine")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreate.toggle() }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                Form {
                    TextField("Decision Title", text: $newTitle)
                    Section(header: Text("Options")) {
                        ForEach(0..<newOptions.count, id: \.self) { index in
                            TextField("Option \(index + 1)", text: $newOptions[index])
                        }
                        Button("Add Option") { newOptions.append("") }
                    }
                    Button("Start Session") {
                        manager.createSession(spaceID: spaceID, title: newTitle, options: newOptions.filter { !$0.isEmpty })
                        showingCreate = false
                    }
                }
                .navigationTitle("New Decision")
            }
        }
    }
}
