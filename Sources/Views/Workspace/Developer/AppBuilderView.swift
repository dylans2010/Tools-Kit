import SwiftUI

struct AppBuilderView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var appService = DeveloperAppService.shared
    @StateObject private var projectManager = SDKProjectManager.shared

    @State private var name = ""
    @State private var type: DeveloperAppType = .app
    @State private var bundleId = "com."
    @State private var description = ""
    @State private var targets: Set<PlatformTarget> = [.macos]
    @State private var iconName = "app.dashed"

    @State private var isCreating = false

    var body: some View {
        Form {
            if !projectManager.projects.isEmpty {
                Section("Import from Workspace") {
                    Text("Select an existing SDK project to pre-fill the registration details.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(projectManager.projects) { project in
                                Button {
                                    importProject(project)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "cube.box.fill")
                                                .foregroundStyle(.blue)
                                            Text(project.name)
                                                .font(.system(size: 11, weight: .bold))
                                                .lineLimit(1)
                                        }
                                        Text(project.description)
                                            .font(.system(size: 8))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    .padding(10)
                                    .frame(width: 140, height: 70, alignment: .topLeading)
                                    .background(Color.primary.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Basic Information") {
                TextField("App Name", text: $name)
                Picker("Type", selection: $type) {
                    ForEach(DeveloperAppType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                TextField("Bundle Identifier", text: $bundleId)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            Section("Description") {
                TextEditor(text: $description)
                    .frame(minHeight: 100)
            }

            Section("Platform Targets") {
                ForEach(PlatformTarget.allCases, id: \.self) { target in
                    Toggle(target.rawValue, isOn: Binding(
                        get: { targets.contains(target) },
                        set: { val in
                            if val { targets.insert(target) }
                            else { targets.remove(target) }
                        }
                    ))
                }
            }

            Section("App Icon") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(["app.dashed", "cube.fill", "bolt.fill", "hammer.fill", "network", "shield.fill"], id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 50, height: 50)
                                .background(iconName == icon ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.05))
                                .foregroundStyle(iconName == icon ? Color.accentColor : Color.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(iconName == icon ? Color.accentColor : Color.clear, lineWidth: 2))
                                .onTapGesture { iconName = icon }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Section {
                Button {
                    createApp()
                } label: {
                    if isCreating {
                        ProgressView().tint(.white).frame(maxWidth: .infinity)
                    } else {
                        Text("Register Application")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
                .background(name.isEmpty ? Color.secondary : Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(name.isEmpty || isCreating)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
        .navigationTitle("New App")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func importProject(_ project: SDKProject) {
        self.name = project.name
        self.description = project.description
        self.bundleId = "com.workspace.\(project.name.lowercased().replacingOccurrences(of: " ", with: "."))"

        if project.name.contains("Plugin") { self.type = .plugin }
        else if project.name.contains("Connector") { self.type = .connector }
        else { self.type = .app }
    }

    private func createApp() {
        isCreating = true
        let app = DeveloperApp(
            name: name,
            type: type,
            status: .draft,
            version: "1.0.0",
            description: description,
            iconName: iconName,
            bundleId: bundleId,
            platformTargets: Array(targets)
        )

        Task {
            try? await appService.createApp(app)
            await MainActor.run {
                isCreating = false
                dismiss()
            }
        }
    }
}
