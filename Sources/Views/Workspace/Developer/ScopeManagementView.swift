import SwiftUI

struct ScopeManagementView: View {
    @ObservedObject var scopeService = DeveloperScopeService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedTab = 0
    @State private var justifications: [String: String] = [:]
    @State private var selectedAppID: UUID?
    @State private var showingTemplateSheet = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedTab) {
                Text("Granted").tag(0)
                Text("Catalog").tag(1)
                Text("Audit").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                myGrantedScopesList
            } else if selectedTab == 1 {
                requestNewScopeView
            } else {
                ScopeAuditLogView()
            }
        }
        .navigationTitle("Permissions")
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar {
            if selectedTab == 1 {
                Button { showingTemplateSheet = true } label: { Image(systemName: "rectangle.stack.badge.plus") }
            }
        }
        .sheet(isPresented: $showingTemplateSheet) {
            ScopeTemplatesView()
        }
    }

    private var myGrantedScopesList: some View {
        List {
            Section("Active Privileges") {
                if scopeService.grantedScopes.isEmpty {
                    EmptyStateView(icon: "shield.slash", title: "No Permissions", message: "No security scopes have been granted to your account or projects.")
                } else {
                    ForEach(scopeService.grantedScopes) { grant in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(grant.scopeIdentifier).font(.subheadline.monospaced()).bold()
                                Spacer()
                                if let app = appService.apps.first(where: { $0.id == grant.appID }) {
                                    Text(app.name).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                                } else {
                                    Text("ACCOUNT").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
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

            Section("Pending Approvals") {
                if scopeService.pendingRequests.isEmpty {
                    Text("No pending requests.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(scopeService.pendingRequests) { request in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(request.scopeIdentifier).font(.caption.monospaced()).bold()
                                Spacer()
                                Text(request.status.rawValue.uppercased()).font(.system(size: 8, weight: .black)).foregroundStyle(.orange)
                            }
                            Text(request.justification).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
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
                    Text("Target Resource").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
                    Picker("App", selection: $selectedAppID) {
                        Text("Global Account").tag(Optional<UUID>.none)
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)

                SectionHeader(title: "Permissions Catalog", subtitle: "Select scopes and provide mandatory justifications.", icon: "shield.fill")
                    .padding(.horizontal)

                ForEach(scopeService.catalog) { scope in
                    scopeCard(scope)
                }
            }
            .padding(.vertical)
        }
    }

    private func scopeCard(_ scope: DeveloperScope) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(scope.category.rawValue.uppercased()).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                Spacer()
                riskBadge(scope.riskLevel)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(scope.name).font(.subheadline.bold())
                Text(scope.id).font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
                Text(scope.description).font(.system(size: 12)).foregroundStyle(.secondary)
            }

            if scope.riskLevel == .high || scope.riskLevel == .critical {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill").foregroundStyle(.orange).font(.caption)
                        Text("Mandatory Audit Justification").font(.system(size: 10, weight: .bold))
                    }

                    TextEditor(text: Binding(
                        get: { justifications[scope.id] ?? "" },
                        set: { justifications[scope.id] = $0 }
                    ))
                    .frame(height: 80)
                    .font(.system(size: 13))
                    .padding(4)
                    .background(Color.primary.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if (justifications[scope.id]?.count ?? 0) < 20 {
                        Text("\(20 - (justifications[scope.id]?.count ?? 0)) characters remaining")
                            .font(.system(size: 8))
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                submitRequest(scope)
            } label: {
                Text("Submit Request")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(canRequest(scope) ? Color.accentColor : Color.secondary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!canRequest(scope))
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .padding(.horizontal)
    }

    private func submitRequest(_ scope: DeveloperScope) {
        let request = ScopeRequest(
            appId: selectedAppID ?? UUID(),
            scopeIdentifier: scope.id,
            justification: justifications[scope.id] ?? "Standard access request."
        )
        Task {
            try? await scopeService.submitRequest(request)
            await MainActor.run { justifications[scope.id] = "" }
        }
    }

    private func canRequest(_ scope: DeveloperScope) -> Bool {
        if scope.riskLevel == .high || scope.riskLevel == .critical {
            return (justifications[scope.id]?.count ?? 0) >= 20
        }
        return true
    }

    private func riskBadge(_ risk: ScopeRiskLevel) -> some View {
        Text(risk.rawValue.uppercased())
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(riskColor(risk).opacity(0.1))
            .foregroundStyle(riskColor(risk))
            .clipShape(Capsule())
    }

    private func riskColor(_ risk: ScopeRiskLevel) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}
