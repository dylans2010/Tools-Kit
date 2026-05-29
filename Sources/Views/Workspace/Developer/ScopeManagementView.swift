import SwiftUI

struct ScopeManagementView: View {
    @State private var selectedTab = 0
    @State private var searchText = ""

    let availableScopes: [DeveloperScope] = [
        DeveloperScope(id: "read:user", name: "Read User Profile", description: "Access basic user information like name and avatar.", riskLevel: .low, category: "User Identity"),
        DeveloperScope(id: "write:user", name: "Write User Profile", description: "Modify user profile information.", riskLevel: .medium, category: "User Identity"),
        DeveloperScope(id: "read:data", name: "Read Workspace Data", description: "Access files, notes, and tasks in the workspace.", riskLevel: .medium, category: "Read Data"),
        DeveloperScope(id: "write:data", name: "Write Workspace Data", description: "Create or modify files and notes.", riskLevel: .high, category: "Write Data"),
        DeveloperScope(id: "sys:admin", name: "System Admin", description: "Full access to system configurations and internal APIs.", riskLevel: .critical, category: "System-Level", requiredTier: .enterprise)
    ]

    @State private var pendingRequests: [ScopeRequest] = []
    @State private var justifications: [String: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedTab) {
                Text("My Scopes").tag(0)
                Text("Request New").tag(1)
                Text("Audit Log").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                myGrantedScopesList
            } else if selectedTab == 1 {
                requestNewScopeView
            } else {
                scopeAuditLogView
            }
        }
        .navigationTitle("Scope Management")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var myGrantedScopesList: some View {
        List {
            Section("Currently Granted") {
                ForEach(availableScopes.prefix(2)) { scope in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(scope.id).font(.caption.monospaced()).bold()
                            Spacer()
                            Text("Granted").font(.caption2).foregroundStyle(.green)
                        }
                        Text(scope.name).font(.subheadline)
                        Text(scope.description).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button(role: .destructive) {
                            // Revoke
                        } label: {
                            Label("Revoke", systemImage: "xmark.circle")
                        }
                    }
                }
            }

            Section("Pending Requests") {
                ForEach(pendingRequests) { request in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(request.scopeId).font(.caption.monospaced())
                            Text(request.justification).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer()
                        Text(request.status.rawValue).font(.caption2).foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    private var requestNewScopeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Browse Scopes")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(availableScopes) { scope in
                    scopeCard(scope)
                }
            }
            .padding(.vertical)
        }
    }

    private func scopeCard(_ scope: DeveloperScope) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(scope.category).font(.caption2.bold()).foregroundStyle(.secondary)
                Spacer()
                Text(scope.riskLevel.rawValue).font(.caption2.bold()).foregroundStyle(scope.riskLevel.color)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(scope.riskLevel.color.opacity(0.1), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(scope.name).font(.subheadline.bold())
                Text(scope.id).font(.caption2.monospaced()).foregroundStyle(.tertiary)
                Text(scope.description).font(.caption).foregroundStyle(.secondary)
            }

            if scope.riskLevel == .high || scope.riskLevel == .critical {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Justification Required").font(.caption.bold())
                    TextField("How will you use this data?", text: Binding(
                        get: { justifications[scope.id] ?? "" },
                        set: { justifications[scope.id] = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                let request = ScopeRequest(
                    id: UUID(),
                    appId: UUID(), // Should be selected app
                    scopeId: scope.id,
                    justification: justifications[scope.id] ?? "N/A",
                    status: .pending,
                    requestedAt: Date()
                )
                pendingRequests.append(request)
            } label: {
                Text("Request Scope")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var scopeAuditLogView: some View {
        List {
            ForEach(0..<10) { i in
                HStack(alignment: .top, spacing: 12) {
                    VStack {
                        Circle().fill(i % 3 == 0 ? .green : (i % 5 == 0 ? .red : .blue)).frame(width: 8, height: 8)
                        Rectangle().fill(.secondary.opacity(0.2)).frame(width: 1)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(i % 3 == 0 ? "Scope Granted" : (i % 5 == 0 ? "Request Rejected" : "Scope Requested"))
                            .font(.subheadline.bold())
                        Text("scope:read:data • App: GitHub Pro").font(.caption2).foregroundStyle(.secondary)
                        Text(Date().addingTimeInterval(Double(-i * 3600)).formatted()).font(.system(size: 8)).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}
