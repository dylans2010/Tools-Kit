import SwiftUI

class SDKAppBuilderViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var selectedScopes: Set<SDKScope> = []
    @Published var selectedPlugins: Set<UUID> = []
    @Published var selectedTools: Set<UUID> = []
    @Published var selectedConnectors: Set<UUID> = []

    func export() async throws -> URL {
        let config = SDKExportConfig(
            projectName: name,
            scopes: Array(selectedScopes),
            pluginIDs: Array(selectedPlugins),
            toolIDs: Array(selectedTools),
            connectorIDs: Array(selectedConnectors),
            automationRules: SDKAutomationEngine.shared.rules,
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
            ShareSheet(activityItems: [url])
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
            Section("Project Identity") {
                TextField("App Name", text: $viewModel.name)
                TextEditor(text: $viewModel.description)
                    .frame(height: 100)
            }
        }
    }

    private var step2: some View {
        List(SDKScope.allCases, id: \.self) { scope in
            Toggle(String(describing: scope).capitalized, isOn: binding(for: scope))
        }
    }

    private var step3: some View {
        List(SDKPluginManager.shared.plugins) { plugin in
            Toggle(plugin.name, isOn: binding(for: plugin.id, in: \.selectedPlugins))
        }
    }

    private var step4: some View {
        List(SDKToolManager.shared.tools) { tool in
            Toggle(tool.name, isOn: binding(for: tool.id, in: \.selectedTools))
        }
    }

    private var step5: some View {
        List(SDKConnectorManager.shared.connectors, id: \.id) { connector in
            Toggle(connector.name, isOn: binding(for: connector.id, in: \.selectedConnectors))
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
                Button("Previous") { currentStep -= 1 }
            }
            Spacer()
            if currentStep < 5 {
                Button("Next") { currentStep += 1 }
                    .disabled(currentStep == 0 && viewModel.name.isEmpty)
            }
        }
        .padding()
    }

    private func binding(for scope: SDKScope) -> Binding<Bool> {
        Binding(
            get: { viewModel.selectedScopes.contains(scope) },
            set: { $0 ? viewModel.selectedScopes.insert(scope) : viewModel.selectedScopes.remove(scope) }
        )
    }

    private func binding(for id: UUID, in keyPath: ReferenceWritableKeyPath<SDKAppBuilderViewModel, Set<UUID>>) -> Binding<Bool> {
        Binding(
            get: { viewModel[keyPath: keyPath].contains(id) },
            set: { $0 ? viewModel[keyPath: keyPath].insert(id) : viewModel[keyPath: keyPath].remove(id) }
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
