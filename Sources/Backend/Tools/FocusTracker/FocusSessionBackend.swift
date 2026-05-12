import Foundation

struct FocusPreset: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let workSeconds: Int
    let shortBreakSeconds: Int
    let longBreakSeconds: Int
    let cyclesBeforeLongBreak: Int

    static let presets: [FocusPreset] = [
        FocusPreset(name: "Pomodoro", workSeconds: 25 * 60, shortBreakSeconds: 5 * 60, longBreakSeconds: 15 * 60, cyclesBeforeLongBreak: 4),
        FocusPreset(name: "Deep Work", workSeconds: 50 * 60, shortBreakSeconds: 10 * 60, longBreakSeconds: 20 * 60, cyclesBeforeLongBreak: 3),
        FocusPreset(name: "Sprint", workSeconds: 90 * 60, shortBreakSeconds: 15 * 60, longBreakSeconds: 25 * 60, cyclesBeforeLongBreak: 2)
    ]
}

enum FocusPhase: String, Sendable {
    case work = "Work"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
}

final class FocusSessionBackend: ObservableObject {
    @Published var selectedPreset: FocusPreset = FocusPreset.presets[0] {
        didSet { reset() }
    }
    @Published var phase: FocusPhase = .work
    @Published var isActive = false
    @Published var timeRemaining = 25 * 60
    @Published var completedWorkSessions = 0
    @Published var dailyGoal = 6

    init() {
        timeRemaining = selectedPreset.workSeconds
    }

    var progress: Double {
        let duration = phaseDuration
        guard duration > 0 else { return 0 }
        return 1 - Double(timeRemaining) / Double(duration)
    }

    var phaseDuration: Int {
        switch phase {
        case .work: return selectedPreset.workSeconds
        case .shortBreak: return selectedPreset.shortBreakSeconds
        case .longBreak: return selectedPreset.longBreakSeconds
        }
    }

    var streakStatus: String {
        "\(completedWorkSessions)/\(dailyGoal) sessions today"
    }

    func toggle() { isActive.toggle() }

    func reset() {
        isActive = false
        phase = .work
        timeRemaining = selectedPreset.workSeconds
        completedWorkSessions = 0
    }

    func tick() {
        guard isActive else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
            return
        }
        transitionToNextPhase()
    }

    private func transitionToNextPhase() {
        switch phase {
        case .work:
            completedWorkSessions += 1
            phase = completedWorkSessions % selectedPreset.cyclesBeforeLongBreak == 0 ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            phase = .work
        }
        timeRemaining = phaseDuration
    }
}
