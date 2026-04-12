import SwiftUI

struct FileManagementStatsSectionView: View {
    @ObservedObject var backend: FileManagementBackend

    var body: some View {
        ToolInputSection("Stats") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Items: \(backend.totalCount)")
                Text("Files: \(backend.totalFiles)")
                Text("Folders: \(backend.totalFolders)")
                Text("Storage: \(ByteCountFormatter.string(fromByteCount: backend.totalBytes, countStyle: .file))")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
