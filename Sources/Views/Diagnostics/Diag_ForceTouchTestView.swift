import SwiftUI

struct Diag_ForceTouchTestView: View {
    @State private var touchForce: CGFloat = 0
    @State private var maxForce: CGFloat = 0
    @State private var touchCount = 0
    @State private var supports3DTouch = false
    @State private var forceHistory: [CGFloat] = []

    var body: some View {
        List {
            Section("3D Touch / Haptic Touch") {
                VStack(spacing: 12) {
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(supports3DTouch ? .blue : .secondary)
                    Text(supports3DTouch ? "3D Touch Supported" : "Haptic Touch Only")
                        .font(.headline)
                    Text(supports3DTouch ? "This device has pressure-sensitive display" : "This device uses time-based Haptic Touch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Touch Pressure Test Area") {
                ForceTouchArea(touchForce: $touchForce, maxForce: $maxForce, touchCount: $touchCount, forceHistory: $forceHistory)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Section("Readings") {
                LabeledContent("Current Force") {
                    Text(String(format: "%.3f", touchForce))
                        .font(.caption.monospacedDigit())
                }
                LabeledContent("Maximum Force") {
                    Text(String(format: "%.3f", maxForce))
                        .font(.caption.monospacedDigit())
                }
                LabeledContent("Touch Count") {
                    Text("\(touchCount)")
                        .monospacedDigit()
                }
                LabeledContent("3D Touch Available") {
                    Text(supports3DTouch ? "Yes" : "No")
                        .foregroundStyle(supports3DTouch ? .green : .orange)
                }
            }

            Section("Force Capability") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 6s–XS: 3D Touch (pressure-sensitive)", systemImage: "iphone.gen1")
                        .font(.caption)
                    Label("iPhone 11+: Haptic Touch (long-press based)", systemImage: "iphone.gen2")
                        .font(.caption)
                    Label("iPad Pro: No 3D Touch", systemImage: "ipad")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Force Touch Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkCapability() }
    }

    private func checkCapability() {
        let cap = UITraitCollection.current.forceTouchCapability
        supports3DTouch = cap == .available
    }
}

struct ForceTouchArea: UIViewRepresentable {
    @Binding var touchForce: CGFloat
    @Binding var maxForce: CGFloat
    @Binding var touchCount: Int
    @Binding var forceHistory: [CGFloat]

    func makeUIView(context: Context) -> ForceTouchUIView {
        let view = ForceTouchUIView()
        view.onForceChange = { force, max in
            DispatchQueue.main.async {
                self.touchForce = force
                if max > self.maxForce { self.maxForce = max }
                self.forceHistory.append(force)
                if self.forceHistory.count > 50 { self.forceHistory.removeFirst() }
            }
        }
        view.onTouchCount = { count in
            DispatchQueue.main.async { self.touchCount = count }
        }
        return view
    }

    func updateUIView(_ uiView: ForceTouchUIView, context: Context) {}
}

class ForceTouchUIView: UIView {
    var onForceChange: ((CGFloat, CGFloat) -> Void)?
    var onTouchCount: ((Int) -> Void)?
    private var totalTouches = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        isMultipleTouchEnabled = true
        let label = UILabel()
        label.text = "Press here to test force"
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .callout)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        totalTouches += touches.count
        onTouchCount?(totalTouches)
        handleTouch(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        handleTouch(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        onForceChange?(0, 0)
        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
    }

    private func handleTouch(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let force = touch.force
        let maxPossible = touch.maximumPossibleForce
        onForceChange?(force, maxPossible)
        let intensity = min(force / max(maxPossible, 1), 1.0)
        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1 + intensity * 0.5)
    }
}
