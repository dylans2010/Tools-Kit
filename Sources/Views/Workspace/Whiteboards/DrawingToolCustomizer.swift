import SwiftUI

struct DrawingToolCustomizer: View {
    let tool: WhiteboardViewTools.ToolEntry
    @Binding var colorHex: String
    @Binding var lineWidth: Double
    @Binding var opacity: Double

    @State private var showColorGrid = false

    private let presetColors: [(String, String)] = [
        ("FFFFFF", "White"),
        ("000000", "Black"),
        ("EF4444", "Red"),
        ("F97316", "Orange"),
        ("F59E0B", "Amber"),
        ("EAB308", "Yellow"),
        ("84CC16", "Lime"),
        ("22C55E", "Green"),
        ("10B981", "Emerald"),
        ("14B8A6", "Teal"),
        ("06B6D4", "Cyan"),
        ("0EA5E9", "Sky"),
        ("3B82F6", "Blue"),
        ("6366F1", "Indigo"),
        ("8B5CF6", "Violet"),
        ("A855F7", "Purple"),
        ("D946EF", "Fuchsia"),
        ("EC4899", "Pink"),
        ("F43F5E", "Rose"),
        ("78716C", "Stone"),
    ]

    var body: some View {
        VStack(spacing: 12) {
            header

            Divider().opacity(0.3)

            colorSection
            thicknessSection
            opacitySection

            if tool.configuration.drawingStyle != .solid {
                stylePreview
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: tool.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color(hex: colorHex))
                        .opacity(opacity)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(tool.displayName)
                    .font(.headline)
                Text(tool.configuration.drawingStyle.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Color")
                    .font(.subheadline.weight(.medium))
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: colorHex))
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 10), spacing: 6) {
                ForEach(presetColors, id: \.0) { hex, _ in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            colorHex = hex
                        }
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 26, height: 26)
                            .overlay(
                                Circle()
                                    .stroke(colorHex == hex ? Color.white : Color.white.opacity(0.15), lineWidth: colorHex == hex ? 2.5 : 1)
                            )
                            .scaleEffect(colorHex == hex ? 1.15 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var thicknessSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Thickness")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(String(format: "%.1f", lineWidth))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: max(4, lineWidth * 0.8), height: max(4, lineWidth * 0.8))
                    .frame(width: 30, height: 30)

                Slider(
                    value: $lineWidth,
                    in: tool.configuration.minStrokeWidth...tool.configuration.maxStrokeWidth,
                    step: 0.5
                )
                .tint(Color(hex: colorHex))
            }

            HStack(spacing: 8) {
                ForEach([1.0, 3.0, 6.0, 10.0, 16.0, 24.0], id: \.self) { preset in
                    let clamped = min(max(preset, tool.configuration.minStrokeWidth), tool.configuration.maxStrokeWidth)
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { lineWidth = clamped }
                    } label: {
                        Circle()
                            .fill(abs(lineWidth - clamped) < 0.5 ? Color.white : Color.white.opacity(0.2))
                            .frame(width: max(6, clamped * 0.7), height: max(6, clamped * 0.7))
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(abs(lineWidth - clamped) < 0.5 ? Color.accentColor.opacity(0.2) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var opacitySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Intensity")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(opacity * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Slider(value: $opacity, in: 0.05...1.0, step: 0.05)
                    .tint(Color(hex: colorHex))

                Image(systemName: "circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: colorHex))
            }

            HStack(spacing: 8) {
                ForEach([0.1, 0.25, 0.5, 0.75, 1.0], id: \.self) { preset in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { opacity = preset }
                    } label: {
                        Text("\(Int(preset * 100))%")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(abs(opacity - preset) < 0.05 ? .white : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(abs(opacity - preset) < 0.05 ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var stylePreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Preview")
                .font(.subheadline.weight(.medium))

            stylePreviewCanvas
        }
    }

    private var stylePreviewCanvas: some View {
        Canvas { context, size in
            var path = Path()
            let midY = size.height / 2
            path.move(to: CGPoint(x: 16, y: midY))

            let steps = 40
            for i in 0...steps {
                let x = 16 + (size.width - 32) * Double(i) / Double(steps)
                let wave = sin(Double(i) * 0.3) * 8
                path.addLine(to: CGPoint(x: x, y: midY + wave))
            }

            let resolvedColor = Color(hex: colorHex)
            context.opacity = opacity
            context.stroke(
                path,
                with: .color(resolvedColor),
                style: strokeStyle(for: tool.configuration.drawingStyle)
            )
        }
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
        )
    }

    private func strokeStyle(for style: WhiteboardViewTools.DrawingStyle) -> StrokeStyle {
        switch style {
        case .dashed:
            return StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, dash: [lineWidth * 3, lineWidth * 2])
        case .dotted:
            return StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, dash: [1, lineWidth * 2])
        default:
            return StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        }
    }
}
