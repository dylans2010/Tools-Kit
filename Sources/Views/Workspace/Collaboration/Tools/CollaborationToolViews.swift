import SwiftUI

struct DecisionEngineView: View {
    @StateObject private var tool = DecisionEngineTool()
    @State private var newOption = ""

    var body: some View {
        VStack {
            List {
                ForEach(tool.options) { option in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(option.title)
                                .font(.headline)
                            Text("Votes: \(option.votes)")
                                .font(.caption)
                        }
                        Spacer()
                        Button("Vote") {
                            tool.vote(optionID: option.id)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            HStack {
                TextField("New Option", text: $newOption)
                Button("Add") {
                    tool.addOption(title: newOption)
                    newOption = ""
                }
            }
            .padding()
        }
        .navigationTitle("Decision Engine")
    }
}

struct ProjectBoardView: View {
    @StateObject private var tool = ProjectExecutionBoardTool()

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 20) {
                BoardColumn(title: "To Do", tasks: tool.tasks.filter { $0.status == .todo })
                BoardColumn(title: "In Progress", tasks: tool.tasks.filter { $0.status == .inProgress })
                BoardColumn(title: "Done", tasks: tool.tasks.filter { $0.status == .done })
            }
            .padding()
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
