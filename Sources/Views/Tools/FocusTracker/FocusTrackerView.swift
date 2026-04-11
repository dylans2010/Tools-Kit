import SwiftUI

struct FocusTrackerView: View {
    @StateObject private var backend = FocusSessionBackend()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximize your productivity using the Pomodoro technique. Focus on your work during high-intensity intervals and rest during short breaks.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Picker("Protocol", selection: $backend.selectedPreset) {
                    ForEach(FocusPreset.presets) { preset in
                        Text(preset.name).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ZStack {
                    Circle()
                        .stroke(Color(.systemGray6), lineWidth: 16)

                    Circle()
                        .trim(from: 0, to: backend.progress)
                        .stroke(
                            backend.phase == .work ? Color.orange.gradient : Color.green.gradient,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: backend.progress)

                    VStack(spacing: 12) {
                        Text(backend.phase.rawValue.uppercased())
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(backend.phase == .work ? .orange : .green)
                            .tracking(2)

                        Text(timeString)
                            .font(.system(size: 64, weight: .medium, design: .rounded))
                    }
                }
                .frame(width: 280, height: 280)

                HStack(spacing: 24) {
                    Button(action: backend.reset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }

                    Button(action: backend.toggle) {
                        Image(systemName: backend.isActive ? "pause.fill" : "play.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .padding(24)
                            .background(backend.phase == .work ? Color.orange : Color.green)
                            .clipShape(Circle())
                            .shadow(color: (backend.phase == .work ? Color.orange : Color.green).opacity(0.3), radius: 10, x: 0, y: 5)
                    }

                    // Placeholder for a future skip or more options button
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                    .opacity(0) // Hide for now but keep spacing
                }

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Daily Goal", systemImage: "target")
                                .font(.headline)
                            Spacer()
                            Text("\(backend.dailyGoal) sessions")
                                .bold()
                        }

                        Stepper(value: $backend.dailyGoal, in: 1...16) {
                            ProgressView(value: 2.0, total: Double(backend.dailyGoal)) // Mocked progress
                                .tint(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)

                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text(backend.streakStatus)
                            .font(.subheadline.bold())
                        Spacer()
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
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
