import SwiftUI

private struct _DTConfigEntry: Identifiable, Hashable {
    let id = UUID()
    let key: String
    var value: String
    init(key: String, value: String) {
        self.key = key; self.value = value
    }
}

private class _DTConfigManager: ObservableObject {
    static let shared = _DTConfigManager()
    @Published var entries: [_DTConfigEntry] = []
    @Published var changes: [_DTConfigEntry] = []
    private init() {}
}

struct SDKConfigValidatorDevTool: DevTool {
    let id = "sdk-config-validator"
    let name = "Config Validator"
    let category = DevToolCategory.debugging
    let icon = "checkmark.shield.fill"
    let description = "Validate SDK configuration entries"

    func render() -> some View {
        SDKConfigValidatorView()
    }
}

struct SDKConfigValidatorView: View {
    @StateObject private var config = _DTConfigManager.shared

    var body: some View {
        let sortedConfigurations = config.entries.sorted { lhs, rhs in
            lhs.key < rhs.key
        }
        List {
            Section("Active Configurations") {
                ForEach(sortedConfigurations) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.key).font(.subheadline.bold())
                            Text(entry.value).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("LOCAL")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundStyle(.white)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4))
                    }
                }
            }

            Section("Configuration Change Log") {
                ForEach(config.changes.reversed(), id: \.self) { change in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(change.key).font(.caption.bold())
                        HStack {
                            Text("previous").strikethrough()
                            Image(systemName: "arrow.right")
                            Text(change.value)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

#Preview {
    SDKConfigValidatorView()
}
