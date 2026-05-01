import SwiftUI

struct DecisionEngineView: View {
    let spaceID: UUID
    @ObservedObject private var tool = DecisionEngineTool.shared
    @State private var newDecisionTitle = ""

    private var filteredDecisions: [DecisionEngineTool.Decision] {
        guard let space = CollaborationManager.shared.spaces.first(where: { $0.id == spaceID }) else { return [] }
        return tool.decisions.filter { space.decisionIDs.contains($0.id) }
    }

    var body: some View {
        List {
            Section("Decisions") {
                if filteredDecisions.isEmpty {
                    Text("No decisions in this space.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredDecisions) { decision in
                        NavigationLink(destination: DecisionDetailView(decision: decision)) {
                            Text(decision.title)
                        }
                    }
                }
            }

            Section("New Decision") {
                HStack {
                    TextField("Title", text: $newDecisionTitle)
                    Button("Create") {
                        let _ = tool.createDecision(spaceID: spaceID, title: newDecisionTitle)
                        newDecisionTitle = ""
                    }
                    .disabled(newDecisionTitle.isEmpty)
                }
            }
        }
        .navigationTitle("Decision Engine")
    }
}

struct DecisionDetailView: View {
    let decision: DecisionEngineTool.Decision
    @ObservedObject private var tool = DecisionEngineTool.shared
    @State private var newOption = ""

    var body: some View {
        VStack {
            List {
                ForEach(decision.options) { option in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(option.title)
                                .font(.headline)
                            Text("Votes: \(option.votes)")
                                .font(.caption)
                        }
                        Spacer()
                        Button("Vote") {
                            tool.vote(decisionID: decision.id, optionID: option.id)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            HStack {
                TextField("New Option", text: $newOption)
                Button("Add") {
                    tool.addOption(to: decision.id, title: newOption)
                    newOption = ""
                }
            }
            .padding()
        }
        .navigationTitle(decision.title)
    }
}

struct ProjectBoardView: View {
    let spaceID: UUID
    @ObservedObject private var tool = ProjectExecutionBoardTool.shared
    @State private var newTaskTitle = ""

    private var filteredTasks: [ProjectExecutionBoardTool.BoardTask] {
        guard let space = CollaborationManager.shared.spaces.first(where: { $0.id == spaceID }) else { return [] }
        return tool.tasks.filter { space.taskIDs.contains($0.id) }
    }

    var body: some View {
        VStack {
            HStack {
                TextField("New Task", text: $newTaskTitle)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    tool.addTask(spaceID: spaceID, title: newTaskTitle)
                    newTaskTitle = ""
                }
                .disabled(newTaskTitle.isEmpty)
            }
            .padding()

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 20) {
                    BoardColumn(title: "To Do", tasks: filteredTasks.filter { $0.status == .todo })
                    BoardColumn(title: "In Progress", tasks: filteredTasks.filter { $0.status == .inProgress })
                    BoardColumn(title: "Done", tasks: filteredTasks.filter { $0.status == .done })
                }
                .padding()
            }
        }
        .navigationTitle("Project Board")
    }
}

struct BoardColumn: View {
    let title: String
    let tasks: [ProjectExecutionBoardTool.BoardTask]

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 8)

            ForEach(tasks) { task in
                VStack(alignment: .leading) {
                    Text(task.title)
                        .bold()
                    if !task.dependencyIDs.isEmpty {
                        Text("Has dependencies")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .frame(width: 200, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}
