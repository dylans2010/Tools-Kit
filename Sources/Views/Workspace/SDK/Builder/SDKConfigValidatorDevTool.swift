import SwiftUI

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
    @StateObject private var config = SDKConfigManager.shared

    var body: some View {
        let sortedConfigurations = config.entries.sorted { lhs, rhs in
            lhs.key < rhs.key
        }
        VStack(spacing: 0) {
            DevToolHeader(
                title: "SDK Config Validator",
                description: "Validate active configurations and inspect the change log for auditing purposes.",
                icon: "checkmark.shield.fill"
            )
            .padding()

            List {
                Section("Active Configurations") {
                    ForEach(sortedConfigurations) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.key).font(.subheadline.bold())
                                Text(entry.value).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            StatusBadge(text: entry.source.rawValue, color: .accentColor)
                        }
                    }
                }

                Section("Configuration Change Log") {
                    ForEach(config.changes.reversed(), id: \.self) { change in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(change.key).font(.caption.bold())
                            HStack {
                                Text(change.oldValue ?? "nil").strikethrough()
                                Image(systemName: "arrow.right")
                                Text(change.newValue ?? "nil")
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
}
