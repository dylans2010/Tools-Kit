import SwiftUI

struct AppManagementView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var searchText = ""
    @State private var selectedType: DeveloperAppType?

    var filteredApps: [DeveloperApp] {
        appService.apps.filter { app in
            (searchText.isEmpty || app.name.localizedCaseInsensitiveContains(searchText) || app.bundleId.localizedCaseInsensitiveContains(searchText)) &&
            (selectedType == nil || app.type == selectedType)
        }
    }

    var body: some View {
        List {
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
