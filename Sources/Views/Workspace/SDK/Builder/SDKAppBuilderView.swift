import SwiftUI

class SDKAppBuilderViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var selectedScopes: Set<SDKScope> = []
    @Published var selectedPlugins: Set<UUID> = []
    @Published var selectedTools: Set<UUID> = []
    @Published var selectedConnectors: Set<UUID> = []

    func export() async throws -> URL {
        let rules = await SDKAutomationEngine.shared.rules
        let config = SDKExportConfig(
            projectName: name,
            scopes: Array(selectedScopes),
            pluginIDs: Array(selectedPlugins),
            toolIDs: Array(selectedTools),
            connectorIDs: Array(selectedConnectors),
            automationRules: rules,
            exportedAt: Date()
        )
        return try await SDKExportService().export(config: config)
    }
}

struct SDKAppBuilderView: View {
    @StateObject private var viewModel = SDKAppBuilderViewModel()
    @State private var currentStep = 0
    @State private var exportedURL: URL?
    @State private var isExporting = false

    var body: some View {
        VStack {
            stepIndicator

            TabView(selection: $currentStep) {
                step1.tag(0)
                step2.tag(1)
                step3.tag(2)
                step4.tag(3)
                step5.tag(4)
                step6.tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            navigationButtons
        }
        .navigationTitle("App Builder")
        .sheet(item: $exportedURL) { url in
            AppBuilderShareSheet(activityItems: [url])
        }
    }

    private var stepIndicator: some View {
        HStack {
            ForEach(0..<6) { index in
                Circle()
                    .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
    }

    private var step1: some View {
        Form {
            Section {
                TextField("App Name", text: $viewModel.name)
                TextEditor(text: $viewModel.description)
                    .frame(height: 100)
            } header: {
                Label("Project Identity", systemImage: "doc.text.fill")
            }
        }
    }

    private var step2: some View {
        List {
            Section {
                ForEach(SDKScope.allCases, id: \.self) { scope in
                    Toggle(String(describing: scope).capitalized, isOn: binding(for: scope, in: \.selectedScopes))
                }
            } header: {
                Label("Scopes", systemImage: "lock.shield")
            }
        }
    }

    private var step3: some View {
        List {
            Section {
                ForEach(SDKPluginManager.shared.plugins) { plugin in
                    Toggle(plugin.name, isOn: binding(for: plugin.id, in: \.selectedPlugins))
                }
            } header: {
                Label("Plugins", systemImage: "puzzlepiece.extension")
            }
        }
    }

    private var step4: some View {
        List {
            Section {
                ForEach(SDKToolManager.shared.tools) { tool in
                    Toggle(tool.name, isOn: binding(for: tool.id, in: \.selectedTools))
                }
            } header: {
                Label("Tools", systemImage: "wrench.and.screwdriver")
            }
        }
    }

    private var step5: some View {
        List {
            Section {
                ForEach(SDKConnectorManager.shared.connectors, id: \.id) { connector in
                    Toggle(connector.name, isOn: binding(for: connector.id, in: \.selectedConnectors))
                }
            } header: {
                Label("Connectors", systemImage: "cable.connector")
            }
        }
    }

    private var step6: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("Ready to Build").font(.title)
            Text("Your app configuration is complete.").foregroundStyle(.secondary)

            Button {
                exportApp()
            } label: {
                if isExporting {
                    ProgressView().progressViewStyle(.circular)
                } else {
                    Label("Export as .zip", systemImage: "archivebox")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting || viewModel.name.isEmpty)
        }
    }

    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button { currentStep -= 1 } label: {
                    Label("Previous", systemImage: "chevron.left")
                }
            }
            Spacer()
            if currentStep < 5 {
                Button { currentStep += 1 } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                    .disabled(currentStep == 0 && viewModel.name.isEmpty)
            }
        }
        .padding()
    }

    private func binding<T: Hashable>(for item: T, in keyPath: ReferenceWritableKeyPath<SDKAppBuilderViewModel, Set<T>>) -> Binding<Bool> {
        Binding<Bool>(
            get: { viewModel[keyPath: keyPath].contains(where: { $0 == item }) },
            set: { (inserted: Bool) in
                if inserted {
                    _ = viewModel[keyPath: keyPath].insert(item)
                } else {
                    viewModel[keyPath: keyPath].remove(item)
                }
            }
        )
    }

    private func exportApp() {
        isExporting = true
        Task {
            do {
                let url = try await viewModel.export()
                await MainActor.run {
                    self.exportedURL = url
                    isExporting = false
                }
            } catch {
                await MainActor.run { isExporting = false }
            }
        }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

struct AppBuilderShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
