import SwiftUI
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

struct WorkoutsSettingsView: View {
    @StateObject private var manager = WorkoutsManager.shared
    @StateObject private var appSettings = AIChatSettingsManager.shared

    @State private var showingAppSettings = false
    @State private var showingImporter = false
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section("Nutrition Goals") {
                Stepper("Calorie Goal: \(manager.preferences.calorieGoal)", value: binding(\.calorieGoal), in: 1200...5000, step: 50)
                Stepper("Protein Goal: \(Int(manager.preferences.proteinGoal))g", value: binding(\.proteinGoal), in: 40...300, step: 5)
                Stepper("Carbs Goal: \(Int(manager.preferences.carbsGoal))g", value: binding(\.carbsGoal), in: 50...500, step: 5)
                Stepper("Fats Goal: \(Int(manager.preferences.fatsGoal))g", value: binding(\.fatsGoal), in: 20...180, step: 2)
            }

            Section("Workout Preferences") {
                Stepper("Preferred Duration: \(manager.preferences.preferredDurationMinutes) min", value: binding(\.preferredDurationMinutes), in: 20...120, step: 5)
            }

            Section("Integrations") {
                Toggle("Sync with Apple Health", isOn: binding(\.syncAppleHealth))
                Button("Sync Apple Health Now") {
                    Task { await manager.syncHealthData() }
                }
            }

            Section("Data") {
                Button("Export JSON") { exportJSON() }
                Button("Export CSV") { exportCSV() }
                Button("Import JSON") { showingImporter = true }
                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button("Open App Settings") {
                    showingAppSettings = true
                }
            }
        }
        .navigationTitle("Workout Settings")
        .sheet(isPresented: $showingAppSettings) {
            AIChatSettingsView(settings: $appSettings.settings)
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                do {
                    try manager.importData(from: url)
                    statusMessage = "Imported data successfully."
                } catch {
                    statusMessage = "Import failed: \(error.localizedDescription)"
                }
            case .failure(let error):
                statusMessage = "Import canceled: \(error.localizedDescription)"
            }
        }
    }

    private func binding<T>(_ keyPath: WritableKeyPath<WorkoutsPreferences, T>) -> Binding<T> {
        Binding(
            get: { manager.preferences[keyPath: keyPath] },
            set: { newValue in
                var updated = manager.preferences
                updated[keyPath: keyPath] = newValue
                manager.preferences = updated
                manager.persistPreferences()
                manager.generateTodayWorkoutIfNeeded(force: true)
            }
        )
    }

    private func exportJSON() {
        let url = exportURL(ext: "json")
        do {
            try manager.exportJSON(to: url)
            statusMessage = "Exported JSON to \(url.lastPathComponent)."
        } catch {
            statusMessage = "JSON export failed: \(error.localizedDescription)"
        }
    }

    private func exportCSV() {
        let url = exportURL(ext: "csv")
        do {
            try manager.exportCSV(to: url)
            statusMessage = "Exported CSV to \(url.lastPathComponent)."
        } catch {
            statusMessage = "CSV export failed: \(error.localizedDescription)"
        }
    }

    private func exportURL(ext: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("workouts-export-\(Int(Date().timeIntervalSince1970)).\(ext)")
    }
}
