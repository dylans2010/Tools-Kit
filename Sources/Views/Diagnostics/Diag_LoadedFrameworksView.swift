import SwiftUI
import Darwin

struct Diag_LoadedFrameworksView: View {
    @State private var frameworks: [FrameworkInfo] = []
    @State private var stats: [(String, String)] = []
    @State private var searchText: String = ""

    struct FrameworkInfo: Identifiable {
        let id = UUID()
        let name: String
        let path: String
        let isSystem: Bool
    }

    var filteredFrameworks: [FrameworkInfo] {
        if searchText.isEmpty { return frameworks }
        return frameworks.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.path.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Form {
            Section("Loaded Frameworks") {
                VStack(spacing: 8) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("\(frameworks.count) Frameworks Loaded")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Statistics") {
                ForEach(stats, id: \.0) { stat in
                    LabeledContent(stat.0) { Text(stat.1).font(.caption) }
                }
            }

            Section("Frameworks (\(filteredFrameworks.count))") {
                TextField("Search frameworks...", text: $searchText)

                ForEach(filteredFrameworks.prefix(100)) { fw in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: fw.isSystem ? "building.columns.fill" : "shippingbox.fill")
                                .font(.caption)
                                .foregroundStyle(fw.isSystem ? .blue : .purple)
                            Text(fw.name)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                        }
                        Text(fw.path)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 1)
                }

                if filteredFrameworks.count > 100 {
                    Text("Showing 100 of \(filteredFrameworks.count) — use search to filter")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Loaded Frameworks")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadFrameworks() }
    }

    private func loadFrameworks() {
        var fws: [FrameworkInfo] = []
        let count = _dyld_image_count()

        for i in 0..<count {
            guard let namePtr = _dyld_get_image_name(i) else { continue }
            let path = String(cString: namePtr)
            let name = (path as NSString).lastPathComponent
            let isSystem = path.hasPrefix("/System/") || path.hasPrefix("/usr/lib/")
            fws.append(FrameworkInfo(name: name, path: path, isSystem: isSystem))
        }

        fws.sort { $0.name.lowercased() < $1.name.lowercased() }
        frameworks = fws

        let systemCount = fws.filter { $0.isSystem }.count
        let appCount = fws.count - systemCount
        stats = [
            ("Total Loaded", "\(fws.count)"),
            ("System Frameworks", "\(systemCount)"),
            ("App Frameworks", "\(appCount)"),
            ("Swift Runtime", fws.contains { $0.name.contains("Swift") } ? "Loaded" : "Not detected")
        ]
    }
}
