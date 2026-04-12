import SwiftUI

/// Interactive slider question component for filling out a form.
struct SliderQuestionView: View {
    let question: FormQuestion
    @Binding var answer: String

    private var config: (min: Double, max: Double, step: Double) {
        let opts = question.options
        let min = Double(opts.first ?? "") ?? 0
        let maxRaw = Double(opts.count > 1 ? opts[1] : "") ?? 100
        let max = Swift.max(min + 1, maxRaw)
        let step = Swift.max(0.01, Double(opts.count > 2 ? opts[2] : "") ?? 1)
        return (min, max, step)
    }

    private var sliderValue: Binding<Double> {
        Binding(
            get: {
                let cfg = config
                return Double(answer) ?? cfg.min
            },
            set: { newVal in
                answer = formatValue(newVal)
            }
        )
    }

    var body: some View {
        let cfg = config
        VStack(alignment: .leading, spacing: 8) {
            Slider(value: sliderValue, in: cfg.min...cfg.max, step: cfg.step)
                .tint(.blue)

            HStack {
                Text(formatValue(cfg.min))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(answer.isEmpty ? formatValue(cfg.min) : answer)
                    .font(.headline.monospacedDigit())
                    .foregroundColor(.blue)
                Spacer()
                Text(formatValue(cfg.max))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private func formatValue(_ val: Double) -> String {
        if val == val.rounded() {
            return String(Int(val))
        }
        return String(format: "%.2f", val)
    }
}
