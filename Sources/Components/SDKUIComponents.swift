import SwiftUI

/// A collection of modern, monochrome UI components optimized for the ToolsKit SDK Workspace.
/// These components follow a clean design language with heavy use of SF Symbols and subtexts.

// MARK: - Semantic Colors

extension Color {
    static let sdkSuccess = Color.green
    static let sdkWarning = Color.orange
    static let sdkError = Color.red
}

// MARK: - SDK Status Pill

struct SDKStatusPill: View {
    let label: String
    let systemImage: String?
    let color: Color
    var isCapsule: Bool = true

    init(_ label: String, systemImage: String? = nil, color: Color = .secondary, isCapsule: Bool = true) {
        self.label = label
        self.systemImage = systemImage
        self.color = color
        self.isCapsule = isCapsule
    }

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .foregroundStyle(color)
        .clipShape(isCapsule ? AnyShape(Capsule()) : AnyShape(RoundedRectangle(cornerRadius: 6)))
    }
}

// MARK: - SDK Section Header

struct SDKSectionHeader: View {
    let title: String
    let subtitle: String?
    let systemImage: String?
    var alignment: HorizontalAlignment = .center

    init(_ title: String, subtitle: String? = nil, systemImage: String? = nil, alignment: HorizontalAlignment = .center) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.alignment = alignment
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            HStack(spacing: 8) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.secondary)
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(alignment == .center ? .center : .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
        .padding(.vertical, 8)
    }
}

// MARK: - SDK Modern Card

struct SDKModernCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(padding)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - SDK Stat Pill

struct SDKStatPill: View {
    let label: String
    let value: String
    let color: Color
    var icon: String? = nil

    init(label: String, value: String, color: Color = .blue, icon: String? = nil) {
        self.label = label
        self.value = value
        self.color = color
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                }
                Text(value)
                    .font(.system(.subheadline, design: .rounded).bold())
            }
            .foregroundColor(color)

            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - SDK Action Tile

struct SDKActionTile: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let color: Color
    let action: () -> Void

    init(_ title: String, subtitle: String? = nil, systemImage: String, color: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notification Components

struct SDKNotificationBanner: View {
    let message: String
    let type: NotificationType

    enum NotificationType {
        case success, warning, error, info

        var color: Color {
            switch self {
            case .success: return .sdkSuccess
            case .warning: return .sdkWarning
            case .error: return .sdkError
            case .info: return .blue
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.octagon.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding()
        .background(type.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(type.color.opacity(0.2), lineWidth: 1)
        )
    }
}
