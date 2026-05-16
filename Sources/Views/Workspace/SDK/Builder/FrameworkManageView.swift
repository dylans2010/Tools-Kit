import SwiftUI
import Observation
import Combine

// MARK: - 5. Model Layer

enum FrameworkLanguage: String, CaseIterable, Codable, Identifiable {
    case swift, python, javascript, typescript, cpp
    var id: String { rawValue }
}

enum FOCLifecycleState: String, CaseIterable, Codable, Identifiable {
    case unregistered, registered, resolved, installed, active, suspended, deprecated, failed
    var id: String { rawValue }
}

struct FrameworkDescriptor: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let type: FrameworkType
    let entryPoints: [String]
    let language: FrameworkLanguage
    let packageDependencies: [UUID]
    let requiredScopes: [SDKScope]
    var isEnabled: Bool
    var sandboxProfile: SandboxProfile
    var lifecycleState: FOCLifecycleState
    var logs: [FrameworkLogEntry]
    var size: Int64
    var lastModified: Date
    var architectures: [String]
    var linkType: LinkType
    var embedMode: EmbedMode

    enum FrameworkType: String, Codable, CaseIterable {
        case appleSystem, xcframework, `static`, dynamic, embedded, broken
    }

    enum LinkType: String, Codable, CaseIterable {
        case required, optional
    }

    enum EmbedMode: String, Codable, CaseIterable {
        case embedAndSign = "Embed & Sign", embedWithoutSigning = "Embed Without Signing", doNotEmbed = "Do Not Embed"
    }

    init(id: UUID = UUID(), name: String, path: String = "", type: FrameworkType = .xcframework, entryPoints: [String] = ["main"], language: FrameworkLanguage = .swift, packageDependencies: [UUID] = [], requiredScopes: [SDKScope] = [.frameworkExecute], isEnabled: Bool = true, sandboxProfile: SandboxProfile = .balanced, lifecycleState: FOCLifecycleState = .unregistered, logs: [FrameworkLogEntry] = [], size: Int64 = 0, lastModified: Date = Date(), architectures: [String] = ["arm64"], linkType: LinkType = .required, embedMode: EmbedMode = .embedAndSign) {
        self.id = id; self.name = name; self.path = path; self.type = type; self.entryPoints = entryPoints; self.language = language
        self.packageDependencies = packageDependencies; self.requiredScopes = requiredScopes; self.isEnabled = isEnabled
        self.sandboxProfile = sandboxProfile; self.lifecycleState = lifecycleState; self.logs = logs; self.size = size
        self.lastModified = lastModified; self.architectures = architectures; self.linkType = linkType; self.embedMode = embedMode
    }
}

struct FrameworkLogEntry: Identifiable, Codable, Hashable {
    let id: UUID = UUID()
    let timestamp: Date = Date()
    let level: LogLevel = .info
    let message: String = ""
    enum LogLevel: String, Codable { case info, warning, error, debug }
}

// MARK: - 4. Core Engine Layer

struct FOCRegistryEngine {
    func analyzeBinary(at path: String) -> (archs: [String], size: Int64) {
        let url = URL(fileURLWithPath: path)
        let attr = try? FileManager.default.attributesOfItem(atPath: path)
        let size = attr?[.size] as? Int64 ?? 0

        // Re-implementing simplified Mach-O parsing logic here
        var detectedArchs: [String] = []
        if let handle = try? FileHandle(forReadingFrom: url) {
            defer { try? handle.close() }
            if let magicData = try? handle.read(upToCount: 4) {
                let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }
                if magic == 0xBEBAFECA || magic == 0xCAFEBABE {
                    if let countData = try? handle.read(upToCount: 4) {
                        let count = countData.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
                        for _ in 0..<count {
                            if let archData = try? handle.read(upToCount: 20) {
                                let cputype = archData.withUnsafeBytes { $0.load(as: Int32.self) }.bigEndian
                                detectedArchs.append(cputype == 7 | 0x01000000 ? "x86_64" : (cputype == 12 | 0x01000000 ? "arm64" : "unknown"))
                            }
                        }
                    }
                } else if [0xFEEDFACE, 0xFEEDFACF].contains(magic) {
                    detectedArchs = ["arm64"] // Native slice
                }
            }
        }
        return (detectedArchs.isEmpty ? ["arm64"] : detectedArchs, size)
    }

    func register(fw: FrameworkDescriptor, frameworks: inout [FrameworkDescriptor]) {
        frameworks.removeAll { $0.name == fw.name }
        var registered = fw
        let analysis = analyzeBinary(at: fw.path)
        registered.architectures = analysis.archs
        registered.size = analysis.size
        registered.lifecycleState = .registered
        frameworks.append(registered)
    }
}

