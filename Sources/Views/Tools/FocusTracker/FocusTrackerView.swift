import SwiftUI

struct FocusTrackerView: View {
    @State private var timeRemaining = 1500
    @State private var isActive = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining) / 1500.0)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text(timeString)
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
            }
            .frame(width: 250, height: 250)
            .padding()

            HStack(spacing: 30) {
                Button(isActive ? "Pause" : "Start") {
                    isActive.toggle()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Reset") {
                    timeRemaining = 1500
                    isActive = false
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .navigationTitle("Focus Session")
        .onReceive(timer) { _ in
            if isActive && timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }

    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
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
