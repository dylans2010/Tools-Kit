import SwiftUI

class SDKAppBuilderViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var selectedScopes: Set<SDKScope> = []
    @Published var selectedPlugins: Set<UUID> = []
    @Published var selectedTools: Set<UUID> = []
    @Published var selectedConnectors: Set<UUID> = []

    func export() {
        // Call SDKExportService
    }
}

struct SDKAppBuilderView: View {
    @StateObject private var builder = SDKAppBuilderViewModel()
    @State private var currentStep = 0
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            TabView(selection: $currentStep) {
                Step1View(name: $builder.name, description: $builder.description).tag(0)
                Step2View(selectedScopes: $builder.selectedScopes).tag(1)
                Step3View(selectedPlugins: $builder.selectedPlugins).tag(2)
                Step4View(selectedTools: $builder.selectedTools).tag(3)
                Step5View(selectedConnectors: $builder.selectedConnectors).tag(4)
                ReviewStepView(builder: builder).tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack {
                if currentStep > 0 {
                    Button("Back") { currentStep -= 1 }
                }
                Spacer()
                if currentStep < 5 {
                    Button("Next") { currentStep += 1 }
                } else {
                    Button("Build & Export") {
                        builder.export()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle("App Builder")
    }
}

struct Step1View: View {
    @Binding var name: String
    @Binding var description: String
    var body: some View {
        Form {
            Section("Project Identity") {
                TextField("App Name", text: $name)
                TextEditor(text: $description)
                    .frame(height: 100)
            }
        }
    }
}

struct Step2View: View {
    @Binding var selectedScopes: Set<SDKScope>
    var body: some View {
        List(SDKScope.allCases, id: \.self) { type in
            Toggle(type.rawValue.capitalized, isOn: Binding(
                get: { selectedScopes.contains(type) },
                set: { if $0 { selectedScopes.insert(type) } else { selectedScopes.remove(type) } }
            ))
        }
    }
}

struct Step3View: View {
    @Binding var selectedPlugins: Set<UUID>
    var body: some View {
        List(SDKPluginManager.shared.plugins) { plugin in
            Toggle(plugin.name, isOn: Binding(
                get: { selectedPlugins.contains(plugin.id) },
                set: { if $0 { selectedPlugins.insert(plugin.id) } else { selectedPlugins.remove(plugin.id) } }
            ))
        }
    }
}

struct Step4View: View {
    @Binding var selectedTools: Set<UUID>
    var body: some View {
        List(SDKToolManager.shared.tools) { tool in
            Toggle(tool.name, isOn: Binding(
                get: { selectedTools.contains(tool.id) },
                set: { if $0 { selectedTools.insert(tool.id) } else { selectedTools.remove(tool.id) } }
            ))
        }
    }
}

struct Step5View: View {
    @Binding var selectedConnectors: Set<UUID>
    var body: some View {
        List(SDKConnectorManager.shared.connectors, id: \.id) { connector in
            Toggle(connector.name, isOn: Binding(
                get: { selectedConnectors.contains(connector.id) },
                set: { if $0 { selectedConnectors.insert(connector.id) } else { selectedConnectors.remove(connector.id) } }
            ))
        }
    }
}

struct ReviewStepView: View {
    @ObservedObject var builder: SDKAppBuilderViewModel
    var body: some View {
        VStack {
            Text("Review Your App")
                .font(.title)
            List {
                LabeledContent("Name", value: builder.name)
                LabeledContent("Scopes", value: "\(builder.selectedScopes.count)")
                LabeledContent("Plugins", value: "\(builder.selectedPlugins.count)")
                LabeledContent("Tools", value: "\(builder.selectedTools.count)")
                LabeledContent("Connectors", value: "\(builder.selectedConnectors.count)")
            }
        }
    }
}
