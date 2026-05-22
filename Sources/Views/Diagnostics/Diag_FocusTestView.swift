import SwiftUI

struct Diag_FocusTestView: View {
    @State private var focusPoint: CGPoint = .zero
    @State private var showRing = false

    var body: some View {
        VStack(spacing: 0) {
            Text("Tap anywhere to set focus point")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)

            GeometryReader { geo in
                ZStack {
                    // Focus chart pattern
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let maxRadius = min(size.width, size.height) / 2
                        for i in stride(from: 0, to: maxRadius, by: 8) {
                            let rect = CGRect(x: center.x - i, y: center.y - i, width: i * 2, height: i * 2)
                            context.stroke(Path(ellipseIn: rect), with: .color(.primary.opacity(0.3)), lineWidth: 0.5)
                        }
                        // Crosshairs
                        var hLine = Path()
                        hLine.move(to: CGPoint(x: 0, y: center.y))
                        hLine.addLine(to: CGPoint(x: size.width, y: center.y))
                        context.stroke(hLine, with: .color(.primary.opacity(0.2)), lineWidth: 0.5)

                        var vLine = Path()
                        vLine.move(to: CGPoint(x: center.x, y: 0))
                        vLine.addLine(to: CGPoint(x: center.x, y: size.height))
                        context.stroke(vLine, with: .color(.primary.opacity(0.2)), lineWidth: 0.5)

                        // Fine lines for focus testing
                        for i in stride(from: 2, to: maxRadius, by: 3) {
                            let angle = Double(i) * .pi * 2 / maxRadius
                            var line = Path()
                            line.move(to: center)
                            let end = CGPoint(x: center.x + cos(angle) * maxRadius, y: center.y + sin(angle) * maxRadius)
                            line.addLine(to: end)
                            context.stroke(line, with: .color(.primary.opacity(0.15)), lineWidth: 0.5)
                        }
                    }

                    // Focus ring
                    if showRing {
                        Circle()
                            .stroke(Color.yellow, lineWidth: 2)
                            .frame(width: 80, height: 80)
                            .position(focusPoint)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Text at various sizes for focus testing
                    VStack(spacing: 4) {
                        Text("FOCUS TEST").font(.system(size: 24, weight: .bold))
                        Text("Check camera autofocus with this pattern").font(.system(size: 12))
                        Text("Fine detail text for close-up focus testing").font(.system(size: 8))
                        Text("Very small text 4pt").font(.system(size: 4))
                    }
                    .foregroundStyle(.primary)
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    focusPoint = location
                    withAnimation(.spring(response: 0.2)) {
                        showRing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showRing = false }
                    }
                }
            }
        }
        .navigationTitle("Focus Test")
        .navigationBarTitleDisplayMode(.inline)
    }
}
