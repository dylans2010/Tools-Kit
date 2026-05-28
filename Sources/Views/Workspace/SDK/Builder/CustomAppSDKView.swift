import SwiftUI
import UniformTypeIdentifiers

struct CustomAppSDKView: View {
    struct ImportedSDKApp: Identifiable {
        let id = UUID()
        var name: String
        var bundlePath: URL?
        var version: String
        var sdkCompatibility: String
        var moduleCount: Int
        var pluginCount: Int
        var connectorCount: Int
        var importedAt: Date
        var status: AppStatus

        enum AppStatus: String {
            case pending, validated, incompatible, registered, running
        }
    }

    struct ValidationResult: Identifiable {
        let id = UUID()
        var appName: String
        var isCompatible: Bool
        var sdkVersionMatch: Bool
        var moduleIntegrity: Bool
        var pluginCompatibility: Bool
        var connectorSupport: Bool
        var issues: [String]
        var warnings: [String]
    }

    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var importedApps: [CustomAppSDKView.ImportedSDKApp] = []
    @State private var isImporting = false
    @State private var isValidating = false
    @State private var validationResult: CustomAppSDKView.ValidationResult?
    @State private var showingFilePicker = false
    @State private var showingValidationDetail = false
    @State private var selectedApp: CustomAppSDKView.ImportedSDKApp?
    @State private var errorMessage: String?

