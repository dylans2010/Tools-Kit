import SwiftUI

struct AppDetailView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var keyService = APIKeyService.shared
    @ObservedObject var scopeService = DeveloperScopeService.shared
    @State private var selectedTab = 0
    @State private var showingStatusSheet = false
    @State private var newStatus: DeveloperAppStatus = .draft
    @State private var statusReason = ""

    var app: DeveloperApp? {
        appService.apps.first { $0.id == appID }
    }

    var body: some View {
        Group {
            if let app = app {
                ScrollView {
                    VStack(spacing: 20) {
                        appHeader(app)

                        Picker("Details", selection: $selectedTab) {
                            Text("Overview").tag(0)
                            Text("Technical").tag(1)
                            Text("Auth").tag(2)
                            Text("Management").tag(3)
                            Text("Admin").tag(4)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        VStack(spacing: 0) {
                            switch selectedTab {
                            case 0:
                                overviewTab(app)
                            case 1:
                                technicalTab(app)
                            case 2:
                                authTab(app)
                            case 3:
                                managementTab(app)
                            case 4:
                                adminTab(app)
                            default:
                                Color.clear
                            }
                        }
                        .transition(.opacity)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(.orange)
                    Text("App Not Found").font(.headline)
                    Text("This project may have been deleted or moved.").font(.subheadline).foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle("App Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Update Status") {
                    if let app = app {
                        newStatus = app.status
                        showingStatusSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingStatusSheet) {
            statusUpdateSheet
        }
    }

    private func appHeader(_ app: DeveloperApp) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.accentColor.opacity(0.1))
                Image(systemName: app.iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.title3.bold())
                Text(app.bundleId).font(.caption).monospaced().foregroundStyle(.secondary)
                HStack {
                    Text(app.type.rawValue).font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1), in: Capsule())
                    statusBadge(app.status)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func statusBadge(_ status: DeveloperAppStatus) -> some View {
        Text(status.rawValue).font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(statusColor(status).opacity(0.1), in: Capsule())
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: DeveloperAppStatus) -> Color {
        switch status {
        case .draft: return .gray
        case .underReview: return .orange
        case .live: return .sdkSuccess
        case .suspended: return .sdkError
        case .deprecated: return .secondary
        case .archived: return .black
        }
    }

    private func overviewTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Project Information", subtitle: nil, icon: nil)

            VStack(spacing: 12) {
                infoRow(label: "Description", value: app.description)
                infoRow(label: "Current Version", value: app.version)
                infoRow(label: "Installs", value: "\(app.installCount)")
                infoRow(label: "Monetization", value: app.monetizationModel.rawValue)
                infoRow(label: "Created", value: app.createdAt.formatted(date: .abbreviated, time: .omitted))
            }

            SectionHeader(title: "Platform Targets", subtitle: nil, icon: nil)
            FlowLayout(app.platformTargets, spacing: 8) { target in
                Text(target.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.1), in: Capsule())
            }
        }
        .padding()
    }

    private func technicalTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Technical Tools", subtitle: nil, icon: nil)

            NavigationLink(destination: AppBundleValidatorView(appID: app.id)) {
                toolRow(title: "Bundle Validator", icon: "checkmark.seal", color: .blue)
            }
            NavigationLink(destination: AppVersionHistoryView(appID: app.id)) {
                toolRow(title: "Version History", icon: "clock.arrow.circlepath", color: .orange)
            }
            NavigationLink(destination: PrivacyManifestEditorView(appID: app.id)) {
                toolRow(title: "Privacy Manifest", icon: "hand.raised.fill", color: .red)
            }
            NavigationLink(destination: DataHandlingPolicyBuilderView(appID: app.id)) {
                toolRow(title: "Data Policy Builder", icon: "doc.text.fill", color: .purple)
            }
            NavigationLink(destination: AppEnvironmentsView(appID: app.id)) {
                toolRow(title: "Environments", icon: "server.rack", color: .mint)
            }
        }
        .padding()
    }

    private func authTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Permissions & Keys", subtitle: nil, icon: nil)

            let assignedKeys = keyService.keys.filter { $0.appID == app.id }

            if assignedKeys.isEmpty {
                EmptyStateView(icon: "key.slash", title: "No API Keys", message: "No API keys assigned to this project.")
            } else {
                ForEach(assignedKeys) { key in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(key.label).font(.subheadline.bold())
                            Text(key.maskedValue).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(key.environment.rawValue).font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(key.environment == .live ? Color.sdkSuccess.opacity(0.1) : Color.sdkWarning.opacity(0.1))
                            .foregroundStyle(key.environment == .live ? .sdkSuccess : .sdkWarning)
                            .clipShape(Capsule())
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            NavigationLink(destination: ScopeManagementView()) {
                Label("Manage Scopes", systemImage: "shield.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }

    private func managementTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "App Operations", subtitle: nil, icon: nil)

            NavigationLink(destination: AppCollaboratorsView(appID: app.id)) {
                toolRow(title: "Collaborators", icon: "person.2.fill", color: .blue)
            }
            NavigationLink(destination: MarketplaceSubmissionView(appID: app.id)) {
                toolRow(title: "Marketplace Listing", icon: "storefront.fill", color: .teal)
            }
        }
        .padding()
    }

    private func adminTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Danger Zone", subtitle: nil, icon: nil)
            VStack(spacing: 12) {
                Button(role: .destructive) {
                    // Transfer ownership
                } label: {
                    Label("Transfer Ownership", systemImage: "person.2.badge.key")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    Task {
                        try? await appService.deleteApp(id: app.id)
                    }
                } label: {
                    Label("Delete Project", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private func toolRow(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).frame(width: 24)
            Text(title).font(.subheadline)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.bold()).foregroundStyle(.secondary)
            Text(value.isEmpty ? "—" : value).font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusUpdateSheet: some View {
        NavigationStack {
            Form {
                Section("Update Project Status") {
                    Picker("New Status", selection: $newStatus) {
                        ForEach(DeveloperAppStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Reason for change").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $statusReason)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("Project Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingStatusSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        Task {
                            try? await appService.transitionStatus(id: appID, newStatus: newStatus, reason: statusReason)
                            await MainActor.run {
                                showingStatusSheet = false
                                statusReason = ""
                            }
                        }
                    }
                }
            }
        }
    }
}
