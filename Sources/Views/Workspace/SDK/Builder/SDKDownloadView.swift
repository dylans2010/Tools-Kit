import SwiftUI

struct SDKDownloadView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var selectedVersion: SDKBundleVersion?
    @State private var downloadProgress: Double = 0.0
    @State private var isDownloading = false
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var errorMessage: String?
    @State private var showingExportSheet = false
    @State private var showingInstallGuide = false
    @State private var exportModules = true
    @State private var exportPlugins = true
    @State private var exportConnectors = true
    @State private var exportRuntime = true

    struct SDKBundleVersion: Identifiable, Hashable {
        let id = UUID()
        let version: String
        let releaseDate: Date
        let size: String
        let changelog: String
        let isLatest: Bool
    }

    @State private var availableVersions: [SDKBundleVersion] = []

    var body: some View {
        List {
            sdkOverviewSection
            versionSelectionSection
            exportSection
            installGuideSection

            if let url = exportedURL {
                exportResultSection(url)
            }

            if let error = errorMessage {
                Section(header: Text("Error")) {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("SDK Download")
        .sheet(isPresented: $showingExportSheet) {
            NavigationStack { exportConfigSheet }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingInstallGuide) {
            NavigationStack { installGuideContent }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var sdkOverviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shippingbox.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading) {
                        Text("ToolsKit SDK").font(.headline)
                        Text("Versioned SDK distribution").font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let project = projectManager.currentProject {
                    HStack(spacing: 16) {
                        Label("v\(project.version)", systemImage: "tag").font(.caption)
                        Label("\(project.enabledPluginIDs.count) plugins", systemImage: "puzzlepiece").font(.caption)
                        Label("\(project.enabledConnectorIDs.count) connectors", systemImage: "link").font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("SDK Bundle")
        }
    }

    private var versionSelectionSection: some View {
        Section {
            ForEach(availableVersions) { version in
                Button {
                    selectedVersion = version
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("v\(version.version)")
                                    .font(.subheadline.bold())
                                if version.isLatest {
                                    Text("LATEST")
                                        .font(.system(size: 8, weight: .black))
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color.green.opacity(0.15), in: Capsule())
                                        .foregroundStyle(.green)
                                }
                            }
                            Text(version.changelog)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            HStack(spacing: 12) {
                                Label(version.size, systemImage: "doc.zipper").font(.caption2)
                                Label(version.releaseDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar").font(.caption2)
                            }
                            .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        if selectedVersion?.version == version.version {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Version Selection")
        }
    }

    private var exportSection: some View {
        Section {
            Button {
                showingExportSheet = true
            } label: {
                Label("Configure Export", systemImage: "square.and.arrow.up")
            }

            Button(action: startDownload) {
                HStack {
                    Label(isDownloading ? "Downloading..." : "Download SDK Bundle", systemImage: "arrow.down.circle.fill")
                    Spacer()
                    if isDownloading {
                        ProgressView(value: downloadProgress)
                            .frame(width: 80)
                    }
                }
            }
            .disabled(isDownloading || selectedVersion == nil)

            Button(action: startExport) {
                HStack {
                    Label(isExporting ? "Exporting..." : "Export Current Project", systemImage: "doc.zipper")
                    Spacer()
                    if isExporting { ProgressView().controlSize(.small) }
                }
            }
            .disabled(isExporting || projectManager.currentProject == nil)
        } header: {
            Text("Distribution")
        }
    }

    private var installGuideSection: some View {
        Section {
            Button {
                showingInstallGuide = true
            } label: {
                Label("Installation Guide", systemImage: "book.closed")
            }
        } header: {
            Text("Integration")
        }
    }

    @ViewBuilder
    private func exportResultSection(_ url: URL) -> some View {
        Section {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                VStack(alignment: .leading) {
                    Text(url.lastPathComponent).font(.subheadline.bold())
                    Text("Ready for distribution").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        } header: {
            Text("Export Result")
        }
    }

    private var exportConfigSheet: some View {
        Form {
            Section(header: Text("Include in Bundle")) {
                Toggle("SDK Modules", isOn: $exportModules)
                Toggle("Plugins", isOn: $exportPlugins)
                Toggle("Connectors", isOn: $exportConnectors)
                Toggle("Runtime Definitions", isOn: $exportRuntime)
            }

            if let version = selectedVersion {
                Section(header: Text("Selected Version")) {
                    LabeledContent("Version", value: "v\(version.version)")
                    LabeledContent("Size", value: version.size)
                }
            }
        }
        .navigationTitle("Export Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { showingExportSheet = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Apply") { showingExportSheet = false }
            }
        }
    }

    private var installGuideContent: some View {
        List {
            Section(header: Text("Step 1: Download")) {
                Text("Select an SDK version and download the .zip bundle containing all SDK modules, plugins, connectors, and runtime definitions.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Section(header: Text("Step 2: Extract")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unzip the bundle into your Xcode project directory:")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("unzip ToolsKit-SDK-v2.1.0.zip -d ./SDK/")
                        .font(.system(size: 11, design: .monospaced))
                        .padding(8)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            Section(header: Text("Step 3: Integrate")) {
                Text("Add the extracted SDK directory as a Swift Package or embed the framework directly into your Xcode project target.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Section(header: Text("Step 4: Initialize")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Boot the SDK at app launch:")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("await WorkspaceSDK.shared.initialize()")
                        .font(.system(size: 11, design: .monospaced))
                        .padding(8)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .navigationTitle("Installation Guide")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { showingInstallGuide = false }
            }
        }
    }

    private func startDownload() {
        guard selectedVersion != nil else { return }
        isDownloading = true
        downloadProgress = 0
        errorMessage = nil

        Task {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run { downloadProgress = Double(i) / 10.0 }
            }
            await MainActor.run {
                isDownloading = false
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                exportedURL = docs.appendingPathComponent("ToolsKit-SDK-v\(selectedVersion?.version ?? "2.1.0").zip")
            }
        }
    }

    private func startExport() {
        guard let project = projectManager.currentProject else { return }
        isExporting = true
        errorMessage = nil

        Task {
            do {
                let config = SDKExportConfig(
                    projectName: project.name,
                    scopes: SDKScope.allCases,
                    pluginIDs: exportPlugins ? project.enabledPluginIDs : [],
                    toolIDs: project.enabledToolIDs,
                    connectorIDs: exportConnectors ? project.enabledConnectorIDs : [],
                    automationRules: project.automationRules,
                    exportedAt: Date()
                )
                let url = try await SDKExportService().export(config: config)
                await MainActor.run {
                    exportedURL = url
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExporting = false
                }
            }
        }
    }
}
