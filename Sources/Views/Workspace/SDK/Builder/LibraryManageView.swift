import SwiftUI
import Observation
import Combine

// MARK: - 5. Model Layer

struct LibraryDescriptor: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let version: String
    let channel: VersionChannel
    let type: LibraryType
    let capabilities: [String]
    let requiredScopes: [SDKScope]
    var resourceLimits: [String: Double]
    var targetCount: Int
    var addedDate: Date
    var lastModified: Date
    var size: Int64
    var stabilityIndex: Double = 0.9

    enum LibraryType: String, Codable, CaseIterable {
        case `static`, dynamic, tbd, broken, unused, sdk, local
    }

    init(id: UUID = UUID(), name: String, path: String = "", version: String, channel: VersionChannel = .stable, type: LibraryType = .local, capabilities: [String] = [], requiredScopes: [SDKScope] = [], resourceLimits: [String: Double] = ["max_memory": 128.0, "max_cpu": 0.5], targetCount: Int = 0, addedDate: Date = Date(), lastModified: Date = Date(), size: Int64 = 0) {
        self.id = id; self.name = name; self.path = path; self.version = version
        self.channel = channel; self.type = type; self.capabilities = capabilities
        self.requiredScopes = requiredScopes; self.resourceLimits = resourceLimits
        self.targetCount = targetCount; self.addedDate = addedDate; self.lastModified = lastModified; self.size = size
    }
}

struct LIIAUsageMapping: Codable, Identifiable {
    let id: UUID = UUID()
    let libraryId: UUID
    let filePaths: [String]
    let callSites: Int
}

struct LIIAImpactAnalysis: Identifiable {
    let id: UUID = UUID()
    let libraryId: UUID
    let breakProbability: Double
    let blastRadius: Int
    let affectedModules: [String]
}

struct LIIAScore: Identifiable {
    let id: UUID = UUID()
    let efficiency: Int
    let weight: Int
    let stability: Int
    let volatility: Int
}

// MARK: - 4. Core Engine Layer

struct LIIAIngestionPipeline {
    func parseStructure(path: String) -> [String: String] {
        return ["headers": "include/", "sources": "src/", "assets": "Resources/"]
    }
}

struct LIIAUsageTracer {
    func trace(library: LibraryDescriptor) async -> LIIAUsageMapping {
        let fm = FileManager.default
        var paths: [String] = []
        var calls = 0
        let sourcesURL = URL(fileURLWithPath: "Sources")
        if let enumerator = fm.enumerator(at: sourcesURL, includingPropertiesForKeys: [.isRegularFileKey]) {
            for case let url as URL in enumerator {
                if url.pathExtension == "swift", let content = try? String(contentsOf: url) {
                    if content.contains("import \(library.name)") {
                        paths.append(url.lastPathComponent)
                        calls += content.components(separatedBy: library.name).count - 1
                    }
                }
            }
        }
        return LIIAUsageMapping(libraryId: library.id, filePaths: paths, callSites: calls)
    }
}

struct LIIAImpactSimulationEngine {
    func simulate(library: LibraryDescriptor, allLibraries: [LibraryDescriptor], mappings: [UUID: LIIAUsageMapping]) -> LIIAImpactAnalysis {
        let usage = mappings[library.id] ?? LIIAUsageMapping(libraryId: library.id, filePaths: [], callSites: 0)
        let blastRadius = usage.filePaths.count
        let breakProbability = Double(min(100, usage.callSites)) / 100.0
        let affected = Array(Set(usage.filePaths.prefix(5)))
        return LIIAImpactAnalysis(libraryId: library.id, breakProbability: breakProbability, blastRadius: blastRadius, affectedModules: affected)
    }
}

struct LIIAIntelligenceScorer {
    static func compute(library: LibraryDescriptor, usage: LIIAUsageMapping) -> LIIAScore {
        let efficiency = min(100, (usage.callSites * 10) / max(1, Int(library.size / 1024 / 1024)))
        let weight = min(100, Int(library.size / 1024 / 1024))
        let stability = Int(library.stabilityIndex * 100)
        let volatility = 100 - stability
        return LIIAScore(efficiency: efficiency, weight: weight, stability: stability, volatility: volatility)
    }
}

// MARK: - 3. Service Layer

@MainActor
final class LIIAIntelligenceService: ObservableObject {
    static let shared = LIIAIntelligenceService()
    @Published var libraries: [LibraryDescriptor] = []
    @Published var usageMappings: [UUID: LIIAUsageMapping] = [:]
    private let eventBus = SDKEventBus.shared

    private init() { load() }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: "LIIA_Libraries"),
           let decoded = try? JSONDecoder().decode([LibraryDescriptor].self, from: data) {
            self.libraries = decoded
        }
        refreshUsage()
    }

    func refreshUsage() {
        Task {
            for lib in libraries {
                let mapping = await LIIAUsageTracer().trace(library: lib)
                self.usageMappings[lib.id] = mapping
            }
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(libraries) { UserDefaults.standard.set(data, forKey: "LIIA_Libraries") }
        eventBus.publish(SDKBusEvent(channel: "liia", name: "intelligence_updated", data: ["count": "\(libraries.count)"], source: "LIIA"))
    }

    func install(lib: LibraryDescriptor) {
        libraries.removeAll { $0.name == lib.name }
        libraries.append(lib)
        save()
        refreshUsage()
    }

    func uninstall(id: UUID) -> LIIAImpactAnalysis {
        let analysis = LIIAImpactSimulationEngine().simulate(library: libraries.first { $0.id == id }!, allLibraries: libraries, mappings: usageMappings)
        if analysis.breakProbability < 0.9 {
            libraries.removeAll { $0.id == id }
            usageMappings.removeValue(forKey: id)
            save()
        }
        return analysis
    }
}

