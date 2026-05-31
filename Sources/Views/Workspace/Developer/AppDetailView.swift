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
                            Text("Versions").tag(1)
                            Text("Scopes").tag(2)
                            Text("Security").tag(3)
                            Text("More").tag(4)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        VStack(spacing: 0) {
                            switch selectedTab {
                            case 0:
                                overviewTab(app)
                            case 1:
                                versionsTab(app)
                            case 2:
                                scopesTab(app)
                            case 3:
                                securityTab(app)
                            case 4:
                                moreTab(app)
                            default:
                                Color.clear
                            }
                        }
                        .transition(.opacity)
                    }
                    .padding(.bottom, 32)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(.secondary)
                    Text("App Not Found").font(.headline)
                    Text("This project may have been deleted or moved.").font(.subheadline).foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
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
        .sheet(isPresented: $showingAddVersion) {
            addVersionSheet
        }
        .sheet(isPresented: $showingTransferOwnership) {
            transferOwnershipSheet
        }
    }

    private func appHeader(_ app: DeveloperApp) -> some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.primary.opacity(0.05))
                Image(systemName: app.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(.primary)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.title3.bold())
                Text(app.bundleId).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Text(app.type.rawValue).font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.primary.opacity(0.05), in: Capsule())
                    statusBadge(app.status)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func statusBadge(_ status: DeveloperAppStatus) -> some View {
        Text(status.rawValue.uppercased()).font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.primary.opacity(status == .live ? 0.8 : 0.1), in: Capsule())
            .foregroundStyle(status == .live ? .white : .primary)
    }

    private func overviewTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Project Information", subtitle: nil, icon: nil)

            VStack(spacing: 12) {
                infoRow(label: "Description", value: app.description)
                infoRow(label: "Current Version", value: app.version)
                infoRow(label: "Installs", value: "\(app.installCount)")
                infoRow(label: "Monetization", value: app.monetizationModel.rawValue)
                infoRow(label: "Created", value: app.createdAt.formatted(date: .abbreviated, time: .omitted))
            }

            SectionHeader(title: "Management & Compliance", subtitle: nil, icon: nil)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: AppEnvironmentsView()) {
                    toolLink(title: "Environments", icon: "square.stack.3d.down.right")
                }
                NavigationLink(destination: PrivacyManifestEditorView()) {
                    toolLink(title: "Privacy Manifest", icon: "hand.raised")
                }
                NavigationLink(destination: AppBundleValidatorView()) {
                    toolLink(title: "Bundle Validator", icon: "checkmark.seal")
                }
                NavigationLink(destination: AppVersionHistoryView()) {
                    toolLink(title: "Version History", icon: "clock.arrow.circlepath")
                }
                NavigationLink(destination: DeveloperIncidentManagerView()) {
                    toolLink(title: "Incidents", icon: "exclamationmark.triangle")
                }
                NavigationLink(destination: FunnelBuilderView()) {
                    toolLink(title: "Funnels", icon: "filter")
                }
            }
        }
        .padding()
    }

    private func toolLink(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).font(.caption).foregroundStyle(.secondary)
            Text(title).font(.system(size: 11, weight: .medium))
            Spacer()
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func versionsTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                SectionHeader(title: "Release History", subtitle: nil, icon: nil)
                Spacer()
                Button {
                    showingAddVersion = true
                } label: {
                    Label("New Version", systemImage: "plus")
                        .font(.caption.bold())
                }
            }

            if app.versions.isEmpty {
                EmptyStateView(icon: "shippingbox", title: "No Versions", message: "No versions released yet.")
            } else {
                ForEach(app.versions.sorted(by: { $0.createdAt > $1.createdAt })) { version in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("v\(version.version)").font(.subheadline.bold())
                            Text("(\(version.buildNumber))").font(.caption).monospaced().foregroundStyle(.secondary)
                            Spacer()
                            Text(version.status.uppercased()).font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.primary.opacity(0.05), in: Capsule())
                        }
                        if !version.releaseNotes.isEmpty {
                            Text(version.releaseNotes).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                        }
                        Text(version.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding()
    }

    private func scopesTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Active Permissions", subtitle: nil, icon: nil)

            if app.grantedScopes.isEmpty {
                EmptyStateView(icon: "shield.slash", title: "No Permissions", message: "No permissions granted yet.")
            } else {
                ForEach(app.grantedScopes, id: \.self) { scopeID in
                    if let scope = scopeService.fetchScope(identifier: scopeID) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(scope.name).font(.subheadline.bold())
                                Text(scope.id).font(.caption2.monospaced()).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.shield").foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }

            NavigationLink(destination: ScopeManagementView()) {
                Label("Request Permissions", systemImage: "shield")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary.opacity(0.05))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
    }

    private func securityTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Identity & Security", subtitle: nil, icon: nil)

            let assignedKeys = keyService.keys.filter { $0.appID == app.id }

            if assignedKeys.isEmpty {
                EmptyStateView(icon: "key.slash", title: "No API Keys", message: "No API keys assigned to this project.")
            } else {
                ForEach(assignedKeys) { key in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key.label).font(.subheadline.bold())
                            Text(key.maskedValue).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(key.environment.rawValue.uppercased()).font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.primary.opacity(0.05), in: Capsule())
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            VStack(spacing: 12) {
                NavigationLink(destination: AuthServiceManagerView()) {
                    Label("Manage API Keys", systemImage: "key")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                NavigationLink(destination: DeveloperAppCertificatesView()) {
                    Label("Certificates", systemImage: "doc.badge.gearshape")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary.opacity(0.05))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding()
    }

    private func moreTab(_ app: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                SectionHeader(title: "Collaborators", subtitle: nil, icon: nil)
                Spacer()
                NavigationLink(destination: AppCollaboratorsView(appID: app.id)) {
                    Text("Manage").font(.caption.bold())
                }
            }
            if app.collaborators.isEmpty {
                Text("You are the sole owner of this project.").font(.caption).foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(app.collaborators) { collab in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(collab.name).font(.subheadline.bold())
                            Text(collab.email).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(collab.role).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            Divider()

            SectionHeader(title: "Commercial & Advanced", subtitle: nil, icon: nil)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: DeveloperMonetizationView()) {
                    toolLink(title: "Monetization", icon: "dollarsign.circle")
                }
                NavigationLink(destination: CustomEventManagerView()) {
                    toolLink(title: "Custom Events", icon: "bolt")
                }
            }

            Divider()

            SectionHeader(title: "Danger Zone", subtitle: nil, icon: nil)
            VStack(spacing: 12) {
                NavigationLink(destination: TransferOwnershipView()) {
                    Label("Transfer Ownership", systemImage: "person.2.badge.key")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.red.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    Task {
                        try? await appService.deleteApp(id: app.id)
                    }
                } label: {
                    Label("Delete Project", systemImage: "trash")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.red.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
    }

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.bold()).foregroundStyle(.secondary)
            Text(value.isEmpty ? "—" : value).font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var addVersionSheet: some View {
        NavigationStack {
            Form {
                Section("New Version Details") {
                    TextField("Version Number", text: $newVersionNumber)
                    TextField("Build Number", text: $newBuildNumber)
                    VStack(alignment: .leading) {
                        Text("Release Notes").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $newReleaseNotes).frame(height: 100)
                    }
                }
            }
            .navigationTitle("Add Version")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddVersion = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let version = AppVersion(version: newVersionNumber, buildNumber: newBuildNumber, releaseNotes: newReleaseNotes)
                        Task {
                            try? await appService.addVersion(appID: appID, version: version)
                            await MainActor.run {
                                showingAddVersion = false
                                newVersionNumber = ""
                                newBuildNumber = ""
                                newReleaseNotes = ""
                            }
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
                Section("Recipient") {
                    TextField("Recipient Email", text: $transferEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Transfer Ownership")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingTransferOwnership = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Transfer") {
                        Task {
                            try? await appService.transferOwnership(appID: appID, toEmail: transferEmail)
                            await MainActor.run {
                                showingTransferOwnership = false
                                transferEmail = ""
                            }
                        }
                    }
                    .disabled(transferEmail.isEmpty)
                }
            }
        }
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
