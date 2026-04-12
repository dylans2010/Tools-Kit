import SwiftUI

struct FileManagementCreateFileSectionView: View {
    @ObservedObject var backend: FileManagementBackend
    @State private var newFileName = ""
    @State private var selectedType: ManagedFileType = .text

    var body: some View {
        ToolInputSection("Create File") {
            VStack(spacing: 10) {
                TextField("File name", text: $newFileName)
                    .textFieldStyle(.roundedBorder)
                Picker("Type", selection: $selectedType) {
                    ForEach(FileManagementFeatures.supportedCreationTypes) { type in
                        Text(".\(type.rawValue)").tag(type)
                    }
                }
                Button("Create File") {
                    backend.createFile(name: newFileName, type: selectedType)
                    newFileName = ""
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
