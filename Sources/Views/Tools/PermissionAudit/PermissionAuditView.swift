import SwiftUI

struct PermissionAuditTool: Tool, Sendable {
    let name = "Permission Audit"
    let icon = "lock.doc.fill"
    let category = ToolCategory.privacy
    let complexity = ToolComplexity.basic
    let description = "Review all permissions granted to this app for a clear privacy overview"
    let requiresAPI = false
    var view: AnyView { AnyView(PermissionAuditView()) }
}

struct PermissionAuditView: View {
    @StateObject private var backend = PermissionAuditBackend()

    var body: some View {
        ToolDetailView(tool: PermissionAuditTool()) {
            VStack(spacing: 16) {
                auditButton
                if backend.isLoading {
                    ProgressView("Checking permissions…").padding()
                } else if !backend.permissions.isEmpty {
                    summarySection
                    permissionsSection
                }
            }
        }
        .navigationTitle("Permission Audit")
        .onAppear { backend.audit() }
    }

    private var auditButton: some View {
        Button(action: backend.audit) {
            Label("Re-Audit Permissions", systemImage: "arrow.clockwise")
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal)
    }

    private var summarySection: some View {
        HStack(spacing: 12) {
            summaryCard("\(backend.grantedCount)", label: "Granted", color: .green, icon: "checkmark.circle.fill")
            summaryCard("\(backend.deniedCount)", label: "Denied", color: .red, icon: "xmark.circle.fill")
            summaryCard("\(backend.permissions.count - backend.grantedCount - backend.deniedCount)",
                       label: "Other", color: .orange, icon: "questionmark.circle.fill")
        }
        .padding(.horizontal)
    }

    private func summaryCard(_ value: String, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color).font(.title2)
            Text(value).font(.title3.bold())
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var permissionsSection: some View {
        ToolInputSection("Permissions (\(backend.permissions.count))") {
            ForEach(backend.permissions) { perm in
                permissionRow(perm)
                Divider().padding(.leading, 56)
            }
        }
    }

    private func permissionRow(_ perm: PermissionItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(statusColor(perm.status).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: perm.icon)
                    .foregroundColor(statusColor(perm.status))
                    .font(.system(size: 16, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(perm.name).font(.subheadline.weight(.medium))
                Text(perm.detail).font(.caption).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            Text(perm.statusText)
                .font(.caption.bold())
                .foregroundColor(statusColor(perm.status))
        }
        .padding()
    }

    private func statusColor(_ status: PermissionItem.Status) -> Color {
        switch status {
        case .granted: return .green
        case .denied: return .red
        case .undetermined: return .orange
        case .restricted: return .gray
        }
    }
}
