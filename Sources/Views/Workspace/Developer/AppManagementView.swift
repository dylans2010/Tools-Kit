import SwiftUI

struct AppManagementView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var searchText = ""
    @State private var selectedType: DeveloperAppType?
    @State private var showingImportSheet = false
    @State private var appToDelete: DeveloperApp?
    @State private var showingDeleteAlert = false

    var filteredApps: [DeveloperApp] {
        appService.apps.filter { app in
            (searchText.isEmpty || app.name.localizedCaseInsensitiveContains(searchText) || app.bundleId.localizedCaseInsensitiveContains(searchText)) &&
            (selectedType == nil || app.type == selectedType)
        }
    }

    var body: some View {
        List {
            if !projectManager.projects.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles").foregroundStyle(.yellow)
                            Text("Import Projects").font(.subheadline.bold())
                        }
                        Text("We found \(projectManager.projects.count) SDK projects that can be registered as applications.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            showingImportSheet = true
                        } label: {
                            Text("Review SDK Projects")
                                .font(.caption.bold())
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.primary)
                                .foregroundStyle(Color(uiColor: .systemBackground))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Picker("Type", selection: $selectedType) {
                    Text("All Categories").tag(Optional<DeveloperAppType>.none)
                    ForEach(DeveloperAppType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(Optional(type))
                    }
                }
            }

            Section {
                if filteredApps.isEmpty {
                    EmptyStateView(icon: "square.stack.3d.up.slash", title: "No Applications", message: searchText.isEmpty ? "Register your first application to start managing its lifecycle." : "No applications match your search criteria.")
                        .padding(.vertical, 40)
                } else {
                    ForEach(filteredApps) { app in
                        NavigationLink(destination: AppDetailView(appID: app.id)) {
                            appRow(app)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                appToDelete = app
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search by name or bundle ID")
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
        .confirmationDialog("Delete Application", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
            Button("Delete \(appToDelete?.name ?? "App")", role: .destructive) {
                if let id = appToDelete?.id {
                    Task { try? await appService.deleteApp(id: id) }
                }
            }
        } message: {
            Text("This will permanently remove the application and all associated metadata. This action cannot be undone.")
        }
    }

    private func appRow(_ app: DeveloperApp) -> some View {
        HStack(spacing: 12) {
            Image(systemName: app.iconName)
                .font(.system(size: 20))
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).font(.subheadline.bold())
                Text("\(app.type.rawValue) • \(app.version)").font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge(app.status)
                Text(app.bundleId).font(.system(size: 8, design: .monospaced)).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private func statusBadge(_ status: DeveloperAppStatus) -> some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(statusColor(status).opacity(0.1))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
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
}
