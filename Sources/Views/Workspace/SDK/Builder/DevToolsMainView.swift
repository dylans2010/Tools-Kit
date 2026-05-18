import SwiftUI

// MARK: - Core Infrastructure

protocol DevTool: Identifiable {
    var id: String { get } // Use string for stable ID
    var name: String { get }
    var category: DevToolCategory { get }
    var icon: String { get }
    var description: String { get }

    associatedtype Content: View
    @ViewBuilder func render() -> Content
}

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
        case .inputOutput: return "arrow.left.and.right"
        case .encoding: return "person.badge.key"
        case .uiDesign: return "paintpalette"
        case .data: return "square.grid.3x2"
        case .networking: return "network"
        case .diagnostics: return "stethoscope"
        case .performance: return "speedometer"
        case .storage: return "externaldrive"
        case .security: return "shield"
        case .utilities: return "wrench.adjustable"
        case .debugging: return "ladybug"
        case .system: return "cpu"
        case .automation: return "bolt.shield"
        }
    }
}

struct AnyDevTool: Identifiable {
    let id: String
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

@MainActor
final class DevToolRegistry: ObservableObject {
    static let shared = DevToolRegistry()

    @Published private(set) var tools: [AnyDevTool] = []

    private init() {
        bootstrap()
    }

    func register<T: DevTool>(_ tool: T) {
        if !tools.contains(where: { $0.id == tool.id }) {
            tools.append(AnyDevTool(tool))
        }
    }

    private func bootstrap() {
        // Input / Output
        register(Base64EncoderDevTool())
        register(Base64DecoderDevTool())
        register(URLEncoderDevTool())
        register(URLDecoderDevTool())
        register(URLParserDevTool())
        register(ASCIIHexConverterDevTool())
        register(UnicodeInspectorDevTool())
        register(HTMLEntityEncoderDevTool())
        register(HTMLEntityDecoderDevTool())
        register(QueryStringParserDevTool())

        // UI Design
        register(ColorConverterDevTool())
        register(ColorPaletteGeneratorDevTool())
        register(GradientBuilderDevTool())
        register(BezierCurveVisualizerDevTool())
        register(ContrastCheckerDevTool())
        register(ColorMixerDevTool())
        register(ShadowGeneratorDevTool())
        register(TypographyScaleDevTool())
        register(SFSymbolsBrowserDevTool())
        register(LayoutGridPreviewDevTool())

        // Data
        register(UUIDGeneratorDevTool())
        register(UUIDBulkGeneratorDevTool())
        register(JSONFormatterDevTool())
        register(JSONValidatorDevTool())
        register(JSONDiffDevTool())
        register(YAMLParserDevTool())
        register(CSVParserDevTool())
        register(XMLFormatterDevTool())
        register(DateFormatterDevTool())
        register(TimezoneConverterDevTool())
        register(NumberFormatterDevTool())

        // Networking
        register(HTTPRequestTesterDevTool())
        register(HeaderInspectorDevTool())
        register(NetworkReachabilityDevTool())
        register(APIResponseViewerDevTool())
        register(WebSocketMonitorDevTool())
        register(DNSLookupDevTool())
        register(IPInfoDevTool())

        // Diagnostics
        register(VerboseLoggerDevTool())
        register(CrashLogViewerDevTool())
        register(ThreadInspectorDevTool())
        register(AppStateInspectorDevTool())
        register(ViewHierarchyInspectorDevTool())

        // Performance
        register(MemoryMonitorDevTool())
        register(CPUMonitorDevTool())
        register(FPSMonitorDevTool())
        register(LaunchTimeTrackerDevTool())
        register(EnergyImpactMonitorDevTool())

        // Storage
        register(FileExplorerDevTool())
        register(UserDefaultsInspectorDevTool())
        register(CacheViewerDevTool())
        register(DiskUsageAnalyzerDevTool())
        register(SQLiteBrowserDevTool())

        // Security
        register(KeychainViewerDevTool())
        register(PermissionInspectorDevTool())
        register(HashGeneratorDevTool())
        register(JWTDecoderDevTool())
        register(EncryptionToolDevTool())

        // Utilities
        register(RegexTesterDevTool())
        register(TextDiffDevTool())
        register(MarkdownPreviewDevTool())
        register(TextCaseConverterDevTool())
        register(ClipboardInspectorDevTool())
        register(LoremIpsumGeneratorDevTool())

        // Debugging
        register(LogStreamViewerDevTool())
        register(BreakpointManagerDevTool())
        register(RuntimeInspectorDevTool())
        register(SDKModuleInspectorDevTool())
        register(SDKConfigValidatorDevTool())
        register(SDKEventLoggerDevTool())
        register(SDKRuntimeStateDevTool())
        register(SDKDependencyGraphDevTool())
        register(SDKIntegrationValidatorDevTool())

        // System
        register(DeviceInfoDevTool())
        register(OSVersionInspectorDevTool())
        register(BatteryStatusDevTool())

        // Automation
        register(ScriptRunnerDevTool())
        register(TaskAutomationDevTool())
    }
}

// MARK: - Main View

struct DevToolsMainView: View {
    @StateObject private var registry = DevToolRegistry.shared
    @State private var searchText = ""
    @State private var expandedCategories: Set<DevToolCategory> = Set(DevToolCategory.allCases)

    private var filteredTools: [AnyDevTool] {
        if searchText.isEmpty {
            return registry.tools
        } else {
            return registry.tools.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var toolsByCategory: [DevToolCategory: [AnyDevTool]] {
        Dictionary(grouping: filteredTools) { $0.category }
    }

    var body: some View {
        List {
            ForEach(DevToolCategory.allCases) { category in
                if let tools = toolsByCategory[category], !tools.isEmpty {
                    Section(isExpanded: Binding(
                        get: {
                            let containsCategory = expandedCategories.contains(category)
                            return containsCategory
                        },
                        set: { isExpanded in
                            if isExpanded {
                                expandedCategories.insert(category)
                            } else {
                                expandedCategories.remove(category)
                            }
                        }
                    )) {
                        ForEach(tools) { tool in
                            NavigationLink(destination: tool.render().navigationTitle(tool.name)) {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tool.name)
                                            .font(.headline)
                                        Text(tool.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: tool.icon)
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Label(category.rawValue, systemImage: category.icon)
                            Spacer()
                            Text("\(tools.count)")
                                .font(.caption2.monospaced())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Dev Tools")
        .searchable(text: $searchText, prompt: "Search tools...")
        .overlay {
            if filteredTools.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if registry.tools.isEmpty {
                ContentUnavailableView {
                    Label("No Tools Registered", systemImage: "hammer")
                } description: {
                    Text("Register tools to see them here.")
                }
            }
        }
    }
}

// MARK: - Shared Models & Extensions

struct IPData: Codable {
    let ip: String?
    let city: String?
    let region: String?
    let country: String?
    let loc: String?
    let org: String?
    let postal: String?
    let timezone: String?
}

struct VerboseLog: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let level: String
    let message: String
}

extension Color {
    func getComponents() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}
