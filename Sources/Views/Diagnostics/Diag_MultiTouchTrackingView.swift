import SwiftUI

struct Diag_MultiTouchTrackingView: View {
    @State private var activeTouches: [UITouch] = []
    @State private var touchCount = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Active Touches: \(touchCount)")
                    .font(.headline.monospacedDigit())
                Spacer()
                Text("Touch the screen with multiple fingers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            MultiTouchCanvas(touchCount: $touchCount)
                .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Multi-Touch Tracking")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MultiTouchCanvas: UIViewRepresentable {
    @Binding var touchCount: Int

    func makeUIView(context: Context) -> MultiTouchView {
        let view = MultiTouchView()
        view.onTouchCountChanged = { count in
            DispatchQueue.main.async { touchCount = count }
        }
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: MultiTouchView, context: Context) {}
}

class MultiTouchView: UIView {
    var onTouchCountChanged: ((Int) -> Void)?
    private var touchPositions: [UITouch: CGPoint] = [:]
    private let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemPink, .systemYellow, .systemCyan, .systemMint, .systemIndigo]

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTouches(event: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTouches(event: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { touchPositions.removeValue(forKey: touch) }
        onTouchCountChanged?(touchPositions.count)
        setNeedsDisplay()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { touchPositions.removeValue(forKey: touch) }
        onTouchCountChanged?(touchPositions.count)
        setNeedsDisplay()
    }

    private func updateTouches(event: UIEvent?) {
        guard let allTouches = event?.allTouches else { return }
        touchPositions.removeAll()
        for touch in allTouches where touch.phase != .ended && touch.phase != .cancelled {
            touchPositions[touch] = touch.location(in: self)
        }
        onTouchCountChanged?(touchPositions.count)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        for (index, position) in touchPositions.values.enumerated() {
            let color = colors[index % colors.count]
            context.setFillColor(color.withAlphaComponent(0.3).cgColor)
            context.fillEllipse(in: CGRect(x: position.x - 40, y: position.y - 40, width: 80, height: 80))
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: CGRect(x: position.x - 10, y: position.y - 10, width: 20, height: 20))

            let label = "\(index + 1)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let size = label.size(withAttributes: attrs)
            label.draw(at: CGPoint(x: position.x - size.width / 2, y: position.y - 55), withAttributes: attrs)
        }
    }
}
