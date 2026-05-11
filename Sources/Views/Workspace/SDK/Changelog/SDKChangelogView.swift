import SwiftUI

struct SDKChangelogView: View {
    @StateObject private var versionManager = SDKVersionManager.shared
    @State private var selectedChangeType: ChangeType?

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        filterChip(nil, label: "All")
                        ForEach(ChangeType.allCases, id: \.self) { type in
                            filterChip(type, label: type.rawValue.capitalized)
                        }
                    }
                }
            }

            ForEach(versionManager.changelog) { entry in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("v\(entry.version.description)")
                                .font(.title2.bold())
                            if entry.version == versionManager.currentVersion {
                                Text("Current")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        let filtered = selectedChangeType == nil ? entry.changes : entry.changes.filter { $0.type == selectedChangeType }
                        ForEach(filtered) { change in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: changeIcon(change.type))
                                    .foregroundStyle(changeColor(change.type))
                                    .frame(width: 20)
                                VStack(alignment: .leading) {
                                    Text(change.type.rawValue.uppercased())
                                        .font(.caption2.bold())
                                        .foregroundStyle(changeColor(change.type))
                                    Text(change.description)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Changelog")
    }

    private func filterChip(_ type: ChangeType?, label: String) -> some View {
        Button { selectedChangeType = type } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(selectedChangeType == type ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(selectedChangeType == type ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func changeIcon(_ type: ChangeType) -> String {
        switch type {
        case .feature: return "star.fill"
        case .improvement: return "arrow.up.circle.fill"
        case .fix: return "wrench.fill"
        case .breaking: return "exclamationmark.triangle.fill"
        case .deprecation: return "clock.arrow.circlepath"
        }
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