    var body: some View {
        List {
            importSection
            if !importedApps.isEmpty { importedAppsSection }
            if let result = validationResult { validationSection(result) }
            registrationSection

            if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red).font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Import App")
        .sheet(isPresented: $showingValidationDetail) {
            if let app = selectedApp {
                NavigationStack { appValidationDetailSheet(app) }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var importSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.title2).foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading) {
                        Text("Import SDK Application").font(.headline)
                        Text("Import .zip bundles built with ToolsKit SDK").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)

            Button(action: simulateImport) {
                HStack {
                    Label(isImporting ? "Importing..." : "Select App Bundle", systemImage: "folder.badge.plus")
                    Spacer()
                    if isImporting { ProgressView().controlSize(.small) }
                }
            }
            .disabled(isImporting)

            Button(action: importFromClipboard) {
                Label("Import from Clipboard URL", systemImage: "doc.on.clipboard")
            }
        } header: {
            Text("Import")
        }
    }

    private var importedAppsSection: some View {
        Section {
            ForEach($importedApps) { $app in
                Button {
                    selectedApp = app
                    showingValidationDetail = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(app.name).font(.subheadline.bold())
                                Text("v\(app.version)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 12) {
                                Label("\(app.moduleCount) modules", systemImage: "cpu").font(.caption2)
                                Label("\(app.pluginCount) plugins", systemImage: "puzzlepiece").font(.caption2)
                                Label("\(app.connectorCount) connectors", systemImage: "link").font(.caption2)
                            }
                            .foregroundStyle(.tertiary)
                            HStack {
                                Text(app.status.rawValue.uppercased())
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(statusColor(app.status))
                                Text(app.importedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption).foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { offsets in importedApps.remove(atOffsets: offsets) }
        } header: {
            Text("Imported Applications (\(importedApps.count))")
        }
    }

    @ViewBuilder
    private func validationSection(_ result: CustomAppSDKView.ValidationResult) -> some View {
        Section {
            HStack {
                Image(systemName: result.isCompatible ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .foregroundStyle(result.isCompatible ? .green : .red)
                Text(result.isCompatible ? "Compatible" : "Incompatible")
                    .font(.subheadline.bold())
            }

            LabeledContent("SDK Version") {
                Image(systemName: result.sdkVersionMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.sdkVersionMatch ? .green : .red)
            }
            LabeledContent("Module Integrity") {
                Image(systemName: result.moduleIntegrity ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.moduleIntegrity ? .green : .red)
            }
            LabeledContent("Plugin Compatibility") {
                Image(systemName: result.pluginCompatibility ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.pluginCompatibility ? .green : .red)
            }
            LabeledContent("Connector Support") {
                Image(systemName: result.connectorSupport ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.connectorSupport ? .green : .red)
            }

            if !result.warnings.isEmpty {
                ForEach(result.warnings, id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.orange)
                }
            }
        } header: {
            Text("Validation Result")
        }
    }

    private var registrationSection: some View {
        Section {
            ForEach(importedApps.filter({ $0.status == .validated })) { app in
                HStack {
                    Text(app.name).font(.subheadline)
                    Spacer()
                    Button("Register") { registerApp(app) }
                        .buttonStyle(.borderedProminent).controlSize(.small)
                    Button("Run") { executeApp(app) }
                        .buttonStyle(.bordered).controlSize(.small)
                }
            }

            if importedApps.filter({ $0.status == .validated }).isEmpty {
                Text("Import and validate an app to enable registration.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        } header: {
            Text("Registration & Execution")
        }
    }

    @ViewBuilder
    private func appValidationDetailSheet(_ app: CustomAppSDKView.ImportedSDKApp) -> some View {
        List {
            Section(header: Text("App Details")) {
                LabeledContent("Name", value: app.name)
                LabeledContent("Version", value: "v\(app.version)")
                LabeledContent("SDK Compatibility", value: app.sdkCompatibility)
                LabeledContent("Status", value: app.status.rawValue.capitalized)
            }
            Section(header: Text("Contents")) {
                LabeledContent("Modules", value: "\(app.moduleCount)")
                LabeledContent("Plugins", value: "\(app.pluginCount)")
                LabeledContent("Connectors", value: "\(app.connectorCount)")
            }
            Section(header: Text("Actions")) {
                Button(action: { validateApp(app) }) {
                    Label(isValidating ? "Validating..." : "Validate Structure", systemImage: "checkmark.shield")
                }
                .disabled(isValidating)
            }
        }
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { showingValidationDetail = false }
            }
        }
    }

    private func statusColor(_ status: CustomAppSDKView.ImportedSDKApp.AppStatus) -> Color {
        switch status {
        case .pending: return .secondary
        case .validated: return .green
        case .incompatible: return .red
        case .registered: return .blue
        case .running: return .orange
        }
    }

    private func simulateImport() {
        isImporting = true
        errorMessage = nil

        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                let app = CustomAppSDKView.ImportedSDKApp(
                    name: "My Custom App",
                    version: "1.0.0",
                    sdkCompatibility: "2.0.0+",
                    moduleCount: 3,
                    pluginCount: 1,
                    connectorCount: 2,
                    importedAt: Date(),
                    status: .pending
                )
                importedApps.append(app)
                validateApp(app)
                isImporting = false
            }
        }
    }

    private func importFromClipboard() {
        guard let urlString = UIPasteboard.general.string,
              let _ = URL(string: urlString) else {
            errorMessage = "No valid URL found on clipboard"
            return
        }
        simulateImport()
    }

    private func validateApp(_ app: CustomAppSDKView.ImportedSDKApp) {
        isValidating = true
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            await MainActor.run {
                let result = CustomAppSDKView.ValidationResult(
                    appName: app.name,
                    isCompatible: true,
                    sdkVersionMatch: true,
                    moduleIntegrity: true,
                    pluginCompatibility: true,
                    connectorSupport: true,
                    issues: [],
                    warnings: app.moduleCount > 10 ? ["Large module count may impact performance"] : []
                )
                validationResult = result
                if let index = importedApps.firstIndex(where: { $0.id == app.id }) {
                    importedApps[index].status = result.isCompatible ? .validated : .incompatible
                }
                isValidating = false
            }
        }
    }

    private func registerApp(_ app: CustomAppSDKView.ImportedSDKApp) {
        if let index = importedApps.firstIndex(where: { $0.id == app.id }) {
            importedApps[index].status = .registered
        }
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.apps",
            name: "app.imported.registered",
            data: ["name": app.name, "version": app.version]
        ))
    }

    private func executeApp(_ app: CustomAppSDKView.ImportedSDKApp) {
        if let index = importedApps.firstIndex(where: { $0.id == app.id }) {
            importedApps[index].status = .running
        }
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.apps",
            name: "app.imported.launched",
            data: ["name": app.name]
        ))
    }
}
