import SwiftUI

@MainActor
class PersonaAgent: ObservableObject {
    static let shared = PersonaAgent()

    @Published var isTakingOver: Bool = false
    @Published var plan: [AgentStep] = []
    @Published var logs: [String] = []

    struct AgentStep: Identifiable {
        let id = UUID()
        let action: String
        var status: StepStatus = .pending
    }

    enum StepStatus {
        case pending, executing, completed, failed
    }

    private init() {}

    func requestTakeover() async -> Bool {
        // In a real app, this would show a system-level prompt
        logs.append("Agent requested workspace takeover escalation.")
        return true // Simulated approval for this task
    }

    func executePlan() async {
        guard await requestTakeover() else { return }

        isTakingOver = true
        logs.append("Starting autonomous execution...")

        for i in plan.indices {
            plan[i].status = .executing
            logs.append("Executing: \(plan[i].action)")

            // Simulation of tool invocation and validation
            try? await Task.sleep(nanoseconds: 800_000_000)

            // Validate against AuthorizationManager
            if !AuthorizationManager.shared.validateScope("agent.execute", resourceType: "agent-step", resourceId: plan[i].id.uuidString) {
                plan[i].status = .failed
                logs.append("Permission denied for step: \(plan[i].action)")
                break
            }

            plan[i].status = .completed
        }

        isTakingOver = false
        logs.append("Execution finished.")
    }

    func createSamplePlan() {
        plan = [
            AgentStep(action: "Install package: lodash-lite"),
            AgentStep(action: "Resolve dependencies for UI Framework"),
            AgentStep(action: "Attach Framework: Data Transformation Pipeline"),
            AgentStep(action: "Invoke Library: Cloud Store.upload"),
            AgentStep(action: "Finalize Workspace Sync")
        ]
    }
}

struct PersonaAgentFramework: View {
    @StateObject private var agent = PersonaAgent.shared
    @State private var showingApproval = false

    var body: some View {
        VStack(spacing: 0) {
            // Takeover Overlay
            if agent.isTakingOver {
                ZStack {
                    Color.black.opacity(0.8).ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(2)
                        Text("AGENT TAKEOVER IN PROGRESS")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Autonomous persona is orchestrating workspace dependencies...")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    if agent.plan.isEmpty {
                        emptyPlanView
                    } else {
                        planSection
                    }

                    logSection
                }
                .padding()
            }
        }
        .navigationTitle("Persona Agent")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("New Plan") { agent.createSamplePlan() }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Autonomous Persona Execution Layer").font(.title3.bold())
            Text("Orchestrates Authorization, Dependencies, and Workspace Data").font(.caption).foregroundStyle(.secondary)

            if !agent.plan.isEmpty {
                Button(action: { showingApproval = true }) {
                    Label("Execute Agent Plan", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 10)
                .alert("Approve Agent Takeover?", isPresented: $showingApproval) {
                    Button("Cancel", role: .cancel) {}
                    Button("Approve & Execute") {
                        Task { await agent.executePlan() }
                    }
                } message: {
                    Text("This will grant the agent scoped access to install packages, attach frameworks, and invoke libraries.")
                }
            }
        }
    }

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Multi-step Planning Engine").font(.headline)
            ForEach(agent.plan) { step in
                HStack {
                    stepIcon(step.status)
                    Text(step.action).font(.subheadline)
                    Spacer()
                }
                .padding(8)
                .background(.quaternary.opacity(0.5))
                .cornerRadius(8)
            }
        }
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Safety Layer Logs").font(.headline)
            VStack(alignment: .leading) {
                ForEach(agent.logs.reversed(), id: \.self) { log in
                    Text(log).font(.system(size: 10).monospaced())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.black)
            .foregroundStyle(.green)
            .cornerRadius(8)
        }
    }

    private var emptyPlanView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile").font(.system(size: 60)).foregroundStyle(.secondary)
            Text("No active execution plan").font(.headline).foregroundStyle(.secondary)
            Button("Generate Sample Plan") { agent.createSamplePlan() }.buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private func stepIcon(_ status: PersonaAgent.StepStatus) -> some View {
        switch status {
        case .pending: Image(systemName: "circle").foregroundStyle(.secondary)
        case .executing: ProgressView().controlSize(.small)
        case .completed: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed: Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        }
    }
}
