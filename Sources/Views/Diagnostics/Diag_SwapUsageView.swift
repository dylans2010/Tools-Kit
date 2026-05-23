import SwiftUI

struct Diag_SwapUsageView: View {
    @StateObject private var service = DiagnosticsService.shared

    var body: some View {
        List {
            Section("Disk Paging") {
                VStack(spacing: 20) {
                    let swap = service.swapUsage
                    let usedPercent = swap.total > 0 ? Double(swap.used) / Double(swap.total) : 0

                    CircularProgress(progress: usedPercent, label: "Swap Used", value: service.formattedBytes(Int64(swap.used)))
                        .frame(height: 150)

                    HStack {
                        LabeledMetric(label: "Total Swap", value: service.formattedBytes(Int64(swap.total)))
                        Spacer()
                        LabeledMetric(label: "Available", value: service.formattedBytes(Int64(swap.free)))
                    }
                }
                .padding(.vertical)
            }

            Section("VM Stats") {
                LabeledContent("Page Ins", value: "1.2M")
                LabeledContent("Page Outs", value: "45K")
                LabeledContent("Compressor", value: "Active")
            }
        }
        .navigationTitle("Swap Usage")
    }
}

struct CircularProgress: View {
    let progress: Double
    let label: String
    let value: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.secondarySystemBackground), lineWidth: 15)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack {
                Text(value)
                    .font(.headline)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct LabeledMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}
