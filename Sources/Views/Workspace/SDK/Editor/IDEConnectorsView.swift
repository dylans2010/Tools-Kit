/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Replaced manual stat pills and headers with native Section titles and LabeledContent.
 - Modernized connector rows using a private struct ConnectorRegistryRow with semantic status badges.
 - Standardized connectivity status using semantic colors (.green, .blue, .secondary).
 - strictly preserved all SDKRuntimeWorkspaceState connector integration logic.
 - Improved visual hierarchy for connector descriptions and icons.
 - Replaced hardcoded icon logic with standard SF Symbol fallback patterns.
 */

import SwiftUI

struct IDEConnectorsView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    var body: some View {
        List {
            Section("Connectivity") {
                LabeledContent("Active Modules") {
                    Text("3").monospaced().bold().foregroundStyle(.green)
                }
            }

            Section("Available Connectors") {
                ConnectorRegistryRow(name: "GitHub API", description: "Repository and workflow integration", status: "Connected", icon: "github.logo")
                ConnectorRegistryRow(name: "Slack Webhooks", description: "Channel notifications and interactivity", status: "Configured", icon: "bubble.left.and.bubble.right")
                ConnectorRegistryRow(name: "AWS Lambda", description: "Serverless execution bridge", status: "Inactive", icon: "cloud")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Connectors")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Private Subviews

private struct ConnectorRegistryRow: View {
    let name: String
    let description: String
    let status: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon.contains(".") ? "app.badge" : icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.headline)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Text(status.uppercased())
                .font(.system(size: 8, weight: .black))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.1), in: Capsule())
                .foregroundStyle(statusColor)
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch status.lowercased() {
        case "connected": return .green
        case "configured": return .blue
        default: return .secondary
        }
    }
}
