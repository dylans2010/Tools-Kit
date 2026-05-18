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
    @StateObject private var configManager = SDKConfigManager.shared

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "SDK Config Validator",
                description: "Validate active configurations and inspect the change log for auditing purposes.",
                icon: "checkmark.shield.fill"
            )
            .padding()

            List {
                Section("Active Configurations") {
                    ForEach(Array(configManager.configurations.values).sorted(by: { $0.key < $1.key })) { entry in
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
                    ForEach(configManager.changeLog.reversed()) { change in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(change.key).font(.caption.bold())
                            HStack {
                                Text(change.oldValue ?? "nil").strikethrough()
                                Image(systemName: "arrow.right")
                                Text(change.newValue ?? "nil")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                            Text(change.timestamp, style: .relative)
                                .font(.system(size: 8))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}
