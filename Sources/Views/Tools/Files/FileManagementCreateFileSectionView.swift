import SwiftUI

struct FileManagementCreateFileSectionView: View {
    @ObservedObject var backend: FileManagementBackend
    let onDismiss: () -> Void
    @State private var newFileName = ""
    @State private var selectedType: ManagedFileType = .text

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $newFileName)
                        .autocorrectionDisabled()
                    Picker("Type", selection: $selectedType) {
                        ForEach(ManagedFileType.allCases) { type in
                            Text(".\(type.rawValue)").tag(type)
                        }
                    }
                } header: {
                    Text("File Details")
                }
            }
            .navigationTitle("New File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        backend.createFile(name: newFileName, type: selectedType)
                        newFileName = ""
                        onDismiss()
                    }
                    .disabled(newFileName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
