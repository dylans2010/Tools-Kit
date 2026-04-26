import SwiftUI

struct AgentConfigView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TabView {
                AgentConfigOverviewTab().tabItem { Label("Overview", systemImage: "gauge") }
                AgentConfigToolsTab().tabItem { Label("Tools", systemImage: "wrench") }
                AgentConfigLogsTab().tabItem { Label("Logs", systemImage: "doc.text") }
                AgentConfigMemoryTab().tabItem { Label("Memory", systemImage: "brain") }
                AgentConfigBenchmarkTab().tabItem { Label("Bench", systemImage: "chart.bar") }
                AgentConfigDemoTab().tabItem { Label("Demo", systemImage: "play.rectangle") }
                AgentConfigNetworkTab().tabItem { Label("Network", systemImage: "network") }
                AgentConfigExportTab().tabItem { Label("Export", systemImage: "square.and.arrow.up") }
            }
            .navigationTitle("Agent Config (Debug)")
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } } }
        }
    }
}
