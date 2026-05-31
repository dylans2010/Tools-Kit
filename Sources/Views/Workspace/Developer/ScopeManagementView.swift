import SwiftUI

struct ScopeManagementView: View {
    @ObservedObject var scopeService = DeveloperScopeService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedTab = 0
    @State private var justifications: [String: String] = [:]
    @State private var selectedAppID: UUID?
    @State private var showingTemplateSheet = false
    @State private var selectedScope: DeveloperScope?

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
        .toolbar {
            if selectedTab == 1 {
                Button { showingTemplateSheet = true } label: { Image(systemName: "rectangle.stack.badge.plus") }
            }
        }
        .sheet(isPresented: $showingTemplateSheet) {
            ScopeTemplatePickerView(selectedAppID: $selectedAppID)
        }
        .sheet(item: $selectedScope) { scope in
            ScopeDetailSheet(scope: scope)
        }
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

                HStack {
                    SectionHeader(title: "Available Scopes", subtitle: "Select scopes and provide justifications where required.", icon: nil)
                    Spacer()
                    NavigationLink(destination: ScopeRequestFormView()) {
                        Text("Custom Request").font(.caption.bold())
                    }
                }
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

            Button {
                selectedScope = scope
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(scope.name).font(.subheadline.bold())
                        Spacer()
                        Image(systemName: "info.circle").font(.caption).foregroundStyle(.secondary)
                    }
                    Text(scope.id).font(.caption2.monospaced()).foregroundStyle(.tertiary)
                    Text(scope.description).font(.caption).foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if scope.riskLevel == .high || scope.riskLevel == .critical {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill").foregroundStyle(.orange)
                        Text("Mandatory Justification").font(.caption.bold())
                    }
                    Text("This scope provides sensitive access. Explain why your app needs this functionality in detail.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    TextEditor(text: Binding(
                        get: { justifications[scope.id] ?? "" },
                        set: { justifications[scope.id] = $0 }
                    ))
                    .frame(height: 80)
                    .font(.caption)
                    .padding(4)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if (justifications[scope.id]?.count ?? 0) < 20 {
                        Text("\(20 - (justifications[scope.id]?.count ?? 0)) more characters required")
                            .font(.system(size: 8))
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.05))
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
            return (justifications[scope.id]?.count ?? 0) >= 20
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

struct ScopeTemplatePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedAppID: UUID?
    @ObservedObject var scopeService = DeveloperScopeService.shared

    let templates = [
        ScopeTemplate(name: "Basic Identity", description: "Read user profile and email.", scopes: ["user.read", "user.email"]),
        ScopeTemplate(name: "Data Analyst", description: "Read-only access to all data points.", scopes: ["data.read", "analytics.view"]),
        ScopeTemplate(name: "Full Admin", description: "Full read/write access to system resources.", scopes: ["user.write", "data.write", "system.manage"])
    ]

    var body: some View {
        NavigationStack {
            List(templates) { template in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(template.name).font(.headline)
                        Spacer()
                        Button("Apply") {
                            applyTemplate(template)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    Text(template.description).font(.caption).foregroundStyle(.secondary)
                    FlowLayout(template.scopes, spacing: 4) { scope in
                        Text(scope).font(.system(size: 8, design: .monospaced))
                            .padding(4)
                            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Scope Templates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func applyTemplate(_ template: ScopeTemplate) {
        for scopeID in template.scopes {
            let request = ScopeRequest(
                appId: selectedAppID ?? UUID(),
                scopeIdentifier: scopeID,
                justification: "Applied via \(template.name) template."
            )
            Task { try? await scopeService.submitRequest(request) }
        }
        dismiss()
    }
}

struct ScopeTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let scopes: [String]
}
