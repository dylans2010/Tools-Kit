import SwiftUI

struct ForkView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var forkManager = ForkManager.shared

    let originalSpace: CollaborationSpace
    @State private var newName: String = ""
    @State private var isForking = false

    init(space: CollaborationSpace) {
        self.originalSpace = space
        _newName = State(initialValue: "\(space.name)-fork")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Fork Details")) {
                    TextField("Space Name", text: $newName)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("You are forking:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: originalSpace.icon)
                            Text(originalSpace.name).bold()
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button(action: performFork) {
                        if isForking {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Fork")
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                    }
                    .disabled(newName.isEmpty || isForking)
                }

                Section(footer: Text("Forking creates a copy of the space and all its objects. You can contribute back via pull requests.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Fork Space")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func performFork() {
        isForking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            _ = forkManager.forkSpace(id: originalSpace.id, newName: newName)
            isForking = false
            dismiss()
        }
    }
}
