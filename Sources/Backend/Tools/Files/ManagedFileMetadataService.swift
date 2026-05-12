import Foundation

struct ManagedFileMetadataService: Sendable {
    func listItems(in directory: URL) -> [ManagedFileItem] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return urls.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]) else {
                return nil
            }
            return ManagedFileItem(
                url: url,
                isDirectory: values.isDirectory ?? false,
                size: Int64(values.fileSize ?? 0),
                modifiedAt: values.contentModificationDate ?? Date()
            )
        }
        .sorted { $0.url.lastPathComponent.localizedCaseInsensitiveCompare($1.url.lastPathComponent) == .orderedAscending }
    }
}
