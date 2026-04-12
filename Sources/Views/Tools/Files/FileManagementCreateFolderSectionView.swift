import SwiftUI

struct FileManagementCreateFolderSectionView: View {
    @ObservedObject var backend: FileManagementBackend
    @State private var newFolderName = ""

    var body: some View {
        ToolInputSection("Create Folder") {
            HStack {
                TextField("Folder name", text: $newFolderName)
                    .textFieldStyle(.roundedBorder)
                Button("Create") {
                    backend.createFolder(name: newFolderName)
                    newFolderName = ""
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
