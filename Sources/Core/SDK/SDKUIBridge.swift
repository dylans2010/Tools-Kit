import SwiftUI

/// Binds SDK logic and configuration to dynamic SwiftUI views.
public final class SDKUIBridge {
    public static let shared = SDKUIBridge()

    private init() {}

    @ViewBuilder
    public func renderScreen(config: SDKScreenConfig) -> some View {
        VStack {
            ForEach(config.elements, id: \.id) { element in
                renderElement(element)
            }
        }
    }

    @ViewBuilder
    private func renderElement(_ element: SDKUIElement) -> some View {
        switch element.type {
        case .text(let content):
            Text(content)
        case .button(let label, let actionID):
            Button(label) {
                Task {
                    try? await SDKExecutionKernel.shared.execute(actionID: actionID)
                }
            }
        case .list(let scope):
            SDKDataListView(scope: scope)
        }
    }
}

public struct SDKScreenConfig: Codable {
    public let id: UUID
    public let title: String
    public let elements: [SDKUIElement]
}

public struct SDKUIElement: Codable, Identifiable {
    public let id: UUID
    public let type: SDKUIElementType
}

public enum SDKUIElementType: Codable {
    case text(String)
    case button(label: String, actionID: String)
    case list(SDKScope)
}

struct SDKDataListView: View {
    let scope: SDKScope
    @State private var items: [SDKDataItem] = []

    var body: some View {
        List(items) { item in
            VStack(alignment: .leading) {
                Text(item.title).font(.headline)
                Text(item.timestamp.formatted()).font(.caption)
            }
        }
        .task {
            items = (try? await ToolsKitSDK.shared.fetchData(scope: scope)) ?? []
        }
    }
}