// MARK: - 2. ViewModel Layer

@MainActor
final class LibraryManageViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var impactAnalysis: LIIAImpactAnalysis?
    @Published var showImpact: Bool = false
    private let service = LIIAIntelligenceService.shared

    var filteredLibraries: [LibraryDescriptor] {
        service.libraries.filter { $0.name.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty }
    }

    func uninstall(id: UUID) {
        impactAnalysis = service.uninstall(id: id)
        showImpact = true
    }
}

// MARK: - 1. Presentation Layer

struct LibraryManageView: View {
    @StateObject private var viewModel = LibraryManageViewModel()
    @StateObject private var service = LIIAIntelligenceService.shared
    @State private var showInstallSheet = false
    @State private var selectedLibrary: LibraryDescriptor?

    var body: some View {
        NavigationStack {
            List {
                Section("System Intelligence") {
                    HStack {
                        intelligenceTile(label: "Efficiency", value: "\(systemEfficiency())%", color: .green)
                        intelligenceTile(label: "Stability", value: "\(systemStability())%", color: .blue)
                    }
                }
                Section("Reasoning Engine") {
                    if service.libraries.isEmpty {
                        ContentUnavailableView("Empty", systemImage: "brain")
                    } else {
                        ForEach(viewModel.filteredLibraries) { lib in
                            LibraryRow(library: lib, usage: service.usageMappings[lib.id]) { selectedLibrary = lib }
                                .swipeActions { Button(role: .destructive) { viewModel.uninstall(id: lib.id) } label: { Label("Remove", systemImage: "trash") } }
                        }
                    }
                }
            }
            .navigationTitle("LIIA Analyzer")
            .searchable(text: $viewModel.searchText)
            .toolbar { ToolbarItem(placement: .primaryAction) { Button { showInstallSheet = true } label: { Image(systemName: "plus") } } }
            .sheet(isPresented: $showInstallSheet) { LIIAInstallSheet(viewModel: viewModel) }
            .sheet(item: $selectedLibrary) { lib in LibraryDetailSheet(library: lib, service: service) }
            .alert("Impact Analysis", isPresented: $viewModel.showImpact) { Button("OK"){} } message: {
                if let impact = viewModel.impactAnalysis {
                    Text("Risk: \(Int(impact.breakProbability*100))%\nRadius: \(impact.blastRadius) files\nModules: \(impact.affectedModules.joined(separator: ", "))")
                }
            }
        }
    }

    private func intelligenceTile(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(label).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
            Text(value).font(.title2.bold()).foregroundStyle(color)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private func systemEfficiency() -> Int {
        let scores = service.libraries.compactMap { lib -> Int? in
            guard let usage = service.usageMappings[lib.id] else { return nil }
            return LIIAIntelligenceScorer.compute(library: lib, usage: usage).efficiency
        }
        return scores.isEmpty ? 100 : scores.reduce(0, +) / scores.count
    }

    private func systemStability() -> Int {
        service.libraries.isEmpty ? 100 : Int(service.libraries.map(\.stabilityIndex).reduce(0, +) / Double(service.libraries.count) * 100)
    }
}

struct LibraryRow: View {
    let library: LibraryDescriptor; let usage: LIIAUsageMapping?; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(library.name).font(.subheadline.bold())
                    Text("\(usage?.filePaths.count ?? 0) importers").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(usage?.callSites ?? 0) calls").font(.caption2.monospaced()).foregroundStyle(.tertiary)
            }
        }.buttonStyle(.plain)
    }
}

struct LibraryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let library: LibraryDescriptor; let service: LIIAIntelligenceService
    var body: some View {
        List {
            Section("Metrics") {
                if let usage = service.usageMappings[library.id] {
                    let score = LIIAIntelligenceScorer.compute(library: library, usage: usage)
                    LabeledContent("Efficiency", value: "\(score.efficiency)%")
                    LabeledContent("Stability", value: "\(score.stability)%")
                }
            }
            Section("Importers") {
                ForEach(service.usageMappings[library.id]?.filePaths ?? [], id: \.self) { Text($0).font(.caption2.monospaced()) }
            }
        }.navigationTitle(library.name).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
    }
}

struct LIIAInstallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LibraryManageViewModel
    @State private var name = ""; @State private var version = "1.0.0"
    var body: some View {
        Form {
            TextField("Name", text: $name); TextField("Version", text: $version)
            Button("Ingest") {
                LIIAIntelligenceService.shared.install(lib: LibraryDescriptor(name: name, version: version))
                dismiss()
            }.disabled(name.isEmpty)
        }.navigationTitle("Ingestion").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }
}

// MARK: - Legacy Compatibility

enum VersionChannel: String, CaseIterable, Codable, Identifiable { case stable, beta, experimental; var id: String { rawValue } }
enum LibraryCategory: String, CaseIterable, Codable, Identifiable {
    case ai = "AI", storage = "Storage", communication = "Communication", data = "Data", security = "Security"; var id: String { rawValue }
    var icon: String { switch self { case .ai: return "sparkles"; case .storage: return "externaldrive.fill"; case .communication: return "message.fill"; case .data: return "tablecells.fill"; case .security: return "shield.fill" } }
}
@MainActor final class LibraryRegistry: ObservableObject { static let shared = LibraryRegistry(); var libraries: [LibraryDescriptor] { LIIAIntelligenceService.shared.libraries } }
@MainActor final class LibraryManager: ObservableObject { static let shared = LibraryManager() }
