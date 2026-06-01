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

        // New Tools - Encoding
        register(ROT13CipherDevTool())
        register(MorseCodeDevTool())
        register(BinaryConverterDevTool())
        register(OctalConverterDevTool())

        // New Tools - Data
        register(CRONParserDevTool())
        register(PlaceholderDataDevTool())
        register(ProtobufInspectorDevTool())
        register(TOMLParserDevTool())
        register(INIParserDevTool())

        // New Tools - Networking
        register(CURLConverterDevTool())
        register(SSLCertInspectorDevTool())
        register(ProxyConfigDevTool())
        register(HTTPHeaderAnalyzerDevTool())

        // New Tools - Security
        register(PasswordGeneratorDevTool())
        register(CSRFTokenDevTool())
        register(SecretScannerDevTool())

        // New Tools - UI Design
        register(SpacingCalculatorDevTool())
        register(ResponsiveBreakpointDevTool())
        register(IconPreviewDevTool())

        // New Tools - Utilities
        register(EpochConverterDevTool())
        register(SlugGeneratorDevTool())
        register(WordCounterDevTool())
        register(FileHashDevTool())
        register(CharacterEscaperDevTool())

        // New Tools - Diagnostics
        register(AccessibilityAuditDevTool())
        register(LocaleInspectorDevTool())

        // New Tools - Performance
        register(BundleSizeAnalyzerDevTool())

        // SDK Builder Specialized Tools
        register(SDKBuildAnalyzerDevTool())
        register(SDKAssetOptimizerDevTool())
        register(SDKSecurityAuditDevTool())

        // REQUIRED CORE DEVTOOLS
        register(DesignerDevTool())
        register(SearchDocsDevTool())
        register(DatabaseCreateDevTool())
    }
}

// MARK: - Main View

struct DevToolsMainView: View {
    @StateObject private var registry = DevToolRegistry.shared
    @State private var searchText = ""
    @State private var selectedCategory: DevToolCategory?

    private var filteredTools: [AnyDevTool] {
        var tools = registry.tools
        if let cat = selectedCategory {
            tools = tools.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            tools = tools.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        return tools.sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Fast Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    filterChip(nil, label: "All")
                    ForEach(DevToolCategory.allCases) { category in
                        filterChip(category, label: category.rawValue)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color(uiColor: .systemBackground))
            Divider()

            // Flat, Developer-First Tool Index
            List {
                ForEach(filteredTools) { tool in
                    NavigationLink(destination: tool.render().navigationTitle(tool.name)) {
                        HStack(spacing: 12) {
                            Image(systemName: tool.icon)
                                .font(.system(size: 14))
                                .frame(width: 24, alignment: .center)
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(tool.name)
                                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                                Text(tool.description)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(tool.category.rawValue.uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("ToolsKit OS")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Index lookup...")
        .overlay {
            if filteredTools.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private func filterChip(_ category: DevToolCategory?, label: String) -> some View {
        Button {
            selectedCategory = category
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    selectedCategory == category
                        ? Color.primary
                        : Color.secondary.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 4)
                )
                .foregroundStyle(selectedCategory == category ? Color(uiColor: .systemBackground) : .primary)
        }
        .buttonStyle(.plain)
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
    var timestamp = Date()
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


