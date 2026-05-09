/*
 REDESIGN SUMMARY:
 - Standardized navigation using NavigationStack and inline display mode.
 - Replaced manual toolbar buttons with native ToolbarItem placements.
 - Standardized the 'Run' button using a prominent capsule style and SF Symbol effects.
 - Modernized the IDE layout with semantic background colors and thin material toolbars.
 - Replaced manual sheet presentation with native .presentationDetents([.medium, .large]).
 - Standardized compact IDE navigation with a bottom bar using SF Symbols and Labels.
 - Strictly preserved all SDKRuntimeWorkspaceState management and IDE layout logic.
 */

import SwiftUI

struct SDKWorkspaceContainerView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State private var isRunning = false
    @State private var activeSheet: WorkspaceSheet?

    private enum WorkspaceSheet: Identifiable, Equatable {
        case navigator, inspector, console, runConfiguration
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
                                Button { activeSheet = nil } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
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
        HStack(spacing: 0) {
            compactTabItem(title: "Files", icon: "sidebar.left", sheet: .navigator)
            compactTabItem(title: "Inspect", icon: "info.circle", sheet: .inspector)
            compactTabItem(title: "Console", icon: "terminal", sheet: .console)
            compactTabItem(title: "Config", icon: "slider.horizontal.3", sheet: .runConfiguration)
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
    }

    private func compactTabItem(title: String, icon: String, sheet: WorkspaceSheet) -> some View {
        Button {
            activeSheet = sheet
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(activeSheet == sheet ? .accentColor : .secondary)
            .frame(maxWidth: .infinity)
        }
    }

    private var clampedLeftWidth: CGFloat { CGFloat(min(max(180, state.layout.leftSidebarWidth), 420)) }
    private var clampedRightWidth: CGFloat { CGFloat(min(max(220, state.layout.rightInspectorWidth), 500)) }
    private var clampedBottomHeight: CGFloat { CGFloat(min(max(120, state.layout.bottomPanelHeight), 420)) }

    private var topToolbar: some View {
        HStack(spacing: 16) {
            Label("SDK IDE", systemImage: "hammer.fill")
                .font(.subheadline.bold())
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1), in: Capsule())

            Spacer()

            if !isCompact {
                HStack(spacing: 12) {
                    HStack(spacing: 0) {
                        toolbarIconButton(icon: "sidebar.left", active: !state.layout.isLeftCollapsed) { toggle(\.isLeftCollapsed) }
                        Divider().frame(height: 16).padding(.horizontal, 4)
                        toolbarIconButton(icon: "sidebar.bottom", active: !state.layout.isBottomCollapsed) { toggle(\.isBottomCollapsed) }
                        Divider().frame(height: 16).padding(.horizontal, 4)
                        toolbarIconButton(icon: "sidebar.right", active: !state.layout.isRightCollapsed) { toggle(\.isRightCollapsed) }
                    }
                    .padding(4)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))

                    Button { activeSheet = .runConfiguration } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            Button {
                runProject()
            } label: {
                HStack(spacing: 6) {
                    if isRunning {
                        ProgressView().controlSize(.mini)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(isRunning ? "Running" : "Run")
                }
                .font(.caption.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isRunning ? Color.secondary.opacity(0.2) : Color.accentColor)
                .foregroundStyle(isRunning ? Color.secondary : Color.white)
                .clipShape(Capsule())
            }
            .disabled(isRunning)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func toolbarIconButton(icon: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(active ? Color.accentColor : .secondary)
                .frame(width: 32, height: 32)
                .background(active ? Color.accentColor.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private func runProject() {
        Task {
            isRunning = true
            defer { isRunning = false }
            _ = await state.executeGuarded("SDK Run") {
                try await SDKExecutionCoordinator.shared.executeSelectedRunConfiguration()
            }
            state.recalculateDiagnostics()
        }
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
            .fill(Color.secondary.opacity(0.2))
            .frame(width: vertical ? nil : 4, height: vertical ? 4 : nil)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { onChanged($0.translation) })
    }
}
