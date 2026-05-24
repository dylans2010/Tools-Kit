import SwiftUI

struct Diag_DigitizerTestView: View {
    @State private var touchPoints: [CGPoint] = []
    @State private var allTouchedZones: Set<Int> = []
    @State private var isDrawing = false
    @State private var gridColumns = 5
    @State private var gridRows = 8
    @State private var touchCount = 0
    @State private var maxSimultaneous = 0
    @State private var showResults = false

    private var totalZones: Int { gridColumns * gridRows }
    private var coverage: Double { Double(allTouchedZones.count) / Double(totalZones) * 100 }

    var body: some View {
        VStack(spacing: 0) {
            if showResults {
                resultView
            } else {
                testView
            }
        }
        .navigationTitle("Digitizer Test")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(showResults ? "Test" : "Results") {
                    showResults.toggle()
                }
            }
        }
    }

    private var testView: some View {
        VStack(spacing: 0) {
            Text("Drag your finger across the entire screen")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)

            GeometryReader { geo in
                let cellW = geo.size.width / CGFloat(gridColumns)
                let cellH = geo.size.height / CGFloat(gridRows)

                ZStack {
                    ForEach(0..<totalZones, id: \.self) { index in
                        let row = index / gridColumns
                        let col = index % gridColumns
                        Rectangle()
                            .fill(allTouchedZones.contains(index) ? Color.green.opacity(0.4) : Color(.tertiarySystemFill))
                            .border(Color(.separator), width: 0.5)
                            .frame(width: cellW, height: cellH)
                            .position(
                                x: CGFloat(col) * cellW + cellW / 2,
                                y: CGFloat(row) * cellH + cellH / 2
                            )
                    }

                    ForEach(Array(touchPoints.enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                            .position(point)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let point = value.location
                            touchPoints = [point]
                            touchCount += 1

                            let col = Int(point.x / cellW)
                            let row = Int(point.y / cellH)
                            if col >= 0 && col < gridColumns && row >= 0 && row < gridRows {
                                allTouchedZones.insert(row * gridColumns + col)
                            }
                        }
                        .onEnded { _ in
                            touchPoints.removeAll()
                        }
                )
            }

            HStack {
                Text("Coverage: \(Int(coverage))%")
                    .font(.caption.monospaced())
                Spacer()
                Text("\(allTouchedZones.count)/\(totalZones) zones")
                    .font(.caption.monospaced())
                Spacer()
                Button("Reset") {
                    allTouchedZones.removeAll()
                    touchCount = 0
                }
                .font(.caption)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
        }
    }

    private var resultView: some View {
        Form {
            Section("Digitizer Results") {
                VStack(spacing: 12) {
                    Image(systemName: coverage >= 90 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(coverage >= 90 ? .green : coverage >= 60 ? .orange : .red)
                    Text(coverage >= 90 ? "Digitizer Pass" : coverage >= 60 ? "Partial Coverage" : "Incomplete")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Statistics") {
                LabeledContent("Zone Coverage") {
                    Text(String(format: "%.1f%%", coverage))
                        .foregroundStyle(coverage >= 90 ? .green : .orange)
                }
                LabeledContent("Zones Touched") {
                    Text("\(allTouchedZones.count) / \(totalZones)")
                }
                LabeledContent("Touch Events") {
                    Text("\(touchCount)")
                }
                LabeledContent("Grid Size") {
                    Text("\(gridColumns) x \(gridRows)")
                }
            }

            Section("Digitizer Info") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Tests touch screen sensor coverage", systemImage: "hand.point.up.left.fill")
                        .font(.caption)
                    Label("Detects dead zones in touch panel", systemImage: "square.dashed")
                        .font(.caption)
                    Label("Useful after screen replacement", systemImage: "display")
                        .font(.caption)
                    Label("100% coverage = fully functional digitizer", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