struct FOCLifecycleStateMachine {
    func transition(from: FOCLifecycleState, to: FOCLifecycleState) -> Bool {
        let validTransitions: [FOCLifecycleState: [FOCLifecycleState]] = [
            .unregistered: [.registered],
            .registered: [.resolved, .failed],
            .resolved: [.installed, .failed],
            .installed: [.active, .failed, .deprecated],
            .active: [.suspended, .deprecated, .failed],
            .suspended: [.active, .deprecated, .failed],
            .deprecated: [.unregistered],
            .failed: [.registered, .unregistered]
        ]
        return validTransitions[from]?.contains(to) ?? false
    }
}

struct FOCHealthEngine {
    struct HealthMetrics {
        let stability: Int; let fragility: Int; let complexity: Int
    }
    static func compute(fw: FrameworkDescriptor) -> HealthMetrics {
        let stability = fw.lifecycleState == .active ? 95 : (fw.lifecycleState == .failed ? 10 : 60)
        let fragility = fw.packageDependencies.count * 12
        let complexity = fw.entryPoints.count * 8
        return HealthMetrics(stability: stability, fragility: min(100, fragility), complexity: min(100, complexity))
    }
}

// MARK: - 3. Service Layer

@MainActor
final class FOCFrameworkService: ObservableObject {
    static let shared = FOCFrameworkService()
    @Published var frameworks: [FrameworkDescriptor] = []
    private let eventBus = SDKEventBus.shared

    private init() { load() }
    private func load() {
        if let data = UserDefaults.standard.data(forKey: "FOC_Frameworks"),
           let decoded = try? JSONDecoder().decode([FrameworkDescriptor].self, from: data) { self.frameworks = decoded }
    }
    func save() {
        if let data = try? JSONEncoder().encode(frameworks) { UserDefaults.standard.set(data, forKey: "FOC_Frameworks") }
        eventBus.publish(SDKBusEvent(channel: "foc", name: "framework_updated", data: ["count": "\(frameworks.count)"], source: "FOC"))
    }
    func updateState(id: UUID, newState: FOCLifecycleState) -> Bool {
        guard let i = frameworks.firstIndex(where: { $0.id == id }) else { return false }
        if FOCLifecycleStateMachine().transition(from: frameworks[i].lifecycleState, to: newState) {
            frameworks[i].lifecycleState = newState; save(); return true
        }
        return false
    }
    func install(fw: FrameworkDescriptor) { FOCRegistryEngine().register(fw: fw, frameworks: &frameworks); save() }
}

// MARK: - 2. ViewModel Layer

@MainActor
final class FrameworkManageViewModel: ObservableObject {
    @Published var searchText: String = ""
    private let service = FOCFrameworkService.shared
    var filteredFrameworks: [FrameworkDescriptor] { service.frameworks.filter { $0.name.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty } }
    func advance(id: UUID) {
        guard let fw = service.frameworks.first(where: { $0.id == id }) else { return }
        let workflow: [FOCLifecycleState] = [.registered, .resolved, .installed, .active]
        if let current = workflow.firstIndex(of: fw.lifecycleState), current + 1 < workflow.count {
            _ = service.updateState(id: id, newState: workflow[current + 1])
        } else if fw.lifecycleState == .unregistered { _ = service.updateState(id: id, newState: .registered) }
    }
}

