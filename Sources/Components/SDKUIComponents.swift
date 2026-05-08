import SwiftUI

public enum SDKStatus: String, CaseIterable {
    case success, warning, error, info

    public var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .info: return .blue
        }
    }

    public var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        case .info: return "info.circle.fill"
        }
    }
}

public struct SDKStatusPill: View {
    public let status: SDKStatus
    public let text: String

    public init(status: SDKStatus, text: String) {
        self.status = status
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(text)
        }
        .font(.system(size: 10, weight: .bold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .foregroundStyle(status.statusColor)
        .clipShape(Capsule())
    }
}

// Extension to avoid ambiguity if another statusColor exists
private extension SDKStatus {
    var statusColor: Color {
        self.color
    }
}

public struct SDKSectionHeader: View {
    public let title: String
    public let subtext: String?
    public let isCentered: Bool

    public init(title: String, subtext: String? = nil, isCentered: Bool = false) {
        self.title = title
        self.subtext = subtext
        self.isCentered = isCentered
    }

    public var body: some View {
        VStack(alignment: isCentered ? .center : .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            if let subtext = subtext {
                Text(subtext)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(isCentered ? .center : .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: isCentered ? .center : .leading)
        .padding(.vertical, 8)
    }
}

public struct SDKModernCard<Content: View>: View {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

public extension View {
    func sdkSuccessText() -> some View {
        self.foregroundStyle(.green)
    }

    func sdkWarningText() -> some View {
        self.foregroundStyle(.orange)
    }

    func sdkErrorText() -> some View {
        self.foregroundStyle(.red)
    }

    func sdkSubtext() -> some View {
        self.font(.caption).foregroundStyle(.secondary)
    }
}
