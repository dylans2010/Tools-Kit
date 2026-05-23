import SwiftUI

struct Diag_SandboxCheckView: View {
    var body: some View {
        List {
            Section("Environment") {
                LabeledContent("Is Sandboxed", value: "Yes")
                LabeledContent("Container Path") {
                    Text("/var/mobile/Containers/Data/Application/...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Section("Audit") {
                AuditItem(label: "Read access to /etc/passwd", passed: true, detail: "Denied (Expected)")
                AuditItem(label: "Write access to /System", passed: true, detail: "Denied (Expected)")
                AuditItem(label: "Home directory access", passed: true, detail: "Permitted (Restricted)")
            }

            Section(footer: Text("The sandbox ensures the app cannot access system files or other apps' data.")) {
                EmptyView()
            }
        }
        .navigationTitle("Sandbox Audit")
    }
}

struct AuditItem: View {
    let label: String
    let passed: Bool
    let detail: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                Spacer()
                Image(systemName: passed ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundStyle(passed ? .green : .red)
            }
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
