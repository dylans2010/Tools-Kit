import SwiftUI

struct AppManagementView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var searchText = ""
    @State private var selectedType: DeveloperAppType?
    @State private var showingImportSheet = false

    var filteredApps: [DeveloperApp] {
        appService.apps.filter { app in
            (searchText.isEmpty || app.name.localizedCaseInsensitiveContains(searchText) || app.bundleId.localizedCaseInsensitiveContains(searchText)) &&
            (selectedType == nil || app.type == selectedType)
        }
    }

    var body: some View {
        List {
            Section {
                if !projectManager.projects.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
                            Text("Import Existing Work").font(.subheadline.bold())
                        }
                        Text("We detected \(projectManager.projects.count) SDK projects. You can import them to manage as apps.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            showingImportSheet = true
                        } label: {
                            Text("Review SDK Projects")
                                .font(.caption.bold())
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Section {
                Picker("Filter by Type", selection: $selectedType) {
                    Text("All Types").tag(Optional<DeveloperAppType>.none)
                    ForEach(DeveloperAppType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(Optional(type))
                    }
                }
            }

            Section {
                if filteredApps.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.stack.3d.up.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(searchText.isEmpty ? "No apps registered." : "No apps match your search.")
                            .font(.headline)
                        Text("Register your app to manage its lifecycle, versions, and scopes.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        if searchText.isEmpty {
                            NavigationLink(destination: AppBuilderView()) {
                                Text("Register First App")
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(filteredApps) { app in
                        NavigationLink(destination: AppDetailView(appID: app.id)) {
                            appRow(app)
                        }
                    }
                    .onDelete(perform: deleteApps)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search apps by name or bundle ID")
        .navigationTitle("App Management")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: AppBuilderView()) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ProjectImportView()
        }
        .refreshable {
            appService.loadApps()
        }
    }

    private func appRow(_ app: DeveloperApp) -> some View {
        HStack(spacing: 12) {
            Image(systemName: app.iconName)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).font(.subheadline.bold())
                Text("\(app.type.rawValue) • \(app.version)").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge(app.status)
                if app.installCount > 0 {
                    Text("\(app.installCount) installs").font(.system(size: 8)).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
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
        case .live: return .green
        case .suspended: return .red
        case .deprecated: return .secondary
        case .archived: return .black
        }
    }

    private func deleteApps(at offsets: IndexSet) {
        for index in offsets {
            let app = filteredApps[index]
            Task {
                try? await appService.deleteApp(id: app.id)
            }
        }
    }
}

struct ProjectImportView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var projectManager = SDKProjectManager.shared
    @ObservedObject var appService = DeveloperAppService.shared

    var body: some View {
        NavigationStack {
            List(projectManager.projects) { project in
                HStack {
                    VStack(alignment: .leading) {
                        Text(project.name).font(.subheadline.bold())
                        Text("v\(project.version)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if appService.apps.contains(where: { $0.name == project.name }) {
                        Text("Imported").font(.caption2.bold()).foregroundStyle(.green)
                    } else {
                        Button("Import") {
                            importProject(project)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .navigationTitle("Import SDK Projects")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func importProject(_ project: SDKProject) {
        let newApp = DeveloperApp(
            name: project.name,
            type: .app,
            status: .draft,
            version: "\(project.version).0.0",
            description: project.description,
            bundleId: "com.sdk.\(project.id.uuidString.prefix(8).lowercased())",
            grantedScopes: project.enabledScopes
        )
        Task {
            try? await appService.createApp(newApp)
        }
    }
}
