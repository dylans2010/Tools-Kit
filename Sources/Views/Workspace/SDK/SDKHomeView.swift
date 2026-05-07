import SwiftUI

/// SDK Home View — overview of the entire SDK platform.
/// Shows active services, system status, quick actions, and module summaries.
struct SDKHomeView: View {
    @StateObject private var sdk = WorkspaceSDK.shared
    @StateObject private var kernel = WorkspaceSDKKernel.shared
    @StateObject private var mailService = SDKMailService.shared
    @StateObject private var notebookService = SDKNotebookService.shared
    @StateObject private var meetService = SDKMeetService.shared
    @StateObject private var articleService = SDKArticleService.shared
    @StateObject private var eventBus = SDKEventBus.shared
    @StateObject private var dataStore = SDKDataStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                kernelStatusCard
                servicesOverview
                featureModulesGrid
                recentEventsCard
                quickActionsCard
            }
            .padding()
        }
        .navigationTitle("WorkspaceSDK")
        .task {
            if !sdk.isInitialized {
                await sdk.initialize()
            }
        }
    }

    // MARK: - Kernel Status

    private var kernelStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cpu.fill")
                    .font(.title2)
                    .foregroundStyle(kernel.isReady ? .green : .orange)
                VStack(alignment: .leading) {
                    Text("WorkspaceSDK Kernel").font(.headline)
                    Text("v\(sdk.version)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(kernel.state.rawValue.capitalized)
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(kernel.isReady ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .foregroundStyle(kernel.isReady ? .green : .orange)
                    .clipShape(Capsule())
            }

            if kernel.isReady {
                let health = kernel.healthCheck()
                HStack(spacing: 16) {
                    miniStat("Uptime", value: formatUptime(health.uptime))
                    miniStat("Services", value: "\(health.registeredServices)")
                    miniStat("Plugins", value: "\(health.loadedPlugins)")
                    miniStat("Records", value: "\(dataStore.totalRecords)")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Services Overview

    private var servicesOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active Services", systemImage: "square.stack.3d.up.fill")
                .font(.headline)

            let services = ServiceContainer.shared.registeredServiceNames()
            if services.isEmpty {
                Text("No services registered").font(.caption).foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(services.sorted(), id: \.self) { service in
                        HStack {
                            Circle().fill(.green).frame(width: 6, height: 6)
                            Text(service.replacingOccurrences(of: "Protocol", with: ""))
                                .font(.system(size: 11, design: .monospaced))
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Feature Modules Grid

    private var featureModulesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Feature Modules", systemImage: "square.grid.2x2.fill")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                moduleCard("Mail", icon: "envelope.fill", color: .blue, count: mailService.messages.count, subtitle: "\(mailService.unreadCount) unread")
                moduleCard("Notebooks", icon: "book.fill", color: .purple, count: notebookService.notebooks.count, subtitle: "documents")
                moduleCard("Meet", icon: "video.fill", color: .green, count: meetService.sessions.count, subtitle: "sessions")
                moduleCard("Articles", icon: "doc.text.fill", color: .orange, count: articleService.articles.count, subtitle: "\(articleService.publishedCount) published")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Recent Events

    private var recentEventsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Events", systemImage: "bolt.fill")
                    .font(.headline)
                Spacer()
                Text("\(eventBus.totalEventsProcessed) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let recent = eventBus.recentEvents(limit: 5)
            if recent.isEmpty {
                Text("No events yet").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(recent) { event in
                    HStack {
                        Text(event.channel)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                        Text(event.name)
                            .font(.caption)
                        Spacer()
                        Text(event.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Quick Actions

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Actions", systemImage: "bolt.circle.fill")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                NavigationLink(destination: SDKAPIExplorerView()) {
                    quickAction("API Explorer", icon: "network", color: .blue)
                }
                NavigationLink(destination: SDKDataInspectorView()) {
                    quickAction("Data Inspector", icon: "cylinder.split.1x2.fill", color: .purple)
                }
                NavigationLink(destination: SDKPluginManagerView()) {
                    quickAction("Plugins", icon: "puzzlepiece.extension.fill", color: .green)
                }
                NavigationLink(destination: SDKDeveloperGuideView()) {
                    quickAction("Dev Guide", icon: "book.closed.fill", color: .orange)
                }
                NavigationLink(destination: SDKAppBuilderView()) {
                    quickAction("App Builder", icon: "hammer.fill", color: .red)
                }
                NavigationLink(destination: SDKControlCenterView()) {
                    quickAction("Control Center", icon: "gearshape.2.fill", color: .gray)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func moduleCard(_ title: String, icon: String, color: Color, count: Int, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
                Text("\(count)")
                    .font(.title2)
                    .bold()
            }
            Text(title).font(.subheadline).bold()
            Text(subtitle).font(.caption2).foregroundStyle(.secondary)
        }
        .padding()
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }

    private func quickAction(_ title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }

    private func miniStat(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(.caption, design: .monospaced)).bold()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }
}
