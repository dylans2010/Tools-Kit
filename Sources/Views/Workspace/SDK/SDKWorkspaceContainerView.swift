import SwiftUI

struct SDKWorkspaceContainerView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State private var isRunning = false
    @State private var activeSheet: WorkspaceSheet?

    private enum WorkspaceSheet: Identifiable, Equatable {
        case navigator
        case inspector
        case console
        case runConfiguration

        var id: String {
            switch self {
            case .navigator: return "navigator"
            case .inspector: return "inspector"
            case .console: return "console"
            case .runConfiguration: return "runConfiguration"
            }
        }

        var title: String {
            switch self {
            case .navigator: return "Navigator"
            case .inspector: return "Inspector"
            case .console: return "Console"
            case .runConfiguration: return "Run Config"
            }
        }
    }

    private var isCompact: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                topToolbar
                Divider()
                if isCompact || geo.size.width < 760 {
                    compactWorkspace
                } else {
                    regularWorkspace(in: geo)
                }
            }
            .background(Color(.systemGroupedBackground))
            .onDisappear { state.saveSnapshot() }
            .sheet(item: $activeSheet) { sheet in
                NavigationStack {
                    sheetContent(sheet)
                        .navigationTitle(sheet.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { activeSheet = nil }
                            }
                        }
                }
                .presentationDetents(sheet == .console ? [.medium, .large] : [.large])
                .presentationDragIndicator(.visible)
            }
        }
        .navigationTitle("SDK IDE")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func regularWorkspace(in geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if !state.layout.isLeftCollapsed {
                    SDKNavigatorView()
                        .frame(width: clampedLeftWidth)
                    dragHandle {
                        state.layout.leftSidebarWidth = min(max(180, state.layout.leftSidebarWidth + $0.width), max(260, geo.size.width * 0.45))
                        state.saveSnapshot()
                    }
                }

                SDKProjectEditorView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !state.layout.isRightCollapsed {
                    dragHandle {
                        state.layout.rightInspectorWidth = min(max(220, state.layout.rightInspectorWidth - $0.width), max(280, geo.size.width * 0.5))
                        state.saveSnapshot()
                    }
                    SDKInspectorPanelView()
                        .frame(width: clampedRightWidth)
                }
            }

            if !state.layout.isBottomCollapsed {
                dragHandle(vertical: true) {
                    state.layout.bottomPanelHeight = min(max(120, state.layout.bottomPanelHeight - $0.height), max(180, geo.size.height * 0.55))
                    state.saveSnapshot()
                }
                SDKConsoleView(embedded: true)
                    .frame(height: clampedBottomHeight)
            }
        }
    }

    private var compactWorkspace: some View {
        SDKProjectEditorView()
            .safeAreaInset(edge: .bottom) {
                compactBottomBar
            }
    }

    private var compactBottomBar: some View {
        HStack(spacing: 10) {
            Button { activeSheet = .navigator } label: { Label("Files", systemImage: "sidebar.left") }
            Button { activeSheet = .inspector } label: { Label("Inspect", systemImage: "info.circle") }
            Button { activeSheet = .console } label: { Label("Console", systemImage: "terminal") }
            Button { activeSheet = .runConfiguration } label: { Label("Run", systemImage: "slider.horizontal.3") }
        }
        .font(.caption.weight(.semibold))
        .labelStyle(.iconOnly)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var clampedLeftWidth: CGFloat { CGFloat(min(max(180, state.layout.leftSidebarWidth), 420)) }
    private var clampedRightWidth: CGFloat { CGFloat(min(max(220, state.layout.rightInspectorWidth), 500)) }
    private var clampedBottomHeight: CGFloat { CGFloat(min(max(120, state.layout.bottomPanelHeight), 420)) }

    private var topToolbar: some View {
        HStack(spacing: 10) {
            Label("SDK", systemImage: "hammer.circle.fill")
                .font(.headline)
            Spacer()

            if isCompact {
                Menu {
                    Button { activeSheet = .navigator } label: { Label("Navigator", systemImage: "sidebar.left") }
                    Button { activeSheet = .inspector } label: { Label("Inspector", systemImage: "sidebar.right") }
                    Button { activeSheet = .console } label: { Label("Console", systemImage: "terminal") }
                    Button { activeSheet = .runConfiguration } label: { Label("Run Configuration", systemImage: "slider.horizontal.3") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            } else {
                Button { toggle(\.isLeftCollapsed) } label: { Image(systemName: state.layout.isLeftCollapsed ? "sidebar.left" : "sidebar.left.hide") }
                    .buttonStyle(.borderless)
                Button { toggle(\.isRightCollapsed) } label: { Image(systemName: state.layout.isRightCollapsed ? "sidebar.right" : "sidebar.right.hide") }
                    .buttonStyle(.borderless)
                Button { toggle(\.isBottomCollapsed) } label: { Image(systemName: state.layout.isBottomCollapsed ? "rectangle.bottomthird.inset.filled" : "rectangle.bottomthird.inset") }
                    .buttonStyle(.borderless)
                NavigationLink { SDKRunConfigurationView() } label: { Label("Config", systemImage: "slider.horizontal.3") }
                    .buttonStyle(.bordered)
            }

            Button {
                Task {
                    isRunning = true
                    defer { isRunning = false }
                    _ = await state.executeGuarded("SDK Run") {
                        try await SDKExecutionCoordinator.shared.executeSelectedRunConfiguration()
                    }
                    state.recalculateDiagnostics()
                }
            } label: {
                Label(isRunning ? "Running" : "Run", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.thinMaterial)
    }

    @ViewBuilder
    private func sheetContent(_ sheet: WorkspaceSheet) -> some View {
        switch sheet {
        case .navigator: SDKNavigatorView()
        case .inspector: SDKInspectorPanelView()
        case .console: SDKConsoleView(embedded: true)
        case .runConfiguration: SDKRunConfigurationView()
        }
    }

    private func toggle(_ keyPath: WritableKeyPath<SDKWorkspaceLayout, Bool>) {
        state.layout[keyPath: keyPath].toggle()
        state.saveSnapshot()
    }

    private func dragHandle(vertical: Bool = false, onChanged: @escaping (CGSize) -> Void) -> some View {
        Rectangle()
            .fill(.secondary.opacity(0.2))
            .frame(width: vertical ? nil : 4, height: vertical ? 4 : nil)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { onChanged($0.translation) })
    }
}
