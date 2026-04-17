import SwiftUI

struct HealthDataView: View {
    @StateObject private var manager = WorkoutsManager.shared
    @State private var animate = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                healthTile(title: "Steps", value: "\(manager.healthData.steps)", symbol: "figure.walk", color: .green)
                healthTile(title: "Calories Burned", value: "\(Int(manager.healthData.caloriesBurned)) kcal", symbol: "flame.fill", color: .orange)
                healthTile(title: "Workouts", value: "\(manager.healthData.workouts)", symbol: "figure.strengthtraining.traditional", color: .blue)
                healthTile(title: "Average Heart Rate", value: "\(Int(manager.healthData.averageHeartRate ?? 0)) bpm", symbol: "heart.fill", color: .red)
                healthTile(title: "Latest Weight", value: manager.healthData.latestWeightKg.map { String(format: "%.1f kg", $0) } ?? "No data", symbol: "scalemass.fill", color: .purple)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Imported data coverage", systemImage: "chart.line.text.clipboard")
                        .font(.headline)
                    Text("This panel reflects available Apple Health permissions and imported metrics. Tap Sync after granting full read access in Apple Health settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Last Sync: \(manager.healthData.importedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Apple Health")
        .toolbar {
            Button {
                Task { await manager.syncHealthData() }
            } label: {
                Label("Sync", systemImage: "arrow.triangle.2.circlepath")
            }
        }
        .onAppear { animate = true }
    }

    private func healthTile(title: String, value: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 14) {
            if #available(iOS 17, *) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 42, height: 42)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .symbolEffect(.pulse, options: .repeating, value: animate)
            } else {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 42, height: 42)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
