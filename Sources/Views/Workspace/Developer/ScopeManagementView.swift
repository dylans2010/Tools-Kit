import SwiftUI

struct ScopeManagementView: View {
    @ObservedObject var scopeService = DeveloperScopeService.shared
    @State private var selectedTab = 0
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
                if scopeService.grantedScopes.isEmpty {
                    Text("No scopes granted yet.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(scopeService.grantedScopes) { grant in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(grant.scopeIdentifier).font(.caption.monospaced()).bold()
                                Spacer()
                                Text("Granted").font(.caption2).foregroundStyle(.green)
                            }
                            Text(grant.grantDate.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { try? await scopeService.revokeScope(id: grant.id) }
                            } label: {
                                Label("Revoke", systemImage: "xmark.circle")
                            }
                        }
                    }
                }
            }

            Section("Pending Requests") {
                if scopeService.pendingRequests.isEmpty {
                    Text("No pending requests.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(scopeService.pendingRequests) { request in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(request.scopeIdentifier).font(.caption.monospaced())
                                Text(request.justification).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            Text(request.status.rawValue).font(.caption2).foregroundStyle(.orange)
                        }
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

                if scopeService.catalog.isEmpty {
                    Text("The scope catalog is currently empty.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(scopeService.catalog) { scope in
                        scopeCard(scope)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func scopeCard(_ scope: DeveloperScope) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(scope.category.rawValue).font(.caption2.bold()).foregroundStyle(.secondary)
                Spacer()
                Text(scope.riskLevel.rawValue).font(.caption2.bold()).foregroundStyle(riskColor(scope.riskLevel))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(riskColor(scope.riskLevel).opacity(0.1), in: Capsule())
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
                    appId: UUID(), // Should be selected app in real use
                    scopeIdentifier: scope.id,
                    justification: justifications[scope.id] ?? ""
                )
                Task { try? await scopeService.submitRequest(request) }
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

    private func riskColor(_ risk: ScopeRiskLevel) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }

    private var scopeAuditLogView: some View {
        List {
            if scopeService.auditLog.isEmpty {
                Text("No audit log entries found.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(scopeService.auditLog) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Circle().fill(.blue).frame(width: 8, height: 8).padding(.top, 4)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.eventType).font(.subheadline.bold())
                            Text("scope:\(event.scopeIdentifier)").font(.caption2).foregroundStyle(.secondary)
                            Text(event.timestamp.formatted()).font(.system(size: 8)).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }
}
