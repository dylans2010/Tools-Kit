import SwiftUI

struct AppBuilderView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var currentStep = 0
    @State private var projectName = ""
    @State private var projectDescription = ""
    @State private var projectType: DeveloperAppType = .app
    @State private var projectVersion = "1.0.0"
    @State private var bundleId = ""
    @State private var aboutInfo = ""
    @State private var credits = ""
    @State private var socialLinks: [String: String] = [:]
    @State private var selectedScopes: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator

            TabView(selection: $currentStep) {
                identityStep.tag(0)
                typeStep.tag(1)
                aboutStep.tag(2)
                scopesStep.tag(3)
                reviewStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .navigationTitle("Register Existing App")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
    }

    private var identityStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("App Identity").font(.headline)
                TextField("App Name", text: $projectName)
                    .textFieldStyle(.roundedBorder)
                TextField("Bundle Identifier", text: $bundleId)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                TextField("Version", text: $projectVersion)
                    .textFieldStyle(.roundedBorder)
                VStack(alignment: .leading) {
                    Text("Short Description").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $projectDescription)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
            }
            .padding()
        }
    }

    private var typeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Project Type").font(.headline)
                ForEach(DeveloperAppType.allCases, id: \.self) { type in
                    Button { projectType = type } label: {
                        HStack {
                            Text(type.rawValue).font(.subheadline.bold())
                            Spacer()
                            if projectType == type {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(projectType == type ? Color.blue : Color.clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private var aboutStep: some View {
        ScrollView {
            AboutProjectView(aboutInfo: $aboutInfo, credits: $credits, socialLinks: $socialLinks)
        }
    }

    private var scopesStep: some View {
        List {
            Section("Required Permissions") {
                ForEach(["read:user", "write:user", "read:data", "write:data", "read:notifications"], id: \.self) { scope in
                    Toggle(scope, isOn: binding(for: scope))
                }
            }
        }
    }

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Review Registration").font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    summaryRow(label: "Name", value: projectName)
                    summaryRow(label: "Bundle ID", value: bundleId)
                    summaryRow(label: "Type", value: projectType.rawValue)
                    summaryRow(label: "Version", value: projectVersion)
                    summaryRow(label: "Scopes", value: "\(selectedScopes.count) selected")
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: registerApp) {
                    Label("Complete Registration", systemImage: "checkmark.seal.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(projectName.isEmpty || bundleId.isEmpty)
            }
            .padding()
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold()
        }
    }

    private var footer: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") { currentStep -= 1 }
                    .buttonStyle(.bordered)
            }
            Spacer()
            if currentStep < 4 {
                Button("Next") { currentStep += 1 }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentStep == 0 && projectName.isEmpty)
            }
        }
        .padding()
    }

    private func binding(for scope: String) -> Binding<Bool> {
        Binding(
            get: { selectedScopes.contains(scope) },
            set: { isSelected in
                if isSelected {
                    selectedScopes.insert(scope)
                } else {
                    selectedScopes.remove(scope)
                }
            }
        )
    }

    private func registerApp() {
        let newApp = DeveloperApp(
            name: projectName,
            type: projectType,
            status: .draft,
            version: projectVersion,
            description: projectDescription,
            aboutInfo: aboutInfo,
            credits: credits,
            socialLinks: socialLinks,
            bundleId: bundleId,
            grantedScopes: Array(selectedScopes)
        )
        Task {
            try? await appService.createApp(newApp)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct AboutProjectView: View {
    @Binding var aboutInfo: String
    @Binding var credits: String
    @Binding var socialLinks: [String: String]
    @State private var newPlatform = ""
    @State private var newHandle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About this Project").font(.headline)

            VStack(alignment: .leading) {
                Text("Project Details / Info").font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $aboutInfo)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            }

            VStack(alignment: .leading) {
                Text("Credits & Attributions").font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $credits)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Social Links").font(.caption).foregroundStyle(.secondary)

                ForEach(Array(socialLinks.keys.sorted()), id: \.self) { platform in
                    HStack {
                        Text(platform).bold()
                        Text(socialLinks[platform] ?? "").foregroundStyle(.secondary)
                        Spacer()
                        Button { socialLinks.removeValue(forKey: platform) } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                        }
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                HStack {
                    TextField("Platform (X, GitHub, etc.)", text: $newPlatform)
                        .textFieldStyle(.roundedBorder)
                    TextField("Handle/Link", text: $newHandle)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        if !newPlatform.isEmpty && !newHandle.isEmpty {
                            socialLinks[newPlatform] = newHandle
                            newPlatform = ""
                            newHandle = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .padding()
    }
}
