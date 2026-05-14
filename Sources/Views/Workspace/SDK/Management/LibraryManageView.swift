import SwiftUI

struct SDKLibrary: Identifiable, Codable {
    let id: UUID
    let identifier: String
    let name: String
    let version: String
    let capabilities: [LibraryCapability]
    let requiredScopes: [String]
    let compatibilityMatrix: [String: String] // OS version -> compatible library version
    var isLocked: Bool = false
}

struct LibraryCapability: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let inputSchema: String
    let outputSchema: String
}

@MainActor
class LibraryManager: ObservableObject {
    static let shared = LibraryManager()

    @Published var libraries: [SDKLibrary] = []
    @Published var executionLogs: [String] = []

    private init() {
        loadMockLibraries()
    }

    func loadMockLibraries() {
        libraries = [
            SDKLibrary(
                id: UUID(),
                identifier: "com.external.analytics",
                name: "Analytics Core",
                version: "2.4.1",
                capabilities: [
                    LibraryCapability(id: UUID(), name: "trackEvent", description: "Tracks user interaction", inputSchema: "JSON", outputSchema: "Bool")
                ],
                requiredScopes: ["library.invoke", "workspace.read"],
                compatibilityMatrix: ["iOS 16": ">= 2.0.0", "macOS 13": ">= 2.3.0"]
            ),
            SDKLibrary(
                id: UUID(),
                identifier: "com.external.storage",
                name: "Cloud Store",
                version: "1.0.5",
                capabilities: [
                    LibraryCapability(id: UUID(), name: "upload", description: "Uploads data to cloud", inputSchema: "Data", outputSchema: "URL")
                ],
                requiredScopes: ["library.invoke", "workspace.write"],
                compatibilityMatrix: ["iOS 17": ">= 1.0.0"]
            )
        ]
    }

    func invokeLibrary(_ library: SDKLibrary, capability: LibraryCapability, input: String) async throws -> String {
        // SDK Bridge & Validator
        guard AuthorizationManager.shared.validateScope("library.invoke", resourceType: "library", resourceId: library.identifier) else {
            throw SDKError.unauthorized
        }

        for scope in library.requiredScopes {
            guard AuthorizationManager.shared.validateScope(scope, resourceType: "library-dependency", resourceId: library.identifier) else {
                throw SDKError.missingScope(scope)
            }
        }

        executionLogs.append("[\(Date())] Invoking \(library.name).\(capability.name) with input: \(input)")

        // Simulate sandboxed execution
        try await Task.sleep(nanoseconds: 500_000_000)

        executionLogs.append("[\(Date())] \(library.name).\(capability.name) executed successfully.")
        return "Success"
    }

    func toggleLock(_ library: SDKLibrary) {
        if let index = libraries.firstIndex(where: { $0.id == library.id }) {
            libraries[index].isLocked.toggle()
        }
    }
}

enum SDKError: Error, LocalizedError {
    case unauthorized
    case missingScope(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Unauthorized access to library bridge"
        case .missingScope(let s): return "Missing required scope: \(s)"
        }
    }
}

struct LibraryManageView: View {
    @StateObject private var manager = LibraryManager.shared
    @State private var selectedLibrary: SDKLibrary?

    var body: some View {
        List {
            Section("Available Libraries") {
                ForEach(manager.libraries) { library in
                    LibraryRow(library: library) {
                        selectedLibrary = library
                    }
                }
            }

            Section("Execution Monitoring") {
                if manager.executionLogs.isEmpty {
                    Text("No activity logged").foregroundStyle(.secondary)
                } else {
                    ForEach(manager.executionLogs.reversed(), id: \.self) { log in
                        Text(log).font(.caption2.monospaced())
                    }
                }
            }
        }
        .navigationTitle("Library Management")
        .sheet(item: $selectedLibrary) { library in
            LibraryDetailView(library: library)
        }
    }
}

struct LibraryRow: View {
    let library: SDKLibrary
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(library.name).font(.headline)
                Text(library.identifier).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("v\(library.version)").font(.caption2.monospaced())
                if library.isLocked {
                    Image(systemName: "lock.fill").foregroundStyle(.orange).font(.caption2)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

struct LibraryDetailView: View {
    let library: SDKLibrary
    @StateObject private var manager = LibraryManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Descriptor") {
                    LabeledContent("Version", value: library.version)
                    LabeledContent("Locked", value: library.isLocked ? "Yes" : "No")
                    Button(library.isLocked ? "Unlock Version" : "Lock Version") {
                        manager.toggleLock(library)
                    }
                }

                Section("Capabilities") {
                    ForEach(library.capabilities) { cap in
                        VStack(alignment: .leading) {
                            Text(cap.name).font(.subheadline.bold())
                            Text(cap.description).font(.caption)
                            HStack {
                                Text("In: \(cap.inputSchema)").padding(4).background(.quaternary).cornerRadius(4)
                                Text("Out: \(cap.outputSchema)").padding(4).background(.quaternary).cornerRadius(4)
                            }
                            .font(.system(size: 8).monospaced())

                            Button("Invoke (Sandboxed)") {
                                Task {
                                    try? await manager.invokeLibrary(library, capability: cap, input: "{}")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .padding(.top, 4)
                        }
                    }
                }

                Section("Compatibility") {
                    ForEach(Array(library.compatibilityMatrix.keys.sorted()), id: \.self) { key in
                        LabeledContent(key, value: library.compatibilityMatrix[key] ?? "")
                    }
                }

                Section("Required Scopes") {
                    ForEach(library.requiredScopes, id: \.self) { scope in
                        Text(scope).font(.caption.monospaced())
                    }
                }
            }
            .navigationTitle(library.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
