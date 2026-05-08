import SwiftUI

struct SDKWorkspaceContainerView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @State private var isRunning = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                topToolbar
                Divider()
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
            .background(Color(.systemGroupedBackground))
            .onDisappear {
                state.saveSnapshot()
            }
        }
        .navigationTitle("SDK IDE")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var clampedLeftWidth: CGFloat { CGFloat(min(max(180, state.layout.leftSidebarWidth), 420)) }
    private var clampedRightWidth: CGFloat { CGFloat(min(max(220, state.layout.rightInspectorWidth), 500)) }
    private var clampedBottomHeight: CGFloat { CGFloat(min(max(120, state.layout.bottomPanelHeight), 420)) }

    private var topToolbar: some View {
        HStack(spacing: 10) {
            Label("SDK Workspace", systemImage: "hammer.circle.fill")
                .font(.headline)
            Spacer()
            Button {
                state.layout.isLeftCollapsed.toggle()
                state.saveSnapshot()
            } label: {
                Image(systemName: state.layout.isLeftCollapsed ? "sidebar.left" : "sidebar.left.hide")
            }
            .buttonStyle(.borderless)

            Button {
                state.layout.isRightCollapsed.toggle()
                state.saveSnapshot()
            } label: {
                Image(systemName: state.layout.isRightCollapsed ? "sidebar.right" : "sidebar.right.hide")
            }
            .buttonStyle(.borderless)

            Button {
                state.layout.isBottomCollapsed.toggle()
                state.saveSnapshot()
            } label: {
                Image(systemName: state.layout.isBottomCollapsed ? "rectangle.bottomthird.inset.filled" : "rectangle.bottomthird.inset")
            }
            .buttonStyle(.borderless)

            Divider().frame(height: 18)

            Button {
                Task {
                    isRunning = true
                    defer { isRunning = false }
                    _ = try? await SDKExecutionCoordinator.shared.executeSelectedRunConfiguration()
                    state.recalculateDiagnostics()
                }
            } label: {
                Label(isRunning ? "Running..." : "Run", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)

            NavigationLink {
                SDKRunConfigurationView()
            } label: {
                Label("Run Config", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.thinMaterial)
    }

    private func dragHandle(vertical: Bool = false, onChanged: @escaping (CGSize) -> Void) -> some View {
        Rectangle()
            .fill(.secondary.opacity(0.2))
            .frame(width: vertical ? nil : 4, height: vertical ? 4 : nil)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { onChanged($0.translation) }
            )
    }
}
