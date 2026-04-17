import SwiftUI

struct LiveWorkoutView: View {
    @StateObject private var manager = WorkoutsManager.shared
    @StateObject private var timerService = WorkoutTimerService()

    var body: some View {
        List {
            Section("Live Session") {
                LabeledContent("Elapsed", value: formatTime(timerService.elapsedSeconds))
                LabeledContent("Rest", value: formatTime(timerService.restSecondsRemaining))
                LabeledContent("Heart Rate", value: "\(Int(manager.liveHeartRate)) bpm")
            }

            Section {
                HStack {
                    Button(timerService.isRunning ? "Stop" : "Start") {
                        if timerService.isRunning {
                            timerService.stopWorkout()
                        } else {
                            timerService.startWorkout()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Rest 60s") {
                        timerService.startRest(seconds: 60)
                    }
                    .buttonStyle(.bordered)

                    Button("Reset") {
                        timerService.resetWorkout()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Live Workout")
        .task {
            await manager.refreshLiveHeartRate()
        }
    }

    private func formatTime(_ total: Int) -> String {
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
