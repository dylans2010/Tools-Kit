import SwiftUI

struct AppManagementView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var searchText = ""
    @State private var selectedType: DeveloperAppType?

    var filteredApps: [DeveloperApp] {
        appService.apps.filter { app in
            (searchText.isEmpty || app.name.localizedCaseInsensitiveContains(searchText)) &&
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
                    VStack(spacing: 12) {
                        Image(systemName: "square.stack.3d.up.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No apps found. Register your first app to get started.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
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
        .searchable(text: $searchText, prompt: "Search apps")
        .navigationTitle("App Management")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: AppBuilderView()) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func appRow(_ app: DeveloperApp) -> some View {
        HStack {
            Image(systemName: app.iconName)
                .font(.title2)
                .foregroundStyle(.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).font(.subheadline.bold())
                Text("\(app.type.rawValue) • \(app.version)").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            statusBadge(app.status)
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: DeveloperAppStatus) -> some View {
        Text(status.rawValue).font(.caption2.bold())
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
