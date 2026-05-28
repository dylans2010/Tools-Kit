import SwiftUI

struct AppManagementView: View {
    @State private var searchText = ""
    @State private var statusFilter: AppStatus?
    @State private var typeFilter: AppType?
    @State private var showingCreateSheet = false

    @State private var apps: [DeveloperApp] = [
        DeveloperApp(name: "GitHub Pro", type: .connector, status: .live, version: "2.1.0", installCount: 850, revenue: 420.0),
        DeveloperApp(name: "Mail AI Bot", type: .plugin, status: .underReview, version: "1.0.4", installCount: 0),
        DeveloperApp(name: "Internal Metrics", type: .service, status: .draft, version: "0.1.0"),
        DeveloperApp(name: "Legacy Sync", type: .service, status: .deprecated, version: "0.5.0", installCount: 120),
        DeveloperApp(name: "Metal Shaders", type: .sdkExtension, status: .live, version: "1.2.0", installCount: 340)
    ]

    var filteredApps: [DeveloperApp] {
        apps.filter { app in
            (searchText.isEmpty || app.name.localizedCaseInsensitiveContains(searchText)) &&
            (statusFilter == nil || app.status == statusFilter) &&
            (typeFilter == nil || app.type == typeFilter)
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(filteredApps) { app in
                    NavigationLink(destination: AppDetailView(app: app)) {
                        appRow(app)
                    }
                }
            } header: {
                HStack {
                    Text("\(filteredApps.count) Projects")
                    Spacer()
                    Menu {
                        Picker("Status", selection: $statusFilter) {
                            Text("All Statuses").tag(Optional<AppStatus>.none)
                            ForEach(AppStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(Optional(status))
                            }
                        }
                        Picker("Type", selection: $typeFilter) {
                            Text("All Types").tag(Optional<AppType>.none)
                            ForEach(AppType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(Optional(type))
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .navigationTitle("App Management")
        .searchable(text: $searchText, prompt: "Search apps, plugins, connectors")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            MarketplaceSubmissionView()
        }
    }

    private func appRow(_ app: DeveloperApp) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1))
                Image(systemName: app.iconName)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(app.name).font(.subheadline.bold())
                    Text("v\(app.version)").font(.caption2).foregroundStyle(.tertiary)
                }
                HStack(spacing: 6) {
                    Text(app.type.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1), in: Capsule())

                    Text(app.status.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(app.status.color)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(app.installCount)").font(.subheadline.bold())
                Text("Installs").font(.system(size: 8)).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
