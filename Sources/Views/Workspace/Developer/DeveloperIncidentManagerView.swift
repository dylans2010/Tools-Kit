import SwiftUI

struct DeveloperIncidentManagerView: View {
    @ObservedObject var incidentService = IncidentService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingReportIncident = false
    @State private var newIncidentTitle = ""
    @State private var newIncidentDescription = ""
    @State private var selectedSeverity: IncidentSeverity = .medium

    var filteredIncidents: [Incident] {
        incidentService.incidents.filter { selectedAppID == nil || $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section("Status Context") {
                Picker("App Filter", selection: $selectedAppID) {
                    Text("All Platform Assets").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Active Incidents") {
                if filteredIncidents.isEmpty {
                    EmptyStateView(icon: "shield.checkmark", title: "Systems Operational", message: "All monitored applications and infrastructure nodes are reporting normal status.")
                        .padding(.vertical, 40)
                } else {
                    ForEach(filteredIncidents) { incident in
                        incidentRow(incident)
                    }
                }
            }

            Section {
                Button { showingReportIncident = true } label: {
                    Label("Report New Incident", systemImage: "exclamationmark.triangle.fill").font(.subheadline.bold())
                }
            }
        }
        .navigationTitle("Incidents")
        .sheet(isPresented: $showingReportIncident) { reportIncidentSheet }
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private func incidentRow(_ incident: Incident) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(incident.title).font(.subheadline.bold())
                Spacer()
                severityBadge(incident.severity)
            }

            HStack(spacing: 8) {
                Text(incident.status.rawValue.uppercased()).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                Circle().fill(.secondary).frame(width: 2, height: 2)
                Text(incident.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
            }

            if !incident.description.isEmpty {
                Text(incident.description).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func severityBadge(_ severity: IncidentSeverity) -> some View {
        Text(severity.rawValue.uppercased())
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(severityColor(severity).opacity(0.1))
            .foregroundStyle(severityColor(severity))
            .clipShape(Capsule())
    }

    private func severityColor(_ severity: IncidentSeverity) -> Color {
        switch severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }

    private var reportIncidentSheet: some View {
        NavigationStack {
            Form {
                Section("Target Asset") {
                    Picker("App", selection: $selectedAppID) {
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                }

                Section("Incident Details") {
                    TextField("Summary (e.g. API Latency Spike)", text: $newIncidentTitle)
                    Picker("Severity", selection: $selectedSeverity) {
                        ForEach(IncidentSeverity.allCases, id: \.self) { sev in
                            Text(sev.rawValue).tag(sev)
                        }
                    }
                    TextEditor(text: $newIncidentDescription)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Report Incident")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingReportIncident = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Report") {
                        submitIncident()
                    }
                    .disabled(newIncidentTitle.isEmpty || selectedAppID == nil)
                }
            }
        }
    }

    private func submitIncident() {
        guard let appID = selectedAppID else { return }
        let incident = Incident(appID: appID, title: newIncidentTitle, description: newIncidentDescription, severity: selectedSeverity)
        Task {
            try? await incidentService.reportIncident(incident)
            await MainActor.run {
                showingReportIncident = false
                newIncidentTitle = ""
                newIncidentDescription = ""
            }
        }
    }
}
