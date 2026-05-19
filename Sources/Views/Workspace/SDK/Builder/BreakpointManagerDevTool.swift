import SwiftUI

struct BreakpointManagerDevTool: DevTool {
    let id = "breakpoint-manager"
    let name = "Breakpoint Manager"
    let category = DevToolCategory.debugging
    let icon = "pause.fill"
    let description = "Manage and toggle application breakpoints"

    func render() -> some View {
        BreakpointManagerView()
    }
}

struct BreakpointManagerView: View {
    @StateObject private var viewModel = BreakpointManagerViewModel()
    @State private var showingAddSheet = false

    var body: some View {
        List {
            Section("Debugger Status") {
                HStack(spacing: 20) {
                    BPMetric(label: "Enabled", count: viewModel.breakpoints.filter(\.isActive).count, color: .blue)
                    BPMetric(label: "Hit Count", count: 142, color: .orange)
                    BPMetric(label: "Sessions", count: 12, color: .green)
                }
                .padding(.vertical, 8)
            }

            Section("Active Breakpoints (\(viewModel.breakpoints.count))") {
                if viewModel.breakpoints.isEmpty {
                    ContentUnavailableView("No Breakpoints", systemImage: "pause.circle", description: Text("Define halt points to inspect execution state."))
                } else {
                    ForEach($viewModel.breakpoints) { $bp in
                        BreakpointRow(bp: $bp)
                    }
                    .onDelete { viewModel.breakpoints.remove(atOffsets: $0) }
                }
            }

            Section {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Symbol Breakpoint", systemImage: "plus.circle.fill")
                }

                Button(role: .destructive) {
                    viewModel.breakpoints.removeAll()
                } label: {
                    Label("Remove All", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Breakpoints")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: .constant(true)) {
                    Image(systemName: "bolt.fill")
                }
                .toggleStyle(.button)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBreakpointView(viewModel: viewModel)
        }
    }
}

struct BPMetric: View {
    let label: String
    let count: Int
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)").font(.title3.bold().monospacedDigit()).foregroundStyle(color)
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct BreakpointRow: View {
    @Binding var bp: Breakpoint

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(bp.isActive ? Color.blue : Color.secondary.opacity(0.3))
                .frame(width: 10, height: 10)
                .shadow(color: bp.isActive ? .blue.opacity(0.4) : .clear, radius: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(bp.location)
                    .font(.subheadline.bold())
                HStack {
                    Text("Condition:").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                    Text(bp.condition)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.blue)
                }
            }

            Spacer()

            Toggle("", isOn: $bp.isActive)
                .labelsHidden()
                .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

struct AddBreakpointView: View {
    @ObservedObject var viewModel: BreakpointManagerViewModel
    @State private var location = ""
    @State private var condition = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Location (file:line)", text: $location)
                TextField("Condition (optional)", text: $condition)
            }
            .navigationTitle("New Breakpoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.breakpoints.append(Breakpoint(location: location, condition: condition.isEmpty ? "None" : condition, isActive: true))
                        dismiss()
                    }
                    .disabled(location.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct Breakpoint: Identifiable {
    let id = UUID()
    var location: String
    var condition: String
    var isActive: Bool
}

class BreakpointManagerViewModel: ObservableObject {
    @Published var breakpoints: [Breakpoint] = [
        Breakpoint(location: "ToolsKitSDK.swift:150", condition: "scope == .notes", isActive: true),
        Breakpoint(location: "SDKDataEngine.swift:42", condition: "None", isActive: false)
    ]
}

#Preview {
    BreakpointManagerView()
}
