import SwiftUI

// MARK: - DevTool Category

enum DevToolCategory: String, CaseIterable, Identifiable {
    case inputOutput = "Input / Output"
    case encoding = "Encoding"
    case uiDesign = "UI Design"
    case data = "Data"
    case networking = "Networking"
    case diagnostics = "Diagnostics"
    case performance = "Performance"
    case storage = "Storage"
    case security = "Security"
    case utilities = "Utilities"
    case debugging = "Debugging"
    case system = "System"
    case automation = "Automation"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .inputOutput: return "arrow.left.arrow.right"
        case .encoding: return "doc.text"
        case .uiDesign: return "paintpalette"
        case .data: return "cylinder"
        case .networking: return "network"
        case .diagnostics: return "stethoscope"
        case .performance: return "gauge.with.dots.needle.33percent"
        case .storage: return "internaldrive"
        case .security: return "lock.shield"
        case .utilities: return "wrench.and.screwdriver"
        case .debugging: return "ladybug"
        case .system: return "gearshape.2"
        case .automation: return "gearshape.arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - DevTool Protocol

protocol DevTool: Identifiable {
    var id: UUID { get }
    var name: String { get }
    var category: DevToolCategory { get }
    var icon: String { get }
    var description: String { get }
    associatedtype Content: View
    @ViewBuilder func render() -> Content
}

// MARK: - AnyDevTool (Type Erasure)

struct AnyDevTool: Identifiable {
    let id: UUID
    let name: String
    let category: DevToolCategory
    let icon: String
    let description: String
    private let _render: () -> AnyView

    init<T: DevTool>(_ tool: T) {
        self.id = tool.id
        self.name = tool.name
        self.category = tool.category
        self.icon = tool.icon
        self.description = tool.description
        self._render = { AnyView(tool.render()) }
    }

    func render() -> AnyView {
        _render()
    }
}

// MARK: - DevToolRegistry

final class DevToolRegistry: ObservableObject {
    static let shared = DevToolRegistry()

    @Published private(set) var tools: [AnyDevTool] = []

    private init() {
        registerAllTools()
    }

    func register<T: DevTool>(_ tool: T) {
        tools.append(AnyDevTool(tool))
    }

    func tools(in category: DevToolCategory) -> [AnyDevTool] {
        tools.filter { $0.category == category }
    }

    func search(_ query: String) -> [AnyDevTool] {
        guard !query.isEmpty else { return tools }
        let lowered = query.lowercased()
        return tools.filter {
            $0.name.lowercased().contains(lowered) ||
            $0.description.lowercased().contains(lowered) ||
            $0.category.rawValue.lowercased().contains(lowered)
        }
    }

    var categoriesWithTools: [DevToolCategory] {
        DevToolCategory.allCases.filter { category in
            tools.contains { $0.category == category }
        }
    }

    private func registerAllTools() {
        // Input / Output
        register(Base64EncoderTool())
        register(Base64DecoderTool())
        register(URLEncoderTool())
        register(URLDecoderTool())
        register(URLParserTool())
        register(ASCIIHexConverterTool())
        register(UnicodeInspectorTool())
        register(HTMLEntityEncoderTool())
        register(HTMLEntityDecoderTool())
        register(QueryStringParserTool())

        // UI Design
        register(ColorConverterTool())
        register(ColorPaletteGeneratorTool())
        register(GradientBuilderTool())
        register(BezierCurveVisualizerTool())
        register(ContrastCheckerTool())
        register(ColorMixerTool())
        register(ShadowGeneratorTool())
        register(TypographyScaleTool())
        register(SFSymbolsBrowserTool())
        register(LayoutGridPreviewTool())

        // Data
        register(UUIDGeneratorTool())
        register(UUIDBulkGeneratorTool())
        register(JSONFormatterTool())
        register(JSONValidatorTool())
        register(JSONDiffTool())
        register(YAMLParserTool())
        register(CSVParserTool())
        register(XMLFormatterTool())
        register(DateFormatterDevToolImpl())
        register(TimezoneConverterTool())
        register(NumberFormatterDevToolImpl())

        // Networking
        register(HTTPRequestTesterTool())
        register(HeaderInspectorTool())
        register(NetworkReachabilityTool())
        register(APIResponseViewerTool())
        register(WebSocketMonitorTool())
        register(DNSLookupTool())
        register(IPInfoTool())

        // Diagnostics
        register(VerboseLoggerTool())
        register(CrashLogViewerTool())
        register(ThreadInspectorTool())
        register(AppStateInspectorTool())
        register(ViewHierarchyInspectorTool())

        // Performance
        register(MemoryMonitorTool())
        register(CPUMonitorTool())
        register(FPSMonitorTool())
        register(LaunchTimeTrackerTool())
        register(EnergyImpactMonitorTool())

        // Storage
        register(FileExplorerTool())
        register(UserDefaultsInspectorTool())
        register(CacheViewerTool())
        register(DiskUsageAnalyzerTool())
        register(SQLiteBrowserTool())

        // Security
        register(KeychainViewerTool())
        register(PermissionInspectorTool())
        register(HashGeneratorTool())
        register(JWTDecoderTool())
        register(EncryptionToolImpl())

        // Utilities
        register(RegexTesterTool())
        register(TextDiffTool())
        register(MarkdownPreviewTool())
        register(TextCaseConverterTool())
        register(ClipboardInspectorTool())
        register(LoremIpsumGeneratorTool())

        // Debugging
        register(LogStreamViewerTool())
        register(BreakpointManagerTool())
        register(RuntimeInspectorTool())

        // System
        register(DeviceInfoTool())
        register(OSVersionInspectorTool())
        register(BatteryStatusTool())

        // Automation
        register(ScriptRunnerTool())
        register(TaskAutomationTool())
    }
}
