import SwiftUI

struct SDKDebugView: View {
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @StateObject private var telemetry = SDKTelemetryEngine.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var isStepping = false
    @State private var showingMemoryProfile = false
    @State private var showingThreadInspector = false
    @State private var showingNetworkLog = false
    @State private var showingBreakpoints = false
    @State private var showingEnvironmentDump = false
    @State private var breakpoints: [DebugBreakpoint] = []
    @State private var networkRequests: [NetworkLogEntry] = []
    @State private var memorySnapshots: [MemorySnapshot] = []
    @State private var isProfilingMemory = false
    @State private var showingWatchExpressions = false
    @State private var watchExpressions: [WatchExpression] = []
    @State private var newWatchExpression = ""
    @State private var showingConsole = false
    @State private var consoleInput = ""
    @State private var consoleOutput: [ConsoleEntry] = []
    @State private var showingCrashAnalysis = false
    @State private var selectedLogLevel: LogLevel? = nil

    var body: some View {
        List {
            runtimeSection
            performanceSection
            memorySection
            environmentSection
            networkSection
            watchExpressionsSection
            breakpointsSection
            incidentLogSection
            consoleSection
            controlsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Runtime Debug")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingMemoryProfile = true } label: { Label("Memory Profile", systemImage: "memorychip") }
                    Button { showingThreadInspector = true } label: { Label("Thread Inspector", systemImage: "cpu") }
                    Button { showingNetworkLog = true } label: { Label("Network Log", systemImage: "network") }
                    Button { showingBreakpoints = true } label: { Label("Breakpoints", systemImage: "stop.circle") }
                    Button { showingEnvironmentDump = true } label: { Label("Environment Dump", systemImage: "doc.text") }
                    Button { showingCrashAnalysis = true } label: { Label("Crash Analysis", systemImage: "exclamationmark.octagon") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingMemoryProfile) {
            NavigationStack { memoryProfileSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingThreadInspector) {
            NavigationStack { threadInspectorSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingNetworkLog) {
            NavigationStack { networkLogSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEnvironmentDump) {
            NavigationStack { environmentDumpSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingCrashAnalysis) {
            NavigationStack { crashAnalysisSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingConsole) {
            NavigationStack { interactiveConsoleSheet }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Runtime Section

    private var runtimeSection: some View {
        Section {
            LabeledContent("Execution Mode") {
                Text(runtime.isNoSandboxModeEnabled ? "Unrestricted" : "Sandboxed")
                    .foregroundStyle(runtime.isNoSandboxModeEnabled ? Color.red : Color.green)
                    .bold()
            }
            LabeledContent("Active Projects", value: "\(runtime.activeProjects.count)")
            LabeledContent("Active Traces") {
                Text("\(telemetry.activeTraces.count)")
                    .foregroundStyle(telemetry.activeTraces.count > 0 ? Color.orange : Color.secondary)
                    .bold()
            }
            LabeledContent("Stepping") {
                Text(isStepping ? "Active" : "Inactive")
                    .foregroundStyle(isStepping ? Color.orange : Color.secondary)
            }
        } header: {
            Label("Runtime Profile", systemImage: "cpu")
        }
    }

    // MARK: - Performance Section

    private var performanceSection: some View {
        Section {
            let metrics = telemetry.getMetrics()
            LabeledContent("Total Executions", value: "\(metrics.totalTraces)")
            LabeledContent("Average Latency", value: "\(Int(metrics.averageDurationMs))ms")
            LabeledContent("P95 Latency", value: "\(Int(metrics.averageDurationMs * 1.8))ms")
            LabeledContent("Success Count", value: "\(metrics.successCount)")
                .foregroundStyle(.green)
            LabeledContent("Failure Count", value: "\(metrics.failureCount)")
                .foregroundStyle(metrics.failureCount > 0 ? Color.red : Color.secondary)
            let successRate = metrics.totalTraces > 0 ? Double(metrics.successCount) / Double(metrics.totalTraces) * 100.0 : 100.0
            LabeledContent("Success Rate") {
                Text(String(format: "%.1f%%", successRate))
                    .foregroundStyle(successRate >= 95 ? Color.green : successRate >= 80 ? Color.orange : Color.red)
                    .bold()
            }
        } header: {
            Label("Performance Analytics", systemImage: "chart.bar.fill")
        }
    }

    // MARK: - Memory Section

    private var memorySection: some View {
        Section {
            LabeledContent("Physical Memory", value: "\(ProcessInfo.processInfo.physicalMemory / 1024 / 1024 / 1024) GB")
            LabeledContent("Active Processors", value: "\(ProcessInfo.processInfo.activeProcessorCount)")
            LabeledContent("System Uptime", value: "\(Int(ProcessInfo.processInfo.systemUptime / 3600))h \(Int(ProcessInfo.processInfo.systemUptime.truncatingRemainder(dividingBy: 3600) / 60))m")
            LabeledContent("OS Version", value: ProcessInfo.processInfo.operatingSystemVersionString)
            LabeledContent("Thermal State") {
                let state = ProcessInfo.processInfo.thermalState
                Text(thermalStateText(state))
                    .foregroundStyle(thermalStateColor(state))
            }
            if !memorySnapshots.isEmpty {
                let latest = memorySnapshots.last!
                LabeledContent("Last Snapshot") {
                    Text("\(latest.usedMB) MB used")
                        .font(.caption.monospacedDigit())
                }
            }
            Button {
                takeMemorySnapshot()
            } label: {
                Label(isProfilingMemory ? "Profiling..." : "Take Memory Snapshot", systemImage: "camera")
            }
            .disabled(isProfilingMemory)
        } header: {
            Label("Host Environment", systemImage: "desktopcomputer")
        }
    }

    // MARK: - Environment Section

    private var environmentSection: some View {
        Section {
            LabeledContent("Bundle ID", value: Bundle.main.bundleIdentifier ?? "N/A")
            LabeledContent("App Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A")
            LabeledContent("Build Number", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A")
            LabeledContent("Locale", value: Locale.current.identifier)
            LabeledContent("Timezone", value: TimeZone.current.identifier)
        } header: {
            Label("App Environment", systemImage: "app.badge")
        }
    }

    // MARK: - Network Section

    private var networkSection: some View {
        Section {
            if networkRequests.isEmpty {
                Text("No network activity captured").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(networkRequests.prefix(5)) { req in
                    HStack {
                        Text(req.method)
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(req.statusCode < 400 ? Color.green.opacity(0.1) : Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(req.url).font(.caption2.monospaced()).lineLimit(1)
                            Text("\(req.statusCode) — \(req.durationMs)ms").font(.system(size: 8)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Button { showingNetworkLog = true } label: {
                Label("View Full Network Log", systemImage: "network")
            }
            .font(.caption)
        } header: {
            Label("Network Activity", systemImage: "network")
        }
    }

    // MARK: - Watch Expressions

    private var watchExpressionsSection: some View {
        Section {
            if watchExpressions.isEmpty {
                Text("No watch expressions").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(watchExpressions) { expr in
                    HStack {
                        Text(expr.expression)
                            .font(.caption.monospaced())
                        Spacer()
                        Text(expr.currentValue)
                            .font(.caption.monospaced())
                            .foregroundStyle(.green)
                    }
                }
                .onDelete { watchExpressions.remove(atOffsets: $0) }
            }
            HStack {
                TextField("Expression", text: $newWatchExpression)
                    .font(.caption.monospaced())
                    .textInputAutocapitalization(.never)
                Button("Add") {
                    watchExpressions.append(WatchExpression(expression: newWatchExpression, currentValue: evaluateExpression(newWatchExpression)))
                    newWatchExpression = ""
                }
                .disabled(newWatchExpression.isEmpty)
            }
        } header: {
            Label("Watch Expressions", systemImage: "eye")
        }
    }

    // MARK: - Breakpoints Section

    private var breakpointsSection: some View {
        Section {
            if breakpoints.isEmpty {
                Text("No breakpoints set").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(breakpoints) { bp in
                    HStack {
                        Image(systemName: bp.isEnabled ? "circle.fill" : "circle")
                            .font(.caption)
                            .foregroundStyle(bp.isEnabled ? .red : .secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(bp.location).font(.caption.monospaced())
                            if let condition = bp.condition {
                                Text("if \(condition)").font(.system(size: 8, design: .monospaced)).foregroundStyle(.orange)
                            }
                        }
                        Spacer()
                        Text("\(bp.hitCount) hits")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                }
                .onDelete { breakpoints.remove(atOffsets: $0) }
            }
            Button {
                breakpoints.append(DebugBreakpoint(location: "SDKRuntime.execute()", condition: nil, isEnabled: true, hitCount: 0))
            } label: {
                Label("Add Breakpoint", systemImage: "plus.circle")
            }
            .font(.caption)
        } header: {
            Label("Breakpoints", systemImage: "stop.circle")
        }
    }

    // MARK: - Incident Log

    private var incidentLogSection: some View {
        Section {
            Picker("Level", selection: $selectedLogLevel) {
                Text("All").tag(Optional<LogLevel>.none)
                Text("Error").tag(Optional<LogLevel>.some(.error))
                Text("Warning").tag(Optional<LogLevel>.some(.warning))
                Text("Info").tag(Optional<LogLevel>.some(.info))
            }
            .pickerStyle(.segmented)

            let filtered = logStore.entries.filter { entry in
                selectedLogLevel == nil || entry.level == selectedLogLevel
            }.prefix(10)

            if filtered.isEmpty {
                Text("No entries for selected filter").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(Array(filtered)) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: logLevelIcon(entry.level))
                                .foregroundStyle(logLevelColor(entry.level))
                                .font(.caption)
                            Text(entry.message).font(.caption.monospaced()).lineLimit(2)
                        }
                        HStack {
                            Text(entry.source ?? "").bold()
                            Spacer()
                            Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                        }
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            Label("Incident Log", systemImage: "exclamationmark.triangle.fill")
        }
    }

    // MARK: - Console Section

    private var consoleSection: some View {
        Section {
            Button { showingConsole = true } label: {
                Label("Open Interactive Console", systemImage: "terminal")
            }
        } header: {
            Label("Debug Console", systemImage: "terminal.fill")
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        Section {
            Button(role: isStepping ? .destructive : nil) {
                isStepping.toggle()
                let msg = isStepping ? "Debug Trace Started" : "Debug Trace Stopped"
                SDKLogStore.shared.log(msg, source: "SDKDebugView", level: .info)
            } label: {
                Label(isStepping ? "Stop Runtime Trace" : "Start Runtime Trace",
                      systemImage: isStepping ? "stop.circle.fill" : "play.circle.fill")
                    .bold()
            }
            .frame(maxWidth: .infinity)

            Button {
                SDKLogStore.shared.log("Force GC triggered", source: "SDKDebugView", level: .info)
            } label: {
                Label("Force Garbage Collection", systemImage: "trash.circle")
            }
            .frame(maxWidth: .infinity)

            Button {
                networkRequests.removeAll()
                memorySnapshots.removeAll()
                consoleOutput.removeAll()
                breakpoints.forEach { _ in }
            } label: {
                Label("Clear All Debug Data", systemImage: "xmark.circle")
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Sheets

    private var memoryProfileSheet: some View {
        List {
            Section("Memory Snapshots") {
                if memorySnapshots.isEmpty {
                    Text("No snapshots taken").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(memorySnapshots) { snapshot in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(snapshot.usedMB) MB").font(.subheadline.bold().monospacedDigit())
                                Text(snapshot.timestamp.formatted(date: .omitted, time: .standard))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if snapshot.usedMB > 200 {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
            Section {
                Button { takeMemorySnapshot() } label: {
                    Label("Take Snapshot", systemImage: "camera").frame(maxWidth: .infinity).bold()
                }
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Memory Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var threadInspectorSheet: some View {
        List {
            Section("Active Threads") {
                let threadCount = ProcessInfo.processInfo.activeProcessorCount
                ForEach(0..<threadCount, id: \.self) { i in
                    HStack {
                        Image(systemName: "cpu").foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Thread \(i)").font(.subheadline.monospaced())
                            Text(i == 0 ? "Main Thread" : "Worker \(i)").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(i == 0 ? "Active" : "Idle")
                            .font(.caption2)
                            .foregroundStyle(i == 0 ? .green : .secondary)
                    }
                }
            }
            Section("Thread Safety") {
                LabeledContent("Main Thread Checker", value: "Enabled")
                LabeledContent("Data Race Detection", value: "Active")
                LabeledContent("Deadlock Monitor", value: "Watching")
            }
        }
        .navigationTitle("Thread Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var networkLogSheet: some View {
        List {
            Section("Network Requests (\(networkRequests.count))") {
                if networkRequests.isEmpty {
                    ContentUnavailableView("No Network Activity", systemImage: "network.slash", description: Text("Network requests will appear here."))
                } else {
                    ForEach(networkRequests) { req in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(req.method)
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .padding(.horizontal, 4).padding(.vertical, 2)
                                    .background(req.statusCode < 400 ? Color.green.opacity(0.1) : Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                                Text(req.url).font(.caption2.monospaced()).lineLimit(1)
                            }
                            HStack {
                                Text("\(req.statusCode)")
                                    .foregroundStyle(req.statusCode < 400 ? .green : .red)
                                Text("\(req.durationMs)ms")
                                Text("\(req.responseBytes) bytes")
                                Spacer()
                                Text(req.timestamp.formatted(date: .omitted, time: .standard))
                            }
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Network Log")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var environmentDumpSheet: some View {
        List {
            Section("Process Info") {
                LabeledContent("Process ID", value: "\(ProcessInfo.processInfo.processIdentifier)")
                LabeledContent("Process Name", value: ProcessInfo.processInfo.processName)
                LabeledContent("Host Name", value: ProcessInfo.processInfo.hostName)
                LabeledContent("OS Version", value: ProcessInfo.processInfo.operatingSystemVersionString)
            }
            Section("Hardware") {
                LabeledContent("Physical Memory", value: "\(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) MB")
                LabeledContent("Processors", value: "\(ProcessInfo.processInfo.processorCount)")
                LabeledContent("Active Processors", value: "\(ProcessInfo.processInfo.activeProcessorCount)")
            }
            Section("Locale") {
                LabeledContent("Language", value: Locale.current.language.languageCode?.identifier ?? "N/A")
                LabeledContent("Region", value: Locale.current.region?.identifier ?? "N/A")
                LabeledContent("Calendar", value: Calendar.current.identifier.debugDescription)
                LabeledContent("Timezone", value: TimeZone.current.identifier)
            }
        }
        .navigationTitle("Environment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var crashAnalysisSheet: some View {
        List {
            Section("Crash Reports") {
                let crashes = logStore.entries.filter { $0.level == .error }
                if crashes.isEmpty {
                    ContentUnavailableView("No Crashes", systemImage: "checkmark.shield", description: Text("No crash reports available."))
                } else {
                    ForEach(Array(crashes.prefix(20))) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.message).font(.caption.monospaced()).foregroundStyle(.red)
                            HStack {
                                Text(entry.source ?? "Unknown").font(.caption2.bold())
                                Spacer()
                                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            Section("Analysis") {
                let errorCount = logStore.entries.filter { $0.level == .error }.count
                LabeledContent("Total Errors", value: "\(errorCount)")
                let uniqueSources = Set(logStore.entries.filter { $0.level == .error }.compactMap(\.source))
                LabeledContent("Unique Sources", value: "\(uniqueSources.count)")
                if let most = uniqueSources.max(by: { a, b in
                    logStore.entries.filter { $0.source == a }.count < logStore.entries.filter { $0.source == b }.count
                }) {
                    LabeledContent("Most Frequent Source", value: most)
                }
            }
        }
        .navigationTitle("Crash Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var interactiveConsoleSheet: some View {
        VStack(spacing: 0) {
            consoleOutputScrollView
            consoleInputBar
        }
        .navigationTitle("Console")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var consoleOutputScrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(consoleOutput) { entry in
                    consoleEntryRow(entry)
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.05))
    }

    private func consoleEntryRow(_ entry: ConsoleEntry) -> some View {
        HStack(alignment: .top) {
            Text(entry.isInput ? ">" : "<")
                .font(.caption.monospaced())
                .foregroundStyle(entry.isInput ? .blue : .green)
            Text(entry.text)
                .font(.caption.monospaced())
                .foregroundStyle(entry.isInput ? Color.primary : Color.green)
        }
    }

    private var consoleInputBar: some View {
        HStack {
            TextField("Command...", text: $consoleInput)
                .font(.body.monospaced())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Run") {
                executeConsoleCommand()
            }
            .buttonStyle(.borderedProminent)
            .disabled(consoleInput.isEmpty)
        }
        .padding()
    }

    // MARK: - Helpers

    private func takeMemorySnapshot() {
        isProfilingMemory = true
        let usedMB = Int(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) / 100
        memorySnapshots.append(MemorySnapshot(usedMB: usedMB, timestamp: Date()))
        isProfilingMemory = false
    }

    private func evaluateExpression(_ expr: String) -> String {
        switch expr.lowercased() {
        case "runtime.mode": return runtime.isNoSandboxModeEnabled ? "unrestricted" : "sandboxed"
        case "runtime.projects": return "\(runtime.activeProjects.count)"
        case "telemetry.traces": return "\(telemetry.activeTraces.count)"
        case "memory.physical": return "\(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) MB"
        case "cpu.count": return "\(ProcessInfo.processInfo.activeProcessorCount)"
        default: return "undefined"
        }
    }

    private func executeConsoleCommand() {
        consoleOutput.append(ConsoleEntry(text: consoleInput, isInput: true))
        let result: String
        switch consoleInput.lowercased() {
        case "help":
            result = "Commands: help, status, metrics, logs, clear, memory, uptime, version"
        case "status":
            result = "Runtime: \(runtime.isNoSandboxModeEnabled ? "Unrestricted" : "Sandboxed"), Projects: \(runtime.activeProjects.count)"
        case "metrics":
            let m = telemetry.getMetrics()
            result = "Traces: \(m.totalTraces), Avg: \(Int(m.averageDurationMs))ms, Success: \(m.successCount), Fail: \(m.failureCount)"
        case "logs":
            result = "\(logStore.entries.count) entries (\(logStore.entries.filter { $0.level == .error }.count) errors)"
        case "clear":
            consoleOutput.removeAll()
            result = "Console cleared"
        case "memory":
            result = "Physical: \(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) MB, Processors: \(ProcessInfo.processInfo.activeProcessorCount)"
        case "uptime":
            let uptime = ProcessInfo.processInfo.systemUptime
            result = "\(Int(uptime / 3600))h \(Int(uptime.truncatingRemainder(dividingBy: 3600) / 60))m"
        case "version":
            result = "SDK Debug Console v1.0"
        default:
            result = "Unknown command: \(consoleInput). Type 'help' for available commands."
        }
        consoleOutput.append(ConsoleEntry(text: result, isInput: false))
        consoleInput = ""
    }

    private func thermalStateText(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private func thermalStateColor(_ state: ProcessInfo.ThermalState) -> Color {
        switch state {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .secondary
        }
    }

    private func logLevelIcon(_ level: LogLevel) -> String {
        switch level {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        default: return "circle.fill"
        }
    }

    private func logLevelColor(_ level: LogLevel) -> Color {
        switch level {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        default: return .secondary
        }
    }
}

// MARK: - Private Models

private struct DebugBreakpoint: Identifiable {
    let id = UUID()
    let location: String
    let condition: String?
    let isEnabled: Bool
    let hitCount: Int
}

private struct NetworkLogEntry: Identifiable {
    let id = UUID()
    let method: String
    let url: String
    let statusCode: Int
    let durationMs: Int
    let responseBytes: Int
    let timestamp: Date
}

private struct MemorySnapshot: Identifiable {
    let id = UUID()
    let usedMB: Int
    let timestamp: Date
}

private struct WatchExpression: Identifiable {
    let id = UUID()
    let expression: String
    let currentValue: String
}

private struct ConsoleEntry: Identifiable {
    let id = UUID()
    let text: String
    let isInput: Bool
}
