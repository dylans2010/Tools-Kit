import SwiftUI

struct SDKVersionManagerView: View {
    @StateObject private var versionManager = SDKVersionManager.shared

    var body: some View {
        List {
            Section(header: Text("Current Version")) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("SDK \(versionManager.versionString)")
                            .font(.title2.bold())
                        Text("Workspace SDK Platform")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                }
            }

            Section(header: Text("Compatibility")) {
                ForEach(Array(versionManager.compatibilityMatrix.keys.sorted()), id: \.self) { component in
                    let result = versionManager.checkComponentCompatibility(component)
                    HStack {
                        Text(component)
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: result.status == .compatible ? "checkmark.circle.fill" : result.status == .incompatible ? "xmark.circle.fill" : "questionmark.circle")
                            .foregroundStyle(result.status == .compatible ? .green : result.status == .incompatible ? .red : .secondary)
                        Text(result.status.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(header: Text("Changelog")) {
                ForEach(versionManager.changelog) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("v\(entry.version.description)")
                                .font(.headline)
                            Spacer()
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(entry.changes) { change in
                            HStack(alignment: .top, spacing: 6) {
                                Text(change.type.rawValue.uppercased())
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(changeColor(change.type).opacity(0.15))
                                    .foregroundStyle(changeColor(change.type))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                                Text(change.description)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if !versionManager.activeDeprecations().isEmpty {
                Section(header: Text("Deprecations")) {
                    ForEach(versionManager.activeDeprecations()) { notice in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notice.api)
                                .font(.subheadline.monospaced())
                            Text(notice.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Use \(notice.alternative) Instead")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Version Manager")
    }

    private func changeColor(_ type: ChangeType) -> Color {
        switch type {
        case .feature: return .green
        case .improvement: return .blue
        case .fix: return .orange
        case .breaking: return .red
        case .deprecation: return .yellow
        }
    }
}