// MARK: - 1. Presentation Layer

struct FrameworkManageView: View {
    @StateObject private var viewModel = FrameworkManageViewModel()
    @StateObject private var service = FOCFrameworkService.shared
    @State private var showInstallSheet = false
    @State private var selectedFramework: FrameworkDescriptor?

    var body: some View {
        NavigationStack {
            List {
                Section("Runtimes") {
                    HStack {
                        metricTile(label: "Active", value: "\(service.frameworks.filter{$0.lifecycleState == .active}.count)", color: .green)
                        metricTile(label: "Health", value: "\(avgHealth())%", color: .blue)
                    }
                }
                Section("Registry") {
                    if service.frameworks.isEmpty { ContentUnavailableView("Empty", systemImage: "cpu") }
                    else {
                        ForEach(viewModel.filteredFrameworks) { fw in
                            FrameworkRow(fw: fw) { selectedFramework = fw }
                                .swipeActions {
                                    Button { viewModel.advance(id: fw.id) } label: { Label("Next", systemImage: "play.fill") }.tint(.green)
                                    Button(role: .destructive) { service.frameworks.removeAll{$0.id == fw.id}; service.save() } label: { Label("Remove", systemImage: "trash") }
                                }
                        }
                    }
                }
            }
            .navigationTitle("FOC Orchestrator").searchable(text: $viewModel.searchText)
            .toolbar { ToolbarItem(placement: .primaryAction) { Button { showInstallSheet = true } label: { Image(systemName: "plus") } } }
            .sheet(isPresented: $showInstallSheet) { FOCInstallSheet(viewModel: viewModel) }
            .sheet(item: $selectedFramework) { fw in FrameworkDetailSheet(fw: fw) }
        }
    }

    private func metricTile(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(label).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
            Text(value).font(.title2.bold()).foregroundStyle(color)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private func avgHealth() -> Int {
        service.frameworks.isEmpty ? 100 : service.frameworks.map{FOCHealthEngine.compute(fw: $0).stability}.reduce(0, +) / service.frameworks.count
    }
}

struct FrameworkRow: View {
    let fw: FrameworkDescriptor; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(fw.name).font(.subheadline.bold())
                    Text(fw.lifecycleState.rawValue.uppercased()).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                }
                Spacer()
                let m = FOCHealthEngine.compute(fw: fw)
                Circle().fill(m.stability > 80 ? Color.green : (m.stability > 40 ? Color.orange : Color.red)).frame(width: 8, height: 8)
            }
        }.buttonStyle(.plain)
    }
}

struct FrameworkDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let fw: FrameworkDescriptor
    var body: some View {
        List {
            Section("Binary") {
                LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: fw.size, countStyle: .file))
                LabeledContent("Archs", value: fw.architectures.joined(separator: ", "))
            }
            Section("Health") {
                let m = FOCHealthEngine.compute(fw: fw)
                LabeledContent("Stability", value: "\(m.stability)%")
                LabeledContent("Fragility", value: "\(m.fragility)%")
            }
        }.navigationTitle(fw.name).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
    }
}

struct FOCInstallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FrameworkManageViewModel
    @State private var name = ""; @State private var language: FrameworkLanguage = .swift
    var body: some View {
        Form {
            TextField("Name", text: $name); Picker("Language", selection: $language) { ForEach(FrameworkLanguage.allCases){Text($0.rawValue).tag($0)} }
            Button("Register") { FOCFrameworkService.shared.install(fw: FrameworkDescriptor(name: name, language: language)); dismiss() }.disabled(name.isEmpty)
        }.navigationTitle("Registration").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }
}

// MARK: - Legacy Compatibility

@MainActor final class FrameworkRegistry { static let shared = FrameworkRegistry(); var frameworks: [FrameworkDescriptor] { FOCFrameworkService.shared.frameworks } }
@MainActor final class FrameworkManager { static let shared = FrameworkManager() }
enum SandboxProfile: String, CaseIterable, Codable { case restricted, balanced, unrestricted }
