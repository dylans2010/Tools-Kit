import SwiftUI

struct TaskAutomationTool: DevTool {
    let id = UUID()
    let name = "Task Automation"
    let category: DevToolCategory = .automation
    let icon = "gearshape.arrow.triangle.2.circlepath"
    let description = "Create and run automated task sequences"
    func render() -> some View { TaskAutomationDevToolView() }
}

struct TaskAutomationDevToolView: View {
    @State private var tasks: [AutoTask] = []
    @State private var newTaskName = ""
    @State private var newTaskType: TaskType = .log
    @State private var isRunning = false
    @State private var runLog: [String] = []

    enum TaskType: String, CaseIterable {
        case log = "Log Message"
        case delay = "Delay (1s)"
        case clearCache = "Clear Cache"
        case generateUUID = "Generate UUID"
        case timestamp = "Log Timestamp"
        case memoryCheck = "Memory Check"
    }

    struct AutoTask: Identifiable {
        let id = UUID()
        let name: String
        let type: TaskType
        var isCompleted = false
    }

    var body: some View {
        Form {
            Section("Add Task") {
                TextField("Task name", text: $newTaskName)
                Picker("Type", selection: $newTaskType) {
                    ForEach(TaskType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Button("Add") {
                    tasks.append(AutoTask(name: newTaskName.isEmpty ? newTaskType.rawValue : newTaskName, type: newTaskType))
                    newTaskName = ""
                }
            }
            Section("Task Queue (\(tasks.count))") {
                ForEach(tasks) { task in
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isCompleted ? .green : .secondary)
                        VStack(alignment: .leading) {
                            Text(task.name).font(.subheadline)
                            Text(task.type.rawValue).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indices in tasks.remove(atOffsets: indices) }
            }
            Section {
                Button(action: runTasks) {
                    HStack {
                        Label("Run All", systemImage: "play.fill")
                        if isRunning { Spacer(); ProgressView().controlSize(.small) }
                    }
                }
                .disabled(tasks.isEmpty || isRunning)
                Button("Reset") {
                    for i in tasks.indices { tasks[i].isCompleted = false }
                    runLog.removeAll()
                }
            }
            if !runLog.isEmpty {
                Section("Run Log") {
                    ForEach(Array(runLog.enumerated()), id: \.offset) { _, entry in
                        Text(entry).font(.system(.caption2, design: .monospaced))
                    }
                }
            }
        }
        .navigationTitle("Task Automation")
    }

    private func runTasks() {
        isRunning = true; runLog.removeAll()
        Task {
            for i in tasks.indices {
                let task = tasks[i]
                let result: String
                switch task.type {
                case .log: result = "Logged: \(task.name)"
                case .delay:
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    result = "Delayed 1 second"
                case .clearCache:
                    URLCache.shared.removeAllCachedResponses()
                    result = "Cache cleared"
                case .generateUUID: result = "UUID: \(UUID().uuidString)"
                case .timestamp: result = "Time: \(Date())"
                case .memoryCheck:
                    let bytes = ProcessInfo.processInfo.physicalMemory
                    result = "Memory: \(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory))"
                }
                await MainActor.run {
                    tasks[i].isCompleted = true
                    runLog.append("[\(i + 1)/\(tasks.count)] \(result)")
                }
            }
            await MainActor.run { isRunning = false }
        }
    }
}
