import SwiftUI

struct ScopeManagementView: View {
    @ObservedObject var scopeService = DeveloperScopeService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedTab = 0
    @State private var justifications: [String: String] = [:]
    @State private var selectedAppID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedTab) {
                Text("Granted").tag(0)
                Text("Catalog").tag(1)
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
            Section("Active Permissions") {
                if scopeService.grantedScopes.isEmpty {
                    EmptyStateView(icon: "shield.slash", title: "No Permissions", message: "No permissions granted yet.")
                } else {
                    ForEach(scopeService.grantedScopes) { grant in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(grant.scopeIdentifier).font(.caption.monospaced()).bold()
                                Spacer()
                                if let app = appService.apps.first(where: { $0.id == grant.appID }) {
                                    Text(app.name).font(.caption2).foregroundStyle(.secondary)
                                } else {
                                    Text("Account").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            Text("Granted \(grant.grantDate.formatted(date: .abbreviated, time: .omitted))").font(.system(size: 8)).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { try? await scopeService.revokeScope(id: grant.id) }
                            } label: {
                                Label("Revoke", systemImage: "shield.xmark")
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
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(request.scopeIdentifier).font(.caption.monospaced())
                                Spacer()
                                Text(request.status.rawValue).font(.caption2.bold()).foregroundStyle(.orange)
                            }
                            Text(request.justification).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { try? await scopeService.cancelRequest(id: request.id) }
                            } label: {
                                Label("Cancel", systemImage: "xmark.circle")
                            }

                            Button {
                                Task { try? await scopeService.approveRequest(id: request.id) }
                            } label: {
                                Label("Approve", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                    }
                }
            }
        }
    }

    private var requestNewScopeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Request Scopes for:").font(.caption.bold()).foregroundStyle(.secondary)
                    Picker("App", selection: $selectedAppID) {
                        Text("Account Level").tag(Optional<UUID>.none)
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)

                SectionHeader(title: "Available Scopes", subtitle: nil, icon: nil)
                    .padding(.horizontal)

                ForEach(scopeService.catalog) { scope in
                    scopeCard(scope)
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
                riskBadge(scope.riskLevel)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(scope.name).font(.subheadline.bold())
                Text(scope.id).font(.caption2.monospaced()).foregroundStyle(.tertiary)
                Text(scope.description).font(.caption).foregroundStyle(.secondary)
            }

            if scope.riskLevel == .high || scope.riskLevel == .critical {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Justification Required").font(.caption.bold())
                    TextField("Briefly explain your use case...", text: Binding(
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
                    appId: selectedAppID ?? UUID(),
                    scopeIdentifier: scope.id,
                    justification: justifications[scope.id] ?? (scope.riskLevel == .low ? "Standard access" : "")
                )
                Task { try? await scopeService.submitRequest(request) }
            } label: {
                Text("Submit Request")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(canRequest(scope) ? Color.accentColor : Color.secondary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!canRequest(scope))
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func canRequest(_ scope: DeveloperScope) -> Bool {
        if scope.riskLevel == .high || scope.riskLevel == .critical {
            return (justifications[scope.id]?.count ?? 0) > 10
        }
        return true
    }

    private func riskBadge(_ risk: ScopeRiskLevel) -> some View {
        Text(risk.rawValue).font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(riskColor(risk).opacity(0.1), in: Capsule())
            .foregroundStyle(riskColor(risk))
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
                EmptyStateView(icon: "list.bullet.indent", title: "No Audit Events", message: "No audit events found.")
            } else {
                ForEach(scopeService.auditLog) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Circle().fill(event.eventType == "Grant" ? Color.green : (event.eventType == "Revoke" ? Color.red : Color.blue))
                            .frame(width: 8, height: 8).padding(.top, 4)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(event.eventType).font(.subheadline.bold())
                                Spacer()
                                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                            Text("scope: \(event.scopeIdentifier)").font(.caption2.monospaced()).foregroundStyle(.secondary)
                            if let app = appService.apps.first(where: { $0.id == event.appID }) {
                                Text("Project: \(app.name)").font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}
