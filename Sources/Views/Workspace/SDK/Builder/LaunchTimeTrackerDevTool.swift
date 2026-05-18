import SwiftUI

struct LaunchTimeTrackerDevTool: DevTool {
    let id = "launch-time-tracker"
    let name = "Launch Time Tracker"
    let category = DevToolCategory.performance
    let icon = "timer"
    let description = "Track application launch performance"

    func render() -> some View {
        LaunchTimeTrackerView()
    }
}

struct LaunchTimeTrackerView: View {
    var body: some View {
        List {
            Section("System Benchmarks") {
                LabeledContent("Kernel Init", value: "85ms")
                LabeledContent("Shared Cache", value: "112ms")
                LabeledContent("dyld Link", value: "145ms")
            }

            Section("App Benchmarks") {
                LabeledContent("main() to First Frame", value: "240ms")
            }
        }
    }
}
