import SwiftUI

struct SDKProjectArchitectView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Architectural Overview") {
                Text("Design and visualize the modular architecture of your SDK projects. Manage internal dependencies and public interfaces.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if store.sdkArchitectures.isEmpty {
                EmptyStateView(icon: "square.stack.3d.down.right", title: "No Architectures", message: "Define your first SDK architecture.")
            } else {
                ForEach(store.sdkArchitectures) { project in
                    Section(project.name) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Modules").font(.subheadline.bold())
                            FlowLayout(project.modules, spacing: 8) { module in
                                HStack {
                                    Image(systemName: "cube.fill").font(.system(size: 10))
                                    Text(module)
                                }
                                .font(.caption)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.1), in: Capsule())
                            }

                            Divider()

                            Text("External Dependencies").font(.subheadline.bold())
                            if project.dependencies.isEmpty {
                                Text("No external dependencies.").font(.caption).foregroundStyle(.secondary)
                            } else {
                                ForEach(project.dependencies, id: \.self) { dep in
                                    Text(dep).font(.caption.monospaced())
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }

            Section {
                Button {
                    var current = store.sdkArchitectures
                    current.append(SDKProjectArchitecture(name: "New SDK", modules: ["Core"]))
                    store.saveSDKArchitectures(current)
                } label: {
                    Label("Architect New SDK", systemImage: "square.stack.3d.down.right.fill")
                }
            }
        }
        .navigationTitle("SDK Architect")
    }
}
