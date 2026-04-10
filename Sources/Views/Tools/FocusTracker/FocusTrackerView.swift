import SwiftUI

struct FocusTrackerView: View {
    @StateObject private var backend = FocusSessionBackend()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Session", selection: $backend.selectedPreset) {
                    ForEach(FocusPreset.presets) { preset in
                        Text(preset.name).tag(preset)
                    }
                }
                .pickerStyle(.segmented)

                ZStack {
                    Circle().stroke(Color.gray.opacity(0.2), lineWidth: 18)
                    Circle()
                        .trim(from: 0, to: backend.progress)
                        .stroke(backend.phase == .work ? Color.red : Color.green, style: .init(lineWidth: 18, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 8) {
                        Text(backend.phase.rawValue).font(.headline)
                        Text(timeString)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                    }
                }
                .frame(width: 260, height: 260)
                .padding(.top, 12)

                HStack(spacing: 16) {
                    Button(backend.isActive ? "Pause" : "Start", action: backend.toggle)
                        .buttonStyle(.borderedProminent)
                    Button("Reset", action: backend.reset)
                        .buttonStyle(.bordered)
                }

                Stepper("Daily Goal: \(backend.dailyGoal)", value: $backend.dailyGoal, in: 1...16)

                VStack(alignment: .leading, spacing: 6) {
                    Label(backend.streakStatus, systemImage: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Auto switches between work and breaks based on the selected focus protocol.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Focus Session")
        .onReceive(timer) { _ in backend.tick() }
    }

    private var timeString: String {
        let minutes = backend.timeRemaining / 60
        let seconds = backend.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct FocusTrackerTool: Tool {
    let name = "Focus Session"
    let icon = "timer"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Advanced Pomodoro timer for deep work sessions"
    let requiresAPI = false
    var view: AnyView { AnyView(FocusTrackerView()) }
}
