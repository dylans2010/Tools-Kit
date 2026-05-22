import SwiftUI

struct Diag_ColorAccuracyView: View {
    @State private var selectedPattern = 0

    private let patterns = ["Color Bars", "Grayscale", "Color Wheel", "Checker"]

    var body: some View {
        VStack(spacing: 0) {
            Picker("Pattern", selection: $selectedPattern) {
                ForEach(0..<patterns.count, id: \.self) { i in
                    Text(patterns[i]).tag(i)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            switch selectedPattern {
            case 0: colorBarsPattern
            case 1: grayscalePattern
            case 2: colorWheelPattern
            case 3: checkerPattern
            default: EmptyView()
            }

            Spacer()
        }
        .navigationTitle("Color Accuracy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var colorBarsPattern: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.white.frame(maxHeight: .infinity)
                Color.yellow.frame(maxHeight: .infinity)
                Color.cyan.frame(maxHeight: .infinity)
                Color.green.frame(maxHeight: .infinity)
                Color.magenta.frame(maxHeight: .infinity)
                Color.red.frame(maxHeight: .infinity)
                Color.blue.frame(maxHeight: .infinity)
                Color.black.frame(maxHeight: .infinity)
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()

            Text("Standard SMPTE color bars — check for uniform color reproduction")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }

    private var grayscalePattern: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<16, id: \.self) { i in
                    let value = Double(i) / 15.0
                    Color(white: value)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()

            Text("16-step grayscale — each step should be distinguishable")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }

    private var colorWheelPattern: some View {
        VStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 10
                let steps = 360
                for i in 0..<steps {
                    let angle = Double(i) * .pi * 2 / Double(steps)
                    let nextAngle = Double(i + 1) * .pi * 2 / Double(steps)
                    var path = Path()
                    path.move(to: center)
                    path.addArc(center: center, radius: radius, startAngle: .radians(angle), endAngle: .radians(nextAngle), clockwise: false)
                    path.closeSubpath()
                    context.fill(path, with: .color(Color(hue: Double(i) / Double(steps), saturation: 1, brightness: 1)))
                }
            }
            .frame(height: 300)
            .padding()

            Text("Full hue spectrum — transitions should be smooth")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var checkerPattern: some View {
        VStack {
            Canvas { context, size in
                let cellSize: CGFloat = 20
                let cols = Int(size.width / cellSize) + 1
                let rows = Int(size.height / cellSize) + 1
                for row in 0..<rows {
                    for col in 0..<cols {
                        let isBlack = (row + col) % 2 == 0
                        let rect = CGRect(x: CGFloat(col) * cellSize, y: CGFloat(row) * cellSize, width: cellSize, height: cellSize)
                        context.fill(Path(rect), with: .color(isBlack ? .black : .white))
                    }
                }
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()

            Text("Checkerboard — edges should be sharp with no bleeding")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
