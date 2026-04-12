import SwiftUI

struct EqualizerView: View {
    @StateObject private var engine = AudioEngineManager.shared

    @State private var selectedPreset: EQPreset? = EQPreset.flat

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                enableToggleCard
                presetScrollRow
                bandSlidersCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Equalizer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") { resetToFlat() }
                    .foregroundColor(.secondary)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Enable Toggle

    private var enableToggleCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Equalizer")
                    .font(.headline)
                Text("Adjust frequency bands to tailor your sound")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { engine.equalizerEnabled },
                set: {
                    engine.equalizerEnabled = $0
                    engine.applyEQ()
                    engine.saveSettings()
                }
            ))
            .labelsHidden()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    // MARK: - Preset Row

    private var presetScrollRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Presets")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(EQPreset.builtIn) { preset in
                        presetChip(preset)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
        }
    }

    private func presetChip(_ preset: EQPreset) -> some View {
        let isSelected = selectedPreset?.name == preset.name
        return Button {
            applyPreset(preset)
        } label: {
            Text(preset.name)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }

    // MARK: - Band Sliders

    private var bandSlidersCard: some View {
        VStack(spacing: 0) {
            Text("Custom")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 12)

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))

                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(engine.bandFrequencies.enumerated()), id: \.offset) { index, _ in
                        bandColumn(index: index)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 8)
            }
        }
    }

    private func bandColumn(index: Int) -> some View {
        let gain = Binding<Float>(
            get: { index < engine.gains.count ? engine.gains[index] : 0 },
            set: { newVal in
                if index < engine.gains.count {
                    engine.gains[index] = newVal
                    engine.setGain(newVal, forBand: index)
                    selectedPreset = nil
                }
            }
        )

        let freq = engine.bandFrequencies[index]
        let label = freq >= 1000 ? String(format: "%.0fk", freq / 1000) : String(format: "%.0f", freq)

        return VStack(spacing: 6) {
            Text(gainLabel(gain.wrappedValue))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(gainColor(gain.wrappedValue))
                .frame(height: 16)

            VerticalSlider(value: gain, range: -12...12)
                .frame(height: 160)
                .disabled(!engine.equalizerEnabled)
                .opacity(engine.equalizerEnabled ? 1 : 0.4)

            Text(label)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.secondary)
                .frame(height: 14)

            Text(engine.bandNames[index]
                .components(separatedBy: " ").first ?? "")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(height: 12)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func gainLabel(_ val: Float) -> String {
        val == 0 ? "0" : (val > 0 ? "+\(Int(val))" : "\(Int(val))")
    }

    private func gainColor(_ val: Float) -> Color {
        val > 0 ? .accentColor : val < 0 ? .orange : .secondary
    }

    private func applyPreset(_ preset: EQPreset) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedPreset = preset
            engine.applyPreset(preset)
        }
    }

    private func resetToFlat() {
        applyPreset(.flat)
    }
}

// MARK: - Vertical Slider

private struct VerticalSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Track background
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)
                    .frame(maxWidth: .infinity)

                // Zero line
                Color(.systemGray3)
                    .frame(width: 10, height: 1.5)
                    .frame(maxWidth: .infinity)
                    .offset(y: -(geo.size.height / 2))

                // Filled portion
                let filled = filledHeight(in: geo.size.height)
                Capsule()
                    .fill(fillGradient)
                    .frame(width: 4, height: abs(filled))
                    .frame(maxWidth: .infinity)
                    .offset(y: filled < 0 ? -filled / 2 : 0)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1.5)
                    .frame(width: 22, height: 22)
                    .frame(maxWidth: .infinity)
                    .offset(y: -(thumbOffset(in: geo.size.height)))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let ratio = 1 - drag.location.y / geo.size.height
                        let clamped = max(0, min(1, ratio))
                        value = range.lowerBound + Float(clamped) * (range.upperBound - range.lowerBound)
                    }
            )
        }
    }

    private var fillGradient: LinearGradient {
        LinearGradient(
            colors: value >= 0 ? [.accentColor.opacity(0.7), .accentColor] : [.orange.opacity(0.7), .orange],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private func thumbOffset(in height: CGFloat) -> CGFloat {
        let ratio = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return ratio * height
    }

    private func filledHeight(in height: CGFloat) -> CGFloat {
        let zeroRatio = CGFloat((0 - range.lowerBound) / (range.upperBound - range.lowerBound))
        let valRatio  = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return (valRatio - zeroRatio) * height
    }
}
