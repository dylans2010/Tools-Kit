import SwiftUI

struct Diag_DiskUsageView: View {
    @StateObject private var service = DiagnosticsService.shared

    var body: some View {
        Form {
            Section("Storage Overview") {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 20)
                        Circle()
                            .trim(from: 0, to: usageRatio)
                            .stroke(usageColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        VStack {
                            Text("\(Int(usageRatio * 100))%")
                                .font(.title.monospacedDigit().bold())
                            Text("Used")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 150, height: 150)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Space Details") {
                LabeledContent("Total") {
                    Text(service.formattedBytes(service.totalDiskSpace))
                        .monospacedDigit()
                }
                LabeledContent("Used") {
                    Text(service.formattedBytes(service.usedDiskSpace))
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                }
                LabeledContent("Free") {
                    Text(service.formattedBytes(service.freeDiskSpace))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }
            }

            Section("Visual Breakdown") {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange)
                            .frame(width: geo.size.width * usageRatio)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.5))
                    }
                }
                .frame(height: 30)

                HStack {
                    Circle().fill(.orange).frame(width: 10, height: 10)
                    Text("Used")
                        .font(.caption)
                    Spacer()
                    Circle().fill(.green.opacity(0.5)).frame(width: 10, height: 10)
                    Text("Free")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Disk Usage")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var usageRatio: CGFloat {
        guard service.totalDiskSpace > 0 else { return 0 }
        return CGFloat(service.usedDiskSpace) / CGFloat(service.totalDiskSpace)
    }

    private var usageColor: Color {
        if usageRatio > 0.9 { return .red }
        if usageRatio > 0.75 { return .orange }
        return .blue
    }
}
