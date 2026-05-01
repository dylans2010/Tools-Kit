import SwiftUI

struct AddDataCollabView: View {
    @Environment(\.dismiss) var dismiss
    let spaceID: UUID
    @StateObject private var framework = CollaborationFramework.shared
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Available Workspace Data") {
                    if framework.indexedObjects.isEmpty {
                        Text("No compatible data found.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(framework.indexedObjects.keys), id: \.self) { id in
                            let type = framework.indexedObjects[id]!
                            HStack {
                                Label("\(type.rawValue.capitalized) \(id.uuidString.prefix(8))", systemImage: iconFor(type))
                                Spacer()
                                Button("Add") {
                                    framework.linkObject(objectID: id, to: spaceID)
                                    dismiss()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Add to Space")
            .toolbar {
                Button("Close") { dismiss() }
            }
        }
    }

    private func iconFor(_ type: CollaborationFramework.WorkspaceObjectType) -> String {
        switch type {
        case .notebook: return "book"
        case .slideDeck: return "rectangle.on.rectangle.angled"
        case .meeting: return "video"
        case .form: return "list.bullet.rectangle"
        case .spreadsheet: return "tablecells"
        case .mediaProject: return "photo.on.rectangle"
        }
    }
}
