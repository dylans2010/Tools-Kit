import SwiftUI

struct AppDetailView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var keyService = APIKeyService.shared
    @ObservedObject var scopeService = DeveloperScopeService.shared

    @State private var selectedTab = 0
    @State private var showingStatusSheet = false
    @State private var showingAddVersion = false
    @State private var showingTransferOwnership = false

    @State private var newStatus: DeveloperAppStatus = .draft
    @State private var statusReason = ""
    @State private var newVersionNumber = ""
    @State private var newBuildNumber = ""
    @State private var newReleaseNotes = ""
    @State private var transferEmail = ""

    var app: DeveloperApp? {
        appService.apps.first { $0.id == appID }
    }

    var body: some View {
        Group {
            if let app = app {
                ScrollView {
                    VStack(spacing: 24) {
                        appHeader(app)

                        Picker("Details", selection: $selectedTab) {
                            Text("Overview").tag(0)
                            Text("Lifecycle").tag(1)
                            Text("Security").tag(2)
                            Text("Infrastructure").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        VStack(spacing: 0) {
                            switch selectedTab {
                            case 0: overviewTab(app)
                            case 1: lifecycleTab(app)
                            case 2: securityTab(app)
                            case 3: infrastructureTab(app)
                            default: Color.clear
                            }
                        }
                    }
                }
            } else {
                EmptyStateView(icon: "exclamationmark.triangle", title: "App Not Found", message: "The requested application could not be found in the registry.")
            }
        }
        .navigationTitle("App Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if let app = app {
                        newStatus = app.status
                        showingStatusSheet = true
                    }
                } label: {
                    Text("Status").font(.subheadline.bold())
                }
            }
        }
        .sheet(isPresented: $showingStatusSheet) { statusUpdateSheet }
        .sheet(isPresented: $showingAddVersion) { addVersionSheet }
        .sheet(isPresented: $showingTransferOwnership) { transferOwnershipSheet }
    }

    private func appHeader(_ app: DeveloperApp) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.03))
                Image(systemName: app.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).font(.headline)
                Text(app.bundleId).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Text(app.type.rawValue).font(.system(size: 9, weight: .bold)).textCase(.uppercase).foregroundStyle(.secondary)
                    Circle().fill(Color.secondary.opacity(0.3)).frame(width: 3, height: 3)
                    statusBadge(app.status)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .padding(.horizontal)
    }

    private func statusBadge(_ status: DeveloperAppStatus) -> some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 8, weight: .black))
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: DeveloperAppStatus) -> Color {
        switch status {
        case .live: return .green
        case .underReview: return .orange
        case .suspended: return .red
        default: return .secondary
        }
    }

    private func overviewTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            infoSection(app)

            SectionHeader(title: "Compliance & Management", subtitle: nil, icon: nil)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: PrivacyManifestEditorView()) {
                    toolTile(title: "Privacy Manifest", icon: "hand.raised.fill", description: "Audit scope justifications")
                }
                NavigationLink(destination: AppBundleValidatorView()) {
                    toolTile(title: "Bundle Validator", icon: "checkmark.seal.fill", description: "Verify package integrity")
                }
                NavigationLink(destination: DataHandlingPolicyBuilderView()) {
                    toolTile(title: "Data Policies", icon: "doc.text.magnifyingglass", description: "Manage retention policies")
                }
                NavigationLink(destination: DeveloperMonetizationView()) {
                    toolTile(title: "Monetization", icon: "dollarsign.circle.fill", description: "Revenue & pricing config")
                }
            }

            SectionHeader(title: "Targets", subtitle: nil, icon: nil)
            FlowLayout(app.platformTargets, spacing: 8) { target in
                Text(target.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.primary.opacity(0.05), in: Capsule())
            }
        }
        .padding()
    }

    private func lifecycleTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                SectionHeader(title: "Version History", subtitle: nil, icon: nil)
                Spacer()
                Button { showingAddVersion = true } label: {
                    Label("Add Version", systemImage: "plus.circle.fill").font(.caption.bold())
                }
            }

            ForEach(app.versions.sorted(by: { $0.createdAt > $1.createdAt })) { version in
                versionRow(version)
            }

            SectionHeader(title: "Release Operations", subtitle: nil, icon: nil)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: DeveloperReleaseManagementView()) {
                    toolTile(title: "Releases", icon: "shippingbox.fill", description: "Manage rollout cycles")
                }
                NavigationLink(destination: DeveloperBetaTestingView()) {
                    toolTile(title: "Beta Testing", icon: "person.3.sequence.fill", description: "Invite external testers")
                }
                NavigationLink(destination: AppVersionHistoryView()) {
                    toolTile(title: "All Versions", icon: "clock.arrow.circlepath", description: "Full historical audit")
                }
                NavigationLink(destination: DeveloperDeploymentPipelineView()) {
                    toolTile(title: "Pipelines", icon: "hammer.fill", description: "CI/CD execution status")
                }
            }
        }
        .padding()
    }

    private func securityTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Authentication & Keys", subtitle: nil, icon: nil)

            let appKeys = keyService.keys.filter { $0.appID == app.id }
            if appKeys.isEmpty {
                Text("No API keys assigned to this project.").font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            } else {
                ForEach(appKeys) { key in
                    keyRow(key)
                }
            }

            SectionHeader(title: "Permissions", subtitle: nil, icon: nil)
            NavigationLink(destination: ScopeManagementView()) {
                HStack {
                    Label("\(app.grantedScopes.count) Scopes Granted", systemImage: "shield.fill")
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption2)
                }
                .font(.subheadline.bold())
                .padding()
                .background(Color.accentColor.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            SectionHeader(title: "Security Tools", subtitle: nil, icon: nil)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: DeveloperSecretsManagerView()) {
                    toolTile(title: "Secrets", icon: "lock.rectangle.fill", description: "Secure env variables")
                }
                NavigationLink(destination: DeveloperAppCertificatesView()) {
                    toolTile(title: "Certificates", icon: "doc.badge.gearshape.fill", description: "Provisioning profiles")
                }
                NavigationLink(destination: DeveloperSecurityAuditView()) {
                    toolTile(title: "Security Audit", icon: "checkmark.shield.fill", description: "Compliance scan reports")
                }
                NavigationLink(destination: AuthServiceManagerView()) {
                    toolTile(title: "Auth Settings", icon: "key.fill", description: "Global auth config")
                }
            }
        }
        .padding()
    }

    private func infrastructureTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Environment Management", subtitle: nil, icon: nil)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: AppEnvironmentsView()) {
                    toolTile(title: "Environments", icon: "square.stack.3d.down.right.fill", description: "Base URL & configs")
                }
                NavigationLink(destination: DeveloperSandboxEnvironmentView()) {
                    toolTile(title: "Sandbox", icon: "square.dashed", description: "Testing isolated state")
                }
                NavigationLink(destination: WebhookManagerView()) {
                    toolTile(title: "Webhooks", icon: "bolt.horizontal.fill", description: "Event delivery endpoints")
                }
                NavigationLink(destination: DeveloperDatabaseManagerView()) {
                    toolTile(title: "Database", icon: "tablecells.fill", description: "Schema & data explorer")
                }
            }

            SectionHeader(title: "Observability", subtitle: nil, icon: nil)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: DeveloperLogsView()) {
                    toolTile(title: "System Logs", icon: "list.bullet.rectangle.fill", description: "Real-time log stream")
                }
                NavigationLink(destination: AnalyticsDashboardView()) {
                    toolTile(title: "Analytics", icon: "chart.xyaxis.line", description: "Usage & trend metrics")
                }
                NavigationLink(destination: DeveloperCrashReportView()) {
                    toolTile(title: "Crash Reports", icon: "heart.text.square.fill", description: "Symbolicated stack traces")
                }
                NavigationLink(destination: DeveloperPerformanceMonitorView()) {
                    toolTile(title: "Performance", icon: "gauge.with.needle.fill", description: "latency & resource usage")
                }
            }

            SectionHeader(title: "Operations", subtitle: nil, icon: nil)
            VStack(spacing: 12) {
                NavigationLink(destination: AppCollaboratorsView(appID: app.id)) {
                    HStack {
                        Label("Team & Collaborators", systemImage: "person.2.fill")
                        Spacer()
                        Text("\(app.collaborators.count)").font(.caption.bold()).padding(.horizontal, 8).padding(.vertical, 2).background(Color.primary.opacity(0.1), in: Capsule())
                    }
                    .font(.subheadline.bold())
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(role: .destructive) { showingTransferOwnership = true } label: {
                    Label("Transfer Ownership", systemImage: "person.2.badge.key.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.red.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
    }

    private func infoSection(_ app: DeveloperApp) -> some View {
        VStack(spacing: 1) {
            infoRow(label: "Description", value: app.description)
            infoRow(label: "Version", value: app.version)
            infoRow(label: "Bundle", value: app.bundleId)
            infoRow(label: "Created", value: app.createdAt.formatted(date: .abbreviated, time: .omitted))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            Spacer()
            Text(value.isEmpty ? "—" : value).font(.system(size: 13))
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private func toolTile(title: String, icon: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .bold))
                Text(description).font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func versionRow(_ version: AppVersion) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("v\(version.version)").font(.subheadline.bold())
                Text(version.createdAt.formatted(date: .abbreviated, time: .omitted)).font(.system(size: 9)).foregroundStyle(.tertiary)
            }
            Spacer()
            Text(version.status.uppercased()).font(.system(size: 8, weight: .black)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.primary.opacity(0.05), in: Capsule())
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func keyRow(_ key: APIKey) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(key.label).font(.subheadline.bold())
                Text(key.maskedValue).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
            }
            Spacer()
            Text(key.environment.rawValue.uppercased()).font(.system(size: 8, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2).background(key.environment == .live ? Color.green.opacity(0.1) : Color.orange.opacity(0.1)).foregroundStyle(key.environment == .live ? .green : .orange).clipShape(Capsule())
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusUpdateSheet: some View {
        NavigationStack {
            Form {
                Section("Target Status") {
                    Picker("New Status", selection: $newStatus) {
                        ForEach(DeveloperAppStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    TextEditor(text: $statusReason)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if statusReason.isEmpty { Text("Provide a reason...").font(.caption).foregroundStyle(.tertiary).padding(.top, 8).padding(.leading, 4) }
                        }
                }
            }
            .navigationTitle("Update Status")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingStatusSheet = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        Task {
                            try? await appService.transitionStatus(id: appID, newStatus: newStatus, reason: statusReason)
                            await MainActor.run { showingStatusSheet = false; statusReason = "" }
                        }
                    }
                }
            }
        }
    }

    private var addVersionSheet: some View {
        NavigationStack {
            Form {
                Section("Version Information") {
                    TextField("Version Number", text: $newVersionNumber, prompt: Text("e.g. 1.0.1"))
                    TextField("Build Number", text: $newBuildNumber)
                    TextEditor(text: $newReleaseNotes)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if newReleaseNotes.isEmpty { Text("What's new?").font(.caption).foregroundStyle(.tertiary).padding(.top, 8).padding(.leading, 4) }
                        }
                }
            }
            .navigationTitle("New Version")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddVersion = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let v = AppVersion(version: newVersionNumber, buildNumber: newBuildNumber, releaseNotes: newReleaseNotes)
                        Task {
                            try? await appService.addVersion(appID: appID, version: v)
                            await MainActor.run { showingAddVersion = false; newVersionNumber = ""; newBuildNumber = ""; newReleaseNotes = "" }
                        }
                    }
                    .disabled(newVersionNumber.isEmpty || newBuildNumber.isEmpty)
                }
            }
        }
    }

    private var transferOwnershipSheet: some View {
        NavigationStack {
            Form {
                Section("Recipient Email") {
                    TextField("Email Address", text: $transferEmail).keyboardType(.emailAddress).autocapitalization(.none)
                    Text("This will grant 'Owner' permissions to the recipient.").font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Transfer Ownership")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingTransferOwnership = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Transfer") {
                        Task {
                            try? await appService.transferOwnership(appID: appID, toEmail: transferEmail)
                            await MainActor.run { showingTransferOwnership = false; transferEmail = "" }
                        }
                    }
                    .disabled(transferEmail.isEmpty)
                }
            }
        }
    }
}
