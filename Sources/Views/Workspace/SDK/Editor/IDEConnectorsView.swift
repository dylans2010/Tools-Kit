import SwiftUI

struct IDEConnectorsView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("External Integration").font(.headline)
                            Text("Manage connections to third-party APIs and services.").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        SDKStatusPill("ACTIVE", systemImage: "bolt.horizontal.fill", color: .green)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("Connectors", subtitle: "External federation", systemImage: "link.badge.plus")
            }

            Section("Available Connectors") {
                connectorRow(name: "GitHub API", description: "Repository and workflow integration", status: "Connected", icon: "github.logo")
                connectorRow(name: "Slack Webhooks", description: "Channel notifications and interactivity", status: "Configured", icon: "bubble.left.and.bubble.right")
                connectorRow(name: "AWS Lambda", description: "Serverless execution bridge", status: "Not Setup", icon: "cloud.fill")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Connectors")
    }

    private func connectorRow(name: String, description: String, status: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon.contains(".") ? "app.badge" : icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.headline)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Text(status)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status == "Connected" ? Color.green.opacity(0.1) : Color.secondary.opacity(0.1), in: Capsule())
                .foregroundStyle(status == "Connected" ? .green : .secondary)
        }
        .padding(.vertical, 4)
    }
}
